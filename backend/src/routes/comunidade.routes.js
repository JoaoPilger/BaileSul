const router = require('express').Router();
const { listar, buscarPorId, listarMeusEventos, atualizarPerfil, atualizarFotoPerfil, adicionarMidia, removerMidia } = require('../controllers/comunidade.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');
const { uploadMidiaPerfil, uploadErrorHandler } = require('../middlewares/upload');

// RF12, RF20 – Rotas autenticadas da comunidade (DEVEM vir antes de /:id)
router.get('/me/eventos', autenticar, autorizar('comunidade'), listarMeusEventos);
router.put('/me/perfil', autenticar, autorizar('comunidade'), atualizarPerfil);

// Foto de perfil (avatar) da comunidade
router.post('/me/foto-perfil', autenticar, autorizar('comunidade'), uploadMidiaPerfil, atualizarFotoPerfil, uploadErrorHandler);

// Mídias da galeria da comunidade
router.post('/me/midias', autenticar, autorizar('comunidade'), uploadMidiaPerfil, adicionarMidia, uploadErrorHandler);
router.delete('/me/midias/:midia_id', autenticar, autorizar('comunidade'), removerMidia);

// RF15 – Listagem e perfil público
router.get('/', listar);
router.get('/:id', buscarPorId);

module.exports = router;