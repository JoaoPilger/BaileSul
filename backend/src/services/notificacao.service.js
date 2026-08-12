const pool = require('../config/database');

/**
 * Cria uma notificação para um usuário. Nunca lança: falhas são apenas
 * logadas para não quebrar o fluxo principal (venda, contrato, etc.)
 * que disparou a notificação.
 *
 * @param {{ usuario_id: number, tipo: string, titulo: string, mensagem?: string, payload?: object }} dados
 */
const criarNotificacao = async ({ usuario_id, tipo, titulo, mensagem, payload }) => {
  try {
    await pool.query(
      `INSERT INTO notificacoes (usuario_id, tipo, titulo, mensagem, payload)
       VALUES ($1, $2, $3, $4, $5)`,
      [usuario_id, tipo, titulo, mensagem || null, payload ? JSON.stringify(payload) : null]
    );
  } catch (err) {
    console.error(`[Notificacao] Erro ao criar notificação (tipo=${tipo}):`, err.message);
  }
};

module.exports = { criarNotificacao };
