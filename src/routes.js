const express = require('express');

const planRoutes = require('./modules/plan/plan.routes');
const subscriptionRoutes = require('./modules/subscription/subscription.routes');
const publicationRoutes = require('./modules/publication/publication.routes');

const router = express.Router();

// ─── Montage des routes par module ───
router.use('/plans', planRoutes);
router.use('/subscriptions', subscriptionRoutes);
router.use('/publications', publicationRoutes);

module.exports = router;
