/**
 * Runner de migrações SQL.
 *
 * Aplica um ou mais arquivos .sql (na ordem informada), cada um dentro de uma
 * transação. As migrações do projeto são idempotentes (IF NOT EXISTS / DO $$),
 * então podem ser reaplicadas sem efeito colateral.
 *
 * Uso:
 *   node scripts/migrate.js <arquivo.sql> [outro.sql ...]
 *   npm run migrate -- src/models/migration_v10_seguidores_avaliacoes.sql
 *
 * Sem argumentos, lista os arquivos de migração disponíveis.
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const pool = require('../src/config/database');

const MODELS_DIR = path.join(__dirname, '..', 'src', 'models');

function listarMigracoesDisponiveis() {
  const arquivos = [];
  const varrer = (dir) => {
    if (!fs.existsSync(dir)) return;
    for (const nome of fs.readdirSync(dir)) {
      const abs = path.join(dir, nome);
      if (fs.statSync(abs).isDirectory()) varrer(abs);
      else if (nome.endsWith('.sql') && nome !== 'schema.sql') arquivos.push(abs);
    }
  };
  varrer(MODELS_DIR);
  varrer(__dirname);
  return arquivos.sort();
}

async function aplicar(arquivo) {
  const abs = path.resolve(process.cwd(), arquivo);
  if (!fs.existsSync(abs)) {
    throw new Error(`Arquivo não encontrado: ${abs}`);
  }
  const sql = fs.readFileSync(abs, 'utf8');
  console.log(`\n▶  Aplicando: ${path.relative(process.cwd(), abs)}`);
  try {
    await pool.query('BEGIN');
    await pool.query(sql);
    await pool.query('COMMIT');
    console.log('   ✅ OK');
  } catch (err) {
    await pool.query('ROLLBACK');
    throw new Error(`Falha em ${path.basename(abs)}: ${err.message}`);
  }
}

async function main() {
  const arquivos = process.argv.slice(2);

  if (arquivos.length === 0) {
    console.log('Uso: node scripts/migrate.js <arquivo.sql> [outro.sql ...]\n');
    console.log('Migrações disponíveis:');
    for (const m of listarMigracoesDisponiveis()) {
      console.log('  - ' + path.relative(path.join(__dirname, '..'), m));
    }
    process.exit(1);
  }

  let falhou = false;
  try {
    for (const arquivo of arquivos) {
      await aplicar(arquivo);
    }
    console.log('\n🎉 Todas as migrações foram aplicadas.');
  } catch (err) {
    console.error('\n❌ ' + err.message);
    falhou = true;
  }

  await pool.end();
  process.exit(falhou ? 1 : 0);
}

main();
