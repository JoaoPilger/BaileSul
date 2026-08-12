const router = require('express').Router();
const { listar, contagem, marcarTodasLidas, marcarUmaLida } = require('../controllers/notificacao.controller');
const { autenticar } = require('../middlewares/auth.middleware');

router.get('/', autenticar, listar);
router.get('/contagem', autenticar, contagem);
router.patch('/lidas', autenticar, marcarTodasLidas);
router.patch('/:id/lida', autenticar, marcarUmaLida);

module.exports = router;
