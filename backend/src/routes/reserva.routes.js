const router = require('express').Router();
const { minhasReservas } = require('../controllers/reserva.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');

// RF11 – Minhas reservas (somente pessoal)
router.get('/minhas', autenticar, autorizar('pessoal'), minhasReservas);

module.exports = router;