const express = require('express');

const planRoutes = require('./modules/plan/plan.routes');
const subscriptionRoutes = require('./modules/subscription/subscription.routes');
const publicationRoutes = require('./modules/publication/publication.routes');
const adminRoutes = require('./modules/admin/admin.routes');
const escortRoutes = require('./modules/escort/escort.routes');
const avisRoutes = require('./modules/avis/avis.routes');
const signalisationRoutes = require('./modules/signalisation/signalisation.routes');
const notificationRoutes = require('./modules/notification/notification.routes');
const configRoutes = require('./modules/config/config.routes');
const transactionRoutes = require('./modules/transaction/transaction.routes');
const authRoutes = require('./modules/auth/auth.routes');

const router = express.Router();

// --- Montage des routes par module ---
router.use('/auth', authRoutes);
router.use('/plans', planRoutes);
router.use('/subscriptions', subscriptionRoutes);
router.use('/publications', publicationRoutes);
router.use('/admins', adminRoutes);
router.use('/escorts', escortRoutes);
router.use('/avis', avisRoutes);
router.use('/signalisation', signalisationRoutes);
router.use('/notifications', notificationRoutes);
router.use('/config', configRoutes);
router.use('/transactions', transactionRoutes);

module.exports = router;
