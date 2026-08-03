const { Pool } = require('pg');

const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     parseInt(process.env.DB_PORT || '5432', 10),
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  // SSL habilitado em produção; desativado em desenvolvimento local
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: true }
    : false,
  // Configurações de pool
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

// Evento de erro no pool (evita crash por conexão ociosa perdida)
pool.on('error', (err) => {
  console.error('❌ Erro inesperado no pool PostgreSQL:', err.message);
});

// Teste de conectividade e migração automática de colunas de foto de perfil
pool.query('SELECT 1')
  .then(async () => {
    console.log('✅ PostgreSQL conectado');
    try {
      await pool.query(`
        ALTER TABLE perfis_bandas ADD COLUMN IF NOT EXISTS foto_perfil_url VARCHAR(500);
        ALTER TABLE perfis_comunidades ADD COLUMN IF NOT EXISTS foto_perfil_url VARCHAR(500);
      `);
    } catch (migErr) {
      console.error('⚠️  Erro ao atualizar schema foto_perfil_url:', migErr.message);
    }
  })
  .catch((err) => console.error('❌ Erro ao conectar ao PostgreSQL:', err.message));

module.exports = pool;