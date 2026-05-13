const pool = require('../config/database');

/**
 * GET /api/eventos
 * Público - lista eventos com filtros opcionais: ?data=&banda=&estilo=&cidade=
 */
const listar = async (req, res) => {
  // TODO: SELECT em eventos com JOINs em perfis_comunidades e evento_bandas
  // Suportar filtros via query params
  res.status(501).json({ message: 'Não implementado ainda' });
};

/**
 * GET /api/eventos/:id
 * Público - detalhes de um evento
 */
const buscarPorId = async (req, res) => {
  // TODO: SELECT evento + comunidade + bandas + vendedores ativos
  res.status(501).json({ message: 'Não implementado ainda' });
};

/**
 * POST /api/eventos
 * Restrito: comunidade
 */
const criar = async (req, res) => {
  // TODO:
  // 1. Verificar conflito de datas com OVERLAPS no calendário compartilhado
  // 2. INSERT em eventos (comunidade_id vem de req.usuario.id)
  // 3. Se bandas informadas, INSERT em evento_bandas e contratos
  res.status(501).json({ message: 'Não implementado ainda' });
};

/**
 * PUT /api/eventos/:id
 * Restrito: comunidade dona do evento
 */
const atualizar = async (req, res) => {
  // TODO: verificar se req.usuario.id === evento.comunidade_id, depois UPDATE
  res.status(501).json({ message: 'Não implementado ainda' });
};

/**
 * DELETE /api/eventos/:id
 * Restrito: comunidade dona do evento
 */
const remover = async (req, res) => {
  // TODO: verificar propriedade, DELETE ou status = 'cancelado'
  res.status(501).json({ message: 'Não implementado ainda' });
};

/**
 * GET /api/eventos/calendario
 * Restrito: comunidade - calendário compartilhado para gestão de conflitos (RF06)
 */
const calendario = async (req, res) => {
  // TODO: SELECT id, titulo, data_inicio, data_fim, comunidade_id FROM eventos
  //       WHERE status != 'cancelado' ORDER BY data_inicio
  res.status(501).json({ message: 'Não implementado ainda' });
};

module.exports = { listar, buscarPorId, criar, atualizar, remover, calendario };