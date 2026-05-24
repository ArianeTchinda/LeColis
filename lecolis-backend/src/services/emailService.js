// src/services/emailService.js
const nodemailer = require('nodemailer');

// ── Transport ─────────────────────────────────────────────
// En production : remplacer par SMTP réel (SendGrid, Brevo, Gmail, etc.)
// En développement : utiliser Mailtrap (gratuit) ou Ethereal (mails fictifs)
function creerTransport() {
  // Si les variables SMTP sont définies → transport réel
  if (process.env.SMTP_HOST) {
    return nodemailer.createTransport({
      host:   process.env.SMTP_HOST,
      port:   parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  }

  // Sinon → Ethereal (mails fictifs, visible dans les logs)
  // ⚠️ À remplacer en production
  return nodemailer.createTransport({
    host: 'smtp.ethereal.email',
    port: 587,
    auth: {
      user: process.env.ETHEREAL_USER || 'lecolis.test@ethereal.email',
      pass: process.env.ETHEREAL_PASS || 'lecolis_test_pass',
    },
  });
}

const FROM_NAME  = process.env.EMAIL_FROM_NAME  || 'LeColis';
const FROM_EMAIL = process.env.EMAIL_FROM_EMAIL || 'noreply@lecolis.com';

/**
 * Envoie le code de réinitialisation par email
 * @param {string} email - destinataire
 * @param {string} code  - code à 6 chiffres (non hashé, lisible)
 * @param {string} pseudo - prénom/pseudo de l'escort
 */
async function envoyerCodeReinit(email, code, pseudo) {
  const transport = creerTransport();

  const info = await transport.sendMail({
    from:    `"${FROM_NAME}" <${FROM_EMAIL}>`,
    to:      email,
    subject: `${code} — Votre code de réinitialisation LeColis`,
    html: `
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Réinitialisation de mot de passe</title>
</head>
<body style="margin:0;padding:0;background-color:#0F0F1A;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#0F0F1A;padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0"
               style="max-width:480px;background-color:#1A1A2E;border-radius:20px;
                      border:1px solid rgba(255,93,168,0.2);overflow:hidden;">

          <!-- Header -->
          <tr>
            <td align="center" style="padding:32px 24px 20px;
                background:linear-gradient(135deg,rgba(255,93,168,0.15),rgba(182,141,255,0.15));">
              <div style="font-size:32px;margin-bottom:8px;">🔐</div>
              <h1 style="margin:0;color:#FFFFFF;font-size:22px;font-weight:800;letter-spacing:0.5px;">
                Réinitialisation du mot de passe
              </h1>
              <p style="margin:8px 0 0;color:#8A8A9A;font-size:13px;">LeColis — Espace confidentiel</p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:28px 32px;">
              <p style="color:#C8C8D8;font-size:15px;line-height:1.6;margin:0 0 20px;">
                Bonjour <strong style="color:#FFFFFF;">${pseudo}</strong>,
              </p>
              <p style="color:#C8C8D8;font-size:14px;line-height:1.6;margin:0 0 28px;">
                Vous avez demandé à réinitialiser votre mot de passe. Utilisez le code
                ci-dessous dans l'application. Ce code est valable <strong style="color:#FF5DA8;">15 minutes</strong>.
              </p>

              <!-- Code -->
              <div style="text-align:center;margin:0 0 28px;">
                <div style="display:inline-block;background:rgba(255,93,168,0.08);
                            border:2px solid rgba(255,93,168,0.4);border-radius:16px;
                            padding:20px 40px;">
                  <span style="font-size:40px;font-weight:900;letter-spacing:10px;
                               color:#FF5DA8;font-family:'Courier New',monospace;">
                    ${code}
                  </span>
                </div>
              </div>

              <p style="color:#8A8A9A;font-size:12px;line-height:1.6;margin:0 0 8px;">
                ⚠️ Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.
                Votre mot de passe restera inchangé.
              </p>
              <p style="color:#8A8A9A;font-size:12px;line-height:1.6;margin:0;">
                Ne partagez jamais ce code avec quelqu'un.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:16px 32px 28px;border-top:1px solid rgba(255,255,255,0.06);">
              <p style="margin:0;color:#555566;font-size:11px;text-align:center;">
                © ${new Date().getFullYear()} LeColis — Plateforme adulte expérimentale.<br>
                Cet email a été envoyé automatiquement, ne pas répondre.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
    `,
    text: `
Bonjour ${pseudo},

Votre code de réinitialisation LeColis : ${code}

Ce code expire dans 15 minutes.

Si vous n'avez pas fait cette demande, ignorez cet email.

— L'équipe LeColis
    `.trim(),
  });

  // En développement Ethereal : afficher l'URL de prévisualisation
  if (!process.env.SMTP_HOST) {
    const previewUrl = nodemailer.getTestMessageUrl(info);
    if (previewUrl) {
      console.log(`\n📧 [Dev] Email de réinitialisation prévisualisable ici :`);
      console.log(`   ${previewUrl}\n`);
    }
  }

  return info;
}

module.exports = { envoyerCodeReinit };
