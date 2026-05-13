const router = require('express').Router();
const { listar, buscarPorId, criar, atualizar, remover, calendario } = require('../controllers/evento.controller');
const { criar: criarReserva } = require('../controllers/reserva.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');

// Públicas
router.get('/',    listar);
router.get('/:id', buscarPorId);

// Restrito: comunidade - calendário compartilhado (deve vir antes de /:id)
router.get('/calendario', autenticar, autorizar('comunidade'), calendario);

// Restrito: comunidade
router.post('/',      autenticar, autorizar('comunidade'), criar);
router.put('/:id',    autenticar, autorizar('comunidade'), atualizar);
router.delete('/:id', autenticar, autorizar('comunidade'), remover);

// Restrito: pessoal - reservar ingresso
router.post('/:id/reserva', autenticar, autorizar('pessoal'), criarReserva);

module.exports = router;