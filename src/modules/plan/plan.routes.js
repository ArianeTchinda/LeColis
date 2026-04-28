const express = require('express');
const planController = require('./plan.controller');
const { validatePlan } = require('./plan.validator');

const router = express.Router();

router.get('/', planController.getAll);
router.get('/:id', planController.getOne);
router.post('/', validatePlan, planController.create);
router.put('/:id', validatePlan, planController.update);
router.delete('/:id', planController.remove);

module.exports = router;
