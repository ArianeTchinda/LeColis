const express = require('express');
const publicationController = require('./publication.controller');
const { protect } = require('../../shares/middleware/auth');

const router = express.Router();

router.get('/', publicationController.getAll);
router.get('/escort/:escortId', publicationController.getByEscort);
router.get('/:id', publicationController.getOne);

// Routes protegees
router.post('/', protect, publicationController.create);
router.delete('/:id', protect, publicationController.remove);

module.exports = router;
