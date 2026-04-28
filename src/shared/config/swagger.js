const swaggerJsdoc = require('swagger-jsdoc');

// ═══════════════════════════════════════════════
// SWAGGER CONFIGURATION
// ═══════════════════════════════════════════════

const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'LeColis API — DEV 1 (Core Business)',
      version: '1.0.0',
      description: `
## API Backend — Module Core Business

### Modules :
- **Plans** : Configuration des abonnements (CRUD admin)
- **Souscriptions** : Gestion des abonnements escorts (paiement → activation)
- **Publications** : Annonces des escorts (vérification abonnement + quota)

### Règles métier critiques :
- ❌ Publier sans abonnement actif = INTERDIT
- ❌ Dépasser le quota du plan = INTERDIT
- ❌ Créer une souscription sans paiement = INTERDIT
- ✅ Vérification automatique à chaque publication

### Flow complet :
1. Admin crée des plans
2. Escort choisit un plan → paiement
3. Paiement réussi → souscription activée
4. Escort crée des publications (dans la limite du quota)
5. Job CRON expire automatiquement les souscriptions
      `,
      contact: {
        name: 'DEV 1 — Core Business',
      },
    },
    servers: [
      {
        url: 'http://localhost:5000',
        description: 'Serveur de développement',
      },
    ],
    tags: [
      { name: 'Health', description: 'Vérification de l\'état du serveur' },
      { name: 'Plans', description: 'Gestion des plans d\'abonnement (admin)' },
      { name: 'Souscriptions', description: 'Gestion des abonnements escorts' },
      { name: 'Publications', description: 'Gestion des annonces' },
    ],
    components: {
      schemas: {
        // ─── PLAN ───
        PlanInput: {
          type: 'object',
          required: ['nom', 'duree', 'nb_publication'],
          properties: {
            nom: {
              type: 'string',
              example: 'Premium',
              description: 'Nom du plan',
            },
            duree: {
              type: 'integer',
              example: 30,
              description: 'Durée de validité en jours',
            },
            nb_publication: {
              type: 'integer',
              example: 10,
              description: 'Nombre maximum de publications autorisées',
            },
          },
        },
        Plan: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            nom: { type: 'string', example: 'Premium' },
            duree: { type: 'integer', example: 30 },
            nb_publication: { type: 'integer', example: 10 },
          },
        },
        // ─── SUBSCRIPTION ───
        SubscriptionInput: {
          type: 'object',
          required: ['escortId', 'planId', 'montant', 'moyen_payement'],
          properties: {
            escortId: {
              type: 'integer',
              example: 1,
              description: 'ID de l\'escort',
            },
            planId: {
              type: 'integer',
              example: 1,
              description: 'ID du plan choisi',
            },
            montant: {
              type: 'number',
              example: 5000,
              description: 'Montant en XAF',
            },
            moyen_payement: {
              type: 'string',
              enum: ['mobile_money', 'orange_money', 'mtn_momo', 'card'],
              example: 'orange_money',
              description: 'Moyen de paiement',
            },
          },
        },
        Subscription: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            date_debut: { type: 'string', format: 'date', example: '2026-04-28' },
            date_fin: { type: 'string', format: 'date', example: '2026-05-28' },
            montant: { type: 'number', example: 5000 },
            status: { type: 'string', example: 'active' },
            moyen_payement: { type: 'string', example: 'orange_money' },
            id_escort: { type: 'integer', example: 1 },
            id_plan: { type: 'integer', example: 1 },
            plan_nom: { type: 'string', example: 'Premium' },
            plan_duree: { type: 'integer', example: 30 },
            plan_nb_publication: { type: 'integer', example: 10 },
          },
        },
        // ─── PUBLICATION ───
        PublicationInput: {
          type: 'object',
          required: ['titre', 'description', 'id_escort'],
          properties: {
            titre: {
              type: 'string',
              example: 'Disponible ce soir à Douala',
              description: 'Titre de la publication (max 255 caractères)',
            },
            description: {
              type: 'string',
              example: 'Je suis disponible ce soir pour des rencontres...',
              description: 'Description détaillée',
            },
            id_categorie: {
              type: 'integer',
              example: 1,
              description: 'ID de la catégorie (optionnel)',
              nullable: true,
            },
            id_escort: {
              type: 'integer',
              example: 1,
              description: 'ID de l\'escort',
            },
          },
        },
        Publication: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            titre: { type: 'string', example: 'Disponible ce soir à Douala' },
            description: { type: 'string' },
            status: { type: 'string', example: 'active' },
            id_categorie: { type: 'integer', nullable: true },
            id_escort: { type: 'integer', example: 1 },
            categorie_nom: { type: 'string', nullable: true },
            escort_pseudo: { type: 'string', example: 'Bella237' },
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
  apis: ['./src/modules/**/*.controller.js'],
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

module.exports = swaggerSpec;