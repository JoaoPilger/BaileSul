require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

// ── Validação de variáveis de ambiente obrigatórias ─────────────────────────
const ENV_OBRIGATORIAS = [
  'JWT_SECRET', 'DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD',
  'SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY',
];
const envFaltando = ENV_OBRIGATORIAS.filter((k) => !process.env[k]);
if (envFaltando.length > 0) {
  console.error(`Variáveis de ambiente obrigatórias ausentes: ${envFaltando.join(', ')}`);
  process.exit(1);
}

if (!process.env.CLIENT_URL) {
  console.warn('⚠️  CLIENT_URL não definido; CORS bloqueará requisições de browsers em produção.');
}

const app = express();

// ── Segurança: headers HTTP ──────────────────────────────────────────────────
app.use(helmet());

// ── CORS ──────────────────────────────────────────────────────────────────────
const origens = process.env.CLIENT_URL
  ? process.env.CLIENT_URL.split(',').map((o) => o.trim())
  : [];

app.use(
  cors({
    origin(origin, callback) {
      // Apps mobile nativos não enviam Origin.
      if (!origin) return callback(null, true);
      if (origens.includes(origin)) return callback(null, true);
      // Flutter web / dev local em portas variadas.
      if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Not allowed by CORS'));
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// ── Body parser com limite explícito ─────────────────────────────────────────
app.use(express.json({ limit: '1mb' }));

// ── Rate limiting ─────────────────────────────────────────────────────────────

// Autenticação: proteção contra brute-force
const limiterAuth = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Muitas tentativas. Tente novamente em alguns minutos.' },
});

// Reservas: proteção contra spam
const limiterReservas = rateLimit({
  windowMs: 60 * 1000, // 1 minuto
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Muitas requisições. Aguarde um momento.' },
});

// Geral: proteção global
const limiterGeral = rateLimit({
  windowMs: 60 * 1000,
  max: 120,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Muitas requisições. Aguarde um momento.' },
});

// ── Rotas ────────────────────────────────────────────────────────────────────
const authRoutes       = require('./routes/auth.routes');
const eventoRoutes     = require('./routes/evento.routes');
const bandaRoutes      = require('./routes/banda.routes');
const comunidadeRoutes = require('./routes/comunidade.routes');
const vendedorRoutes   = require('./routes/vendedor.routes');
const reservaRoutes    = require('./routes/reserva.routes');
const cnpjRoutes       = require('./routes/cnpj.routes');
const notificacaoRoutes = require('./routes/notificacao.routes');

app.use(limiterGeral);
app.use('/api/auth', limiterAuth);
app.use('/api/reservas/eventos/:evento_id', limiterReservas);

// ── Rotas da API ──────────────────────────────────────────────────────────────
app.use('/api/auth',        authRoutes);
app.use('/api/eventos',     eventoRoutes);
app.use('/api/bandas',      bandaRoutes);
app.use('/api/comunidades', comunidadeRoutes);
app.use('/api/vendedores',  vendedorRoutes);
app.use('/api/reservas',    reservaRoutes);
app.use('/api/cnpj',        cnpjRoutes);
app.use('/api/notificacoes', notificacaoRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', projeto: 'BaileSul' });
});

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' });
});

// ── Handler global de erros ───────────────────────────────────────────────────
// Não expõe err.message ao cliente para evitar vazamento de detalhes internos
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Erro interno do servidor' });
});

module.exports = app;