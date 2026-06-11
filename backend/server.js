require('dotenv').config();
const app = require('./src/app');
const pool = require('./src/config/database');
const { iniciarLimpezaPeriodica } = require('./src/services/token.service');

const PORT = process.env.PORT || 3000;

const tokenCleanupInterval = iniciarLimpezaPeriodica();

const server = app.listen(PORT, () => {
  console.log(`🚀 BaileSul API rodando na porta ${PORT}`);
});

// ── Graceful shutdown ─────────────────────────────────────────────────────────
const shutdown = async (signal) => {
  console.log(`\n${signal} recebido. Encerrando servidor...`);
  clearInterval(tokenCleanupInterval);
  server.close(async () => {
    await pool.end();
    console.log('✅ Pool de banco encerrado. Até logo!');
    process.exit(0);
  });

  // Força encerramento após 10s se conexões não fecharem
  setTimeout(() => {
    console.error('❌ Timeout no shutdown. Forçando encerramento.');
    process.exit(1);
  }, 10_000);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));