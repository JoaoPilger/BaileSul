const pool = require('../config/database');

/**
 * GET /api/notificacoes
 * Lista as notificações do usuário autenticado (mais recentes primeiro).
 */
const listar = async (req, res) => {
  const usuario_id = req.usuario.id;

  try {
    const { rows } = await pool.query(
      `SELECT id, tipo, titulo, mensagem, lida, payload, criado_em
       FROM notificacoes
       WHERE usuario_id = $1
       ORDER BY criado_em DESC
       LIMIT 50`,
      [usuario_id]
    );
    return res.json(rows);
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
