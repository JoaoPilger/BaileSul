const pool = require('../config/database');

/**
 * Remove tokens expirados e revogados antigos da tabela auth_tokens.
 * @returns {Promise<number>} quantidade de registros removidos
 */
const limparTokensExpirados = async () => {
  const { rowCount } = await pool.query(
    `DELETE FROM auth_tokens
     WHERE expires_at < NOW()
        OR (deleted_at IS NOT NULL AND deleted_at < NOW() - INTERVAL '30 days')`
  );
  return rowCount;
};

/** Intervalo padrão: 6 horas */
const INTERVALO_LIMPEZA_MS = 6 * 60 * 60 * 1000;

/**
 * Executa limpeza na inicialização e agenda execuções periódicas.
 * @returns {NodeJS.Timeout} handle do intervalo (para clearInterval no shutdown)
 */
const iniciarLimpezaPeriodica = () => {
  limparTokensExpirados()
    .then((n) => {
      if (n > 0) console.log(`🧹 ${n} token(s) expirado(s)/revogado(s) removido(s)`);
    })
    .catch((err) => console.error('Erro na limpeza inicial de tokens:', err.message));

  return setInterval(() => {
    limparTokensExpirados().catch((err) =>
      console.error('Erro na limpeza periódica de tokens:', err.message)
    );
  }, INTERVALO_LIMPEZA_MS);
};

module.exports = { limparTokensExpirados, iniciarLimpezaPeriodica };
