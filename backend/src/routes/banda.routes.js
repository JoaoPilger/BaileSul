const router = require('express').Router();
const { listar, buscarPorId, agenda, atualizarPerfil } = require('../controllers/banda.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');

// RF18 – Agenda da banda (DEVE vir antes de /:id)
router.get('/me/agenda', autenticar, autorizar('banda'), agenda);

// RF12, RF20 – Editar vitrine da banda
router.put('/me/perfil', autenticar, autorizar('banda'), atualizarPerfil);

// RF10, RF15 – Listagem e perfil público
router.get('/', listar);
router.get('/:id', buscarPorId);

module.exports = router;