const router = require('express').Router();
const { criar, minhasReservas } = require('../controllers/reserva.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');

// RF11 – Reservar ingresso (somente pessoal)
// Montada em /api/reservas → POST /api/reservas/eventos/:evento_id
router.post('/eventos/:evento_id', autenticar, autorizar('pessoal'), criar);

// RF11 – Minhas reservas (somente pessoal)
router.get('/minhas', autenticar, autorizar('pessoal'), minhasReservas);

module.exports = router;