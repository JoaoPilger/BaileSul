const router = require('express').Router();
const {
  listar, buscarPorId, criar, atualizar, cancelar, calendario, responderContrato, convidarBanda,
  dashboardEvento,
} = require('../controllers/evento.controller');
const { autenticar, autorizar, autenticarOpcional } = require('../middlewares/auth.middleware');
const { uploadCapaEvento, uploadErrorHandler } = require('../middlewares/upload');

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

router.use(uploadErrorHandler);

// Banda responde contrato (aceitar / recusar)
router.patch('/:id/contratos/:contrato_id', autenticar, autorizar('banda'), responderContrato);

// Comunidade convida banda para um evento já criado
router.post('/:id/contratos', autenticar, autorizar('comunidade'), convidarBanda);

module.exports = router;