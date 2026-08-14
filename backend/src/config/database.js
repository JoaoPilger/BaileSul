const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Certificado raiz do Supabase — o pooler (Supavisor) usa uma cadeia de CA
// própria, não reconhecida pela store padrão do Node, então sem isso o
// handshake TLS falha com "self-signed certificate in certificate chain".
// DB_HOST aponta pro Supabase em qualquer ambiente (local ou produção),
// então a verificação de certificado vale sempre, não só em produção.
const supabaseCa = fs
  .readFileSync(path.join(__dirname, 'certs', 'supabase-ca.crt'))
  .toString();

const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     parseInt(process.env.DB_PORT || '5432', 10),
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: true, ca: supabaseCa },
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
        ALTER TABLE perfis_comunidades ADD COLUMN IF NOT EXISTS cep VARCHAR(9);
      `);
    } catch (migErr) {
      console.error('⚠️  Erro ao atualizar schema foto_perfil_url:', migErr.message);
    }
    try {
      // Migration v11: unifica musical_gaucha/musical_bandinha em "musical".
      // A constraint antiga precisa cair ANTES do UPDATE — ela não permite
      // o valor 'musical' sozinho, então rodar o UPDATE antes rejeitaria a
      // própria migração.
      await pool.query(`
        ALTER TABLE eventos DROP CONSTRAINT IF EXISTS chk_eventos_tipo_evento;
        UPDATE eventos SET tipo_evento = 'musical'
        WHERE tipo_evento IN ('musical_gaucha', 'musical_bandinha');
        ALTER TABLE eventos ALTER COLUMN tipo_evento SET DEFAULT 'musical';
        ALTER TABLE eventos ADD CONSTRAINT chk_eventos_tipo_evento CHECK (
          tipo_evento IN ('musical', 'almoco', 'bingo', 'expos', 'futebol')
        );
      `);
    } catch (migErr) {
      console.error('⚠️  Erro ao atualizar schema tipo_evento:', migErr.message);
    }
  })
  .catch((err) => console.error('❌ Erro ao conectar ao PostgreSQL:', err.message));

module.exports = pool;