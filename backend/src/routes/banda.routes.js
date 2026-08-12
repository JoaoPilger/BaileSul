const router = require('express').Router();
const {
  listar, buscarPorId, agenda, atualizarPerfil, atualizarFotoPerfil, buscarSugestoes,
  adicionarMidia, removerMidia, seguir, deixarDeSeguir, avaliar,
} = require('../controllers/banda.controller');
const { autenticar, autorizar, autenticarOpcional } = require('../middlewares/auth.middleware');
const { uploadMidiaPerfil, uploadErrorHandler } = require('../middlewares/upload');

// RF18 – Agenda da banda (DEVE vir antes de /:id)
router.get('/me/agenda', autenticar, autorizar('banda'), agenda);

// PUT vitrine da banda
router.put('/me/perfil', autenticar, autorizar('banda'), atualizarPerfil);

// Foto de perfil (avatar) da banda
router.post('/me/foto-perfil', autenticar, autorizar('banda'), uploadMidiaPerfil, atualizarFotoPerfil, uploadErrorHandler);

// Mídias da galeria da banda
router.post('/me/midias', autenticar, autorizar('banda'), uploadMidiaPerfil, adicionarMidia, uploadErrorHandler);
router.delete('/me/midias/:midia_id', autenticar, autorizar('banda'), removerMidia);

// Autocomplete de bandas para o form de criar evento (DEVE vir antes de /:id)
router.get('/sugestoes', autenticar, autorizar('comunidade'), buscarSugestoes);

// RF10, RF15 – Listagem e perfil público
router.get('/', listar);
router.get('/:id', autenticarOpcional, buscarPorId);

// Seguir / avaliar (qualquer usuário autenticado, exceto a própria banda)
router.post('/:id/seguir', autenticar, seguir);
router.delete('/:id/seguir', autenticar, deixarDeSeguir);
router.put('/:id/avaliar', autenticar, avaliar);

module.exports = router;