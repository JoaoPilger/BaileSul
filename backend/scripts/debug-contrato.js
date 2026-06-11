require('dotenv').config();
const pool = require('../src/config/database');

(async () => {
  try {
    const { rows } = await pool.query(
      `SELECT c.id, c.evento_id, c.banda_id, c.status_aceite
       FROM contratos c ORDER BY c.id DESC LIMIT 3`
    );
    console.log('contratos:', rows);

    // Simular responderContrato
    if (rows[0]) {
      const { id: contrato_id, evento_id, banda_id, status_aceite } = rows[0];
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        await client.query(
          `UPDATE contratos SET status_aceite = $1, data_assinatura = CASE WHEN $1 = 'aceito' THEN NOW() ELSE NULL END WHERE id = $2`,
          ['aceito', contrato_id]
        );
        await client.query(
          `INSERT INTO logs_status_contratos (contrato_id, status_anterior, status_novo, usuario_id)
           VALUES ($1, $2, $3, $4)`,
          [contrato_id, status_aceite, 'aceito', banda_id]
        );
        await client.query('ROLLBACK');
        console.log('simulacao OK');
      } catch (e) {
        await client.query('ROLLBACK');
        console.error('simulacao ERRO:', e.message, e.detail);
      } finally {
        client.release();
      }
    }
  } finally {
    await pool.end();
  }
})();
