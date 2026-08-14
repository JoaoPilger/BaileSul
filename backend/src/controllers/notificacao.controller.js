const pool = require('../config/database');
const { parsePaginacao, respostaPaginada } = require('../utils/pagination');

const STATUS_VALIDOS = ['todas', 'lidas', 'nao_lidas'];

/**
 * GET /api/notificacoes?status=todas|lidas|nao_lidas&pagina=&limite=
 * Lista (paginado) o histórico de notificações do usuário autenticado,
 * mais recentes primeiro. `status` filtra por lidas/não lidas; sem o
 * parâmetro, traz todas.
 */
const listar = async (req, res) => {
  const usuario_id = req.usuario.id;
  const { status } = req.query;
  const { pagina, limite, offset } = parsePaginacao(req.query);

  if (status && !STATUS_VALIDOS.includes(status)) {
    return res.status(400).json({ error: `status inválido. Use: ${STATUS_VALIDOS.join(', ')}` });
  }

  let where = 'WHERE usuario_id = $1';
  if (status === 'lidas') where += ' AND lida = TRUE';
  else if (status === 'nao_lidas') where += ' AND lida = FALSE';

  try {
    const countRes = await pool.query(
      `SELECT COUNT(*)::int AS total FROM notificacoes ${where}`,
      [usuario_id]
    );
    const total = countRes.rows[0].total;

    const { rows } = await pool.query(
      `SELECT id, tipo, titulo, mensagem, lida, payload, criado_em
       FROM notificacoes
       ${where}
       ORDER BY criado_em DESC
       LIMIT $2 OFFSET $3`,
      [usuario_id, limite, offset]
    );

    return res.json(respostaPaginada(rows, pagina, limite, total));
  } catch (err) {
    console.error('Erro ao listar notificações:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/notificacoes/contagem
 * Retorna a quantidade de notificações não lidas (para o badge do sino).
 */
const contagem = async (req, res) => {
  const usuario_id = req.usuario.id;

  try {
    const { rows } = await pool.query(
      `SELECT COUNT(*)::int AS nao_lidas FROM notificacoes
       WHERE usuario_id = $1 AND lida = FALSE`,
      [usuario_id]
    );
    return res.json({ nao_lidas: rows[0].nao_lidas });
  } catch (err) {
    console.error('Erro ao contar notificações:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PATCH /api/notificacoes/lidas
 * Marca todas as notificações do usuário autenticado como lidas.
 */
const marcarTodasLidas = async (req, res) => {
  const usuario_id = req.usuario.id;

  try {
    await pool.query(
      `UPDATE notificacoes SET lida = TRUE WHERE usuario_id = $1 AND lida = FALSE`,
      [usuario_id]
    );
    return res.json({ message: 'Notificações marcadas como lidas' });
  } catch (err) {
    console.error('Erro ao marcar notificações como lidas:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PATCH /api/notificacoes/:id/lida
 * Marca uma notificação específica como lida.
 */
const marcarUmaLida = async (req, res) => {
  const usuario_id = req.usuario.id;
  const { id } = req.params;

  try {
    const { rowCount } = await pool.query(
      `UPDATE notificacoes SET lida = TRUE WHERE id = $1 AND usuario_id = $2`,
      [id, usuario_id]
    );
    if (rowCount === 0) {
      return res.status(404).json({ error: 'Notificação não encontrada' });
    }
    return res.json({ message: 'Notificação marcada como lida' });
  } catch (err) {
    console.error('Erro ao marcar notificação como lida:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = { listar, contagem, marcarTodasLidas, marcarUmaLida };
