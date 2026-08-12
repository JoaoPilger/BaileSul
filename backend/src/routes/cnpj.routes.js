const router = require('express').Router();
const { verificar } = require('../controllers/cnpj.controller');

// Consulta pública de status de CNPJ (feedback em tempo real nos formulários)
router.get('/verificar', verificar);

module.exports = router;
