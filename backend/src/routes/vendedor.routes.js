const router = require('express').Router();
const { listar, adicionar, remover, confirmarPagamento } = require('../controllers/vendedor.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');

// RF13 – Confirmar pagamento (DEVE vir antes de /:id)
// Permitido para: comunidade (dona do evento) OU pessoal (vendedor vinculado)
router.patch(
  '/reservas/:reserva_id/confirmar',
  autenticar,
  autorizar('comunidade', 'pessoal'),
  confirmarPagamento
);

// RF08 – Gestão de vendedores (somente comunidade)
router.get('/',       autenticar, autorizar('comunidade'), listar);
router.post('/',      autenticar, autorizar('comunidade'), adicionar);
router.delete('/:id', autenticar, autorizar('comunidade'), remover);

module.exports = router;