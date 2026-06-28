const router = require('express').Router();
const { listar, adicionar, remover, confirmarPagamento, buscarSugestoes } = require('../controllers/vendedor.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');

// RF13 – Confirmar pagamento (DEVE vir antes de /:id)
router.patch(
  '/reservas/:reserva_id/confirmar',
  autenticar,
  autorizar('comunidade', 'pessoal'),
  confirmarPagamento
);

// Autocomplete – busca usuários pessoais por nome ou whatsapp (somente comunidade)
router.get('/sugestoes', autenticar, autorizar('comunidade'), buscarSugestoes);

// RF08 – Gestão de vendedores (somente comunidade)
router.get('/',       autenticar, autorizar('comunidade'), listar);
router.post('/',      autenticar, autorizar('comunidade'), adicionar);
router.delete('/:id', autenticar, autorizar('comunidade'), remover);

module.exports = router;