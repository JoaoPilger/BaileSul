const router = require('express').Router();
const {
  listar, buscarPorId, criar, atualizar, cancelar, calendario, responderContrato
} = require('../controllers/evento.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');
const { uploadCapaEvento, uploadErrorHandler } = require('../middlewares/upload');

// RF06 – Calendário compartilhado (DEVE vir antes de /:id)
router.get('/calendario', autenticar, autorizar('comunidade'), calendario);

// RF14, RF16 – Listagem pública com filtros
router.get('/', listar);

// RF17 – Detalhe público do evento
router.get('/:id', buscarPorId);

// RF07 – CRUD de eventos (somente comunidade)
router.post('/',      autenticar, autorizar('comunidade'), uploadCapaEvento, criar);
router.put('/:id',    autenticar, autorizar('comunidade'), uploadCapaEvento, atualizar);
router.delete('/:id', autenticar, autorizar('comunidade'), cancelar);

router.use(uploadErrorHandler);

// Banda responde contrato (aceitar / recusar)
router.patch('/:id/contratos/:contrato_id', autenticar, autorizar('banda'), responderContrato);

module.exports = router;