const { validarCNPJ } = require('../services/external.service');
const { cnpjFormatoValido } = require('../utils/validators');

/**
 * GET /api/cnpj/verificar?cnpj=00.000.000/0000-00
 * Consulta pública o status do CNPJ na Receita Federal (via OpenCNPJ),
 * usada para dar feedback imediato nos formulários antes do cadastro.
 */
const verificar = async (req, res) => {
  const { cnpj } = req.query;

  if (!cnpj || !cnpjFormatoValido(cnpj)) {
    return res.status(400).json({ error: 'Informe um CNPJ no formato XX.XXX.XXX/XXXX-XX' });
  }

  try {
    const resultado = await validarCNPJ(cnpj);

    return res.json({
      valido: resultado.valido,
      api_disponivel: resultado.apiDisponivel,
      razao_social: resultado.razao_social,
      situacao: resultado.situacao,
    });
  } catch (err) {
    console.error('Erro ao verificar CNPJ:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = { verificar };
