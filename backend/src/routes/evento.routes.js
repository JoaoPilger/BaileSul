const router = require('express').Router();
const {
  listar, buscarPorId, criar, atualizar, cancelar, calendario, responderContrato, convidarBanda,
  removerContrato, dashboardEvento, adicionarDia, removerDia, adicionarMidia, removerMidia,
} = require('../controllers/evento.controller');
const { autenticar, autorizar, autenticarOpcional } = require('../middlewares/auth.middleware');
const { uploadCapaEvento, uploadMidiaEvento, uploadErrorHandler } = require('../middlewares/upload');

// RF06 – Calendário compartilhado (DEVE vir antes de /:id)
router.get('/calendario', autenticar, autorizar('comunidade'), calendario);

// Dashboard exclusivo da comunidade dona (DEVE vir antes de /:id)
router.get('/:id/dashboard', autenticar, autorizar('comunidade'), dashboardEvento);

// RF14, RF16 – Listagem pública com filtros
router.get('/', listar);

// RF17 – Detalhe público do evento (comunidade dona pode pré-visualizar antes da banda confirmar)
router.get('/:id', autenticarOpcional, buscarPorId);

// RF07 – CRUD de eventos (somente comunidade)
router.post('/',      autenticar, autorizar('comunidade'), uploadCapaEvento, criar);
router.put('/:id',    autenticar, autorizar('comunidade'), uploadCapaEvento, atualizar);
router.delete('/:id', autenticar, autorizar('comunidade'), cancelar);

// RF06 – Dias do evento (somente comunidade dona)
router.post('/:id/dias',              autenticar, autorizar('comunidade'), adicionarDia);
router.delete('/:id/dias/:dia_id',    autenticar, autorizar('comunidade'), removerDia);

// RF12 – Mídias do evento (somente comunidade dona)
router.post('/:id/midias',            autenticar, autorizar('comunidade'), uploadMidiaEvento, adicionarMidia);
router.delete('/:id/midias/:midia_id', autenticar, autorizar('comunidade'), removerMidia);

router.use(uploadErrorHandler);

// Banda responde contrato (aceitar / recusar)
router.patch('/:id/contratos/:contrato_id', autenticar, autorizar('banda'), responderContrato);

// Comunidade convida banda para um evento já criado
router.post('/:id/contratos', autenticar, autorizar('comunidade'), convidarBanda);

// Comunidade remove o convite de uma banda (trocar/limpar na edição)
router.delete('/:id/contratos/:contrato_id', autenticar, autorizar('comunidade'), removerContrato);

module.exports = router;