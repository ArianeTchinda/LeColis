const swaggerJsdoc = require('swagger-jsdoc');

// ═══════════════════════════════════════════════
// SWAGGER CONFIGURATION v2.0
// ═══════════════════════════════════════════════

const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'LeColis.com API — v2.0',
      version: '2.0.0',
      description: `
## API Backend — LeColis.com
Documentation technique alignée sur la version 2.0 du projet.

### Modules principaux :
- **Utilisateurs** : Gestion unifiée des comptes (Client, Escort, Admin).
- **Escorts** : Profils étendus, vérification d'identité (CNI), tarifs et disponibilité.
- **Plans & Abonnements** : Gestion des offres et souscriptions conditionnant les publications.
- **Publications** : Annonces avec gestion de médias (Cloud Storage via Minio).
- **Transactions** : Suivi des paiements.
- **Interactions** : Avis, Signalements, Notifications.

### Règles critiques :
- Authentification via JWT avec rôles (\`client\`, \`escort\`, \`admin\`).
- Minio utilisé pour tout le stockage média.
- Validation automatique des quotas de publication selon l'abonnement actif.
      `,
    },
    servers: [
      {
        url: 'http://localhost:5000',
        description: 'Serveur de développement',
      },
    ],
    tags: [
      { name: 'Auth', description: 'Connexion et Inscription' },
      { name: 'Escorts', description: 'Profils et vérification' },
      { name: 'Plans', description: 'Offres d\'abonnement' },
      { name: 'Abonnements', description: 'Souscriptions des escorts' },
      { name: 'Publications', description: 'Annonces et médias' },
      { name: 'Transactions', description: 'Paiements' },
      { name: 'Avis', description: 'Notes et commentaires' },
      { name: 'Signalements', description: 'Modération' },
      { name: 'Notifications', description: 'Alertes utilisateur' },
      { name: 'Config', description: 'Paramètres du site (Logo, etc.)' },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        // ─── UTILISATEUR ───
        Utilisateur: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            nom: { type: 'string' },
            prenom: { type: 'string' },
            pseudonyme: { type: 'string' },
            age: { type: 'integer' },
            mail: { type: 'string' },
            role: { type: 'string', enum: ['client', 'escort', 'admin'] },
            statut: { type: 'string', enum: ['actif', 'suspendu', 'banni'] },
          },
        },
        // ─── ESCORT ───
        Escort: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            utilisateur_id: { type: 'integer' },
            url_image_profil: { type: 'string' },
            localisation_id: { type: 'integer' },
            tarif: { type: 'number' },
            disponible: { type: 'boolean' },
            verified: { type: 'string', enum: ['non_soumis', 'en_attente', 'vérifié', 'rejeté'] },
          },
        },
        // ─── PLAN ───
        Plan: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            nom: { type: 'string' },
            nb_publications: { type: 'integer' },
            duree_jours: { type: 'integer' },
            prix: { type: 'number' },
          },
        },
        // ─── ABONNEMENT ───
        AbonnementPlan: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            escort_id: { type: 'integer' },
            plan_id: { type: 'integer' },
            date_debut: { type: 'string', format: 'date' },
            date_fin: { type: 'string', format: 'date' },
            statut: { type: 'string', enum: ['actif', 'expiré', 'annulé'] },
          },
        },
        // ─── PUBLICATION ───
        Publication: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            titre: { type: 'string' },
            description: { type: 'string' },
            statut: { type: 'string', enum: ['actif', 'inactif'] },
            montant: { type: 'number' },
            vh_publication: { type: 'integer' },
          },
        },
        // ─── MEDIA ───
        PublicationMedia: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            publication_id: { type: 'integer' },
            url: { type: 'string' },
            ordre: { type: 'integer' },
          },
        },
        // ─── TRANSACTION ───
        Transaction: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            escort_id: { type: 'integer' },
            montant: { type: 'number' },
            statut: { type: 'string', enum: ['en_attente', 'validé', 'échoué', 'remboursé'] },
            reference_paiement: { type: 'string' },
          },
        },
        // ─── RÉPONSES STANDARD ───
        SuccessResponse: {
          type: 'object',
          properties: {
            status: { type: 'string', example: 'success' },
            data: { type: 'object' },
          },
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            status: { type: 'string', example: 'fail' },
            message: { type: 'string' },
          },
        },
      },
    },
  },
  apis: ['./src/modules/**/*.controller.js', './src/app.js'],
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

module.exports = swaggerSpec;