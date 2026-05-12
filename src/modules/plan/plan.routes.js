const express = require('express');
const planController = require('./plan.controller');
const { validatePlan } = require('./plan.validator');
const protectAdmin = require('../../shares/middleware/authadmin');

const router = express.Router();

router.get('/', planController.getAll);
router.get('/:id', planController.getOne);
router.post('/', protectAdmin, validatePlan, planController.create);
router.put('/:id', protectAdmin, validatePlan, planController.update);
router.delete('/:id', protectAdmin, planController.remove);

module.exports = router;
