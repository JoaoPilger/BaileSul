const router = require('express').Router();
const { listar, buscarPorId, listarMeusEventos, atualizarPerfil } = require('../controllers/comunidade.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');

// RF12, RF20 – Rotas autenticadas da comunidade (DEVEM vir antes de /:id)
router.get('/me/eventos', autenticar, autorizar('comunidade'), listarMeusEventos);
router.put('/me/perfil', autenticar, autorizar('comunidade'), atualizarPerfil);

// RF15 – Listagem e perfil público
router.get('/', listar);
router.get('/:id', buscarPorId);

module.exports = router;