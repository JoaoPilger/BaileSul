const router = require('express').Router();
const { listar, buscarPorId, atualizarPerfil } = require('../controllers/comunidade.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');

// RF12, RF20 – Editar vitrine da comunidade (DEVE vir antes de /:id)
router.put('/me/perfil', autenticar, autorizar('comunidade'), atualizarPerfil);

// RF15 – Listagem e perfil público
router.get('/', listar);
router.get('/:id', buscarPorId);

module.exports = router;