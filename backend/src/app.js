require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes       = require('./routes/auth.routes');
const eventoRoutes     = require('./routes/evento.routes');
const bandaRoutes      = require('./routes/banda.routes');
const comunidadeRoutes = require('./routes/comunidade.routes');
const vendedorRoutes   = require('./routes/vendedor.routes');
const reservaRoutes    = require('./routes/reserva.routes');

const app = express();

// Middlewares globais
app.use(cors({ origin: process.env.CLIENT_URL }));
app.use(express.json());

// Rotas
app.use('/api/auth',        authRoutes);
app.use('/api/eventos',     eventoRoutes);
app.use('/api/bandas',      bandaRoutes);
app.use('/api/comunidades', comunidadeRoutes);
app.use('/api/vendedores',  vendedorRoutes);
app.use('/api/reservas',    reservaRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', projeto: 'BaileSul' });
});

// Handler de rotas não encontradas
app.use((req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' });
});

// Handler global de erros
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Erro interno do servidor' });
});

module.exports = app;