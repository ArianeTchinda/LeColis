// src/controllers/resetMdpController.js
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const prisma  = require('../config/prisma');
const { envoyerCodeReinit } = require('../services/emailService');

// ── Utilitaires ────────────────────────────────────────────

/** Génère un code à 6 chiffres lisible */
function genererCode() {
  // crypto.randomInt est cryptographiquement sûr
  return String(crypto.randomInt(100000, 999999));
}

/** Hache le code pour stockage en BD (on ne stocke jamais en clair) */
function hacherCode(code) {
  return crypto.createHash('sha256').update(code).digest('hex');
}

// ── POST /auth/mot-de-passe-oublie ────────────────────────
// Étape 1 : l'utilisateur fournit son email
async function demanderReinit(req, res, next) {
  try {
    const { email } = req.body;

    if (!email || !email.includes('@')) {
      return res.status(400).json({ message: 'Email invalide.' });
    }

    const emailNormalise = email.trim().toLowerCase();

    // Chercher l'escort — réponse identique qu'elle existe ou non
    // (évite l'énumération d'emails valides)
    const escort = await prisma.escort.findUnique({
      where:  { email: emailNormalise },
      select: { id: true, pseudo: true, email: true, estBanni: true },
    });

    // Toujours répondre la même chose (sécurité anti-énumération)
    const reponseGenerique = {
      message: 'Si cet email est associé à un compte, un code vous a été envoyé.',
    };

    if (!escort || escort.estBanni) {
      return res.json(reponseGenerique);
    }

    // Invalider les anciens codes non utilisés pour cet email
    await prisma.codeReinit.updateMany({
      where:  { email: emailNormalise, utilise: false },
      data:   { utilise: true },
    });

    // Générer et stocker le nouveau code
    const code    = genererCode();
    const codeHash = hacherCode(code);

    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // +15 min

    await prisma.codeReinit.create({
      data: { email: emailNormalise, code: codeHash, expiresAt },
    });

    // Envoyer l'email (non bloquant sur les erreurs SMTP)
    try {
      await envoyerCodeReinit(emailNormalise, code, escort.pseudo);
    } catch (errEmail) {
      console.error('[Email] Erreur envoi code reinit:', errEmail.message);
      // On ne remonte pas l'erreur SMTP au client
    }

    return res.json(reponseGenerique);
  } catch (err) {
    next(err);
  }
}

// ── POST /auth/verifier-code ───────────────────────────────
// Étape 2 : vérifier le code sans encore changer le mdp
// (permet d'afficher le formulaire nouveau mdp côté frontend)
async function verifierCode(req, res, next) {
  try {
    const { email, code } = req.body;

    if (!email || !code) {
      return res.status(400).json({ message: 'Email et code requis.' });
    }

    const emailNormalise = email.trim().toLowerCase();
    const codeHash       = hacherCode(code.trim());

    const entree = await prisma.codeReinit.findFirst({
      where: {
        email:    emailNormalise,
        code:     codeHash,
        utilise:  false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!entree) {
      return res.status(400).json({
        message: 'Code invalide ou expiré. Faites une nouvelle demande.',
      });
    }

    // Code valide → renvoyer un token temporaire signé pour l'étape 3
    // (évite de retransmettre le code en clair dans l'étape suivante)
    // Simple : on renvoie l'ID de l'entrée CodeReinit (opaque côté client)
    return res.json({
      valide:     true,
      reinitId:   entree.id,
      message:    'Code valide. Vous pouvez définir un nouveau mot de passe.',
    });
  } catch (err) {
    next(err);
  }
}

// ── POST /auth/reinitialiser-mdp ──────────────────────────
// Étape 3 : changer le mot de passe avec le reinitId obtenu à l'étape 2
async function reinitialiserMdp(req, res, next) {
  try {
    const { reinitId, nouveauMotDePasse } = req.body;

    if (!reinitId || !nouveauMotDePasse) {
      return res.status(400).json({ message: 'Données manquantes.' });
    }
    if (nouveauMotDePasse.length < 6) {
      return res.status(400).json({ message: 'Mot de passe : 6 caractères minimum.' });
    }

    // Retrouver l'entrée CodeReinit
    const entree = await prisma.codeReinit.findUnique({
      where: { id: reinitId },
    });

    if (!entree || entree.utilise || entree.expiresAt < new Date()) {
      return res.status(400).json({
        message: 'Session expirée. Refaites une demande de réinitialisation.',
      });
    }

    // Récupérer l'escort
    const escort = await prisma.escort.findUnique({
      where:  { email: entree.email },
      select: { id: true },
    });

    if (!escort) {
      return res.status(404).json({ message: 'Compte introuvable.' });
    }

    const hash = await bcrypt.hash(nouveauMotDePasse, 12);

    // Mettre à jour le mdp + invalider le code + invalider tous les refresh tokens
    await prisma.$transaction([
      prisma.escort.update({
        where: { id: escort.id },
        data:  { motDePasseHash: hash },
      }),
      prisma.codeReinit.update({
        where: { id: reinitId },
        data:  { utilise: true },
      }),
      prisma.refreshToken.deleteMany({
        where: { escortId: escort.id },
      }),
    ]);

    return res.json({
      message: 'Mot de passe réinitialisé avec succès. Vous pouvez vous connecter.',
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { demanderReinit, verifierCode, reinitialiserMdp };
