const router = require('express').Router();
const { listar, buscarPorId, agenda, atualizarPerfil, buscarSugestoes } = require('../controllers/banda.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');

// RF18 – Agenda da banda (DEVE vir antes de /:id)
router.get('/me/agenda', autenticar, autorizar('banda'), agenda);

// PUT vitrine da banda
router.put('/me/perfil', autenticar, autorizar('banda'), atualizarPerfil);

// Autocomplete de bandas para o form de criar evento (DEVE vir antes de /:id)
router.get('/sugestoes', autenticar, autorizar('comunidade'), buscarSugestoes);

// RF10, RF15 – Listagem e perfil público
router.get('/', listar);
router.get('/:id', buscarPorId);

module.exports = router;