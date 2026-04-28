const express = require('express');
const publicationController = require('./publication.controller');
const { validatePublication } = require('./publication.validator');

const router = express.Router();

router.get('/', publicationController.getAll);
router.get('/escort/:escortId', publicationController.getByEscort);
router.get('/:id', publicationController.getOne);
router.post('/', validatePublication, publicationController.create);
router.delete('/:id', publicationController.remove);

module.exports = router;
