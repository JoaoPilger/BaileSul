const pool = require('../config/database');
const { parsePaginacao, respostaPaginada } = require('../utils/pagination');
const { caminhoParaUrl } = require('../middlewares/upload');
const { geocodificarEndereco } = require('../services/external.service');
const { criarNotificacao } = require('../services/notificacao.service');

// Tipos de evento aceitos (coluna eventos.tipo_evento)
const TIPOS_EVENTO = ['musical', 'almoco', 'bingo', 'expos', 'futebol'];

// Mínimo de vendedores ativos pra criar evento — com só 1, se ele ficar
// indisponível ninguém mais consegue confirmar pagamento dos compradores.
const VENDEDORES_MINIMO = 2;

// ─────────────────────────────────────────────────────────────
//  Helpers internos
// ─────────────────────────────────────────────────────────────

/** Normaliza um valor DATE vindo do pg (Date object ou string) para "YYYY-MM-DD". */
const toDateStr = (valor) => {
  if (valor instanceof Date) return valor.toISOString().slice(0, 10);
  return String(valor).slice(0, 10);
};

/** Converte "YYYY-MM-DD" para "DD/MM/AAAA", usado só em mensagens de erro. */
const formatDateBR = (dateStr) => {
  const [y, m, d] = dateStr.split('-');
  return `${d}/${m}/${y}`;
};

/**
 * Extrai a URL da foto de capa da requisição.
 *
 * - Se foi enviado um arquivo via multipart (multer), usa o caminho gerado.
 * - Se o corpo contém foto_capa_url (string), mantém compatibilidade.
 * - Caso contrário, retorna undefined (não altera o valor existente).
 */
const resolverFotoCapa = (req) => {
  if (req.file) {
    return caminhoParaUrl(req.file.path, req);
  }
  if (typeof req.body?.foto_capa_url === 'string' && req.body.foto_capa_url.trim()) {
    return req.body.foto_capa_url.trim();
  }
  return undefined;
};

// ─────────────────────────────────────────────────────────────
//  Controllers
// ─────────────────────────────────────────────────────────────

/**
 * GET /api/eventos
 * RF09, RF15 – Listar eventos públicos (agendados).
 * Filtros opcionais: ?cidade=&estado=&data_inicio=
 */
const listar = async (req, res) => {
  const { cidade, estado, data_inicio, tipo_evento } = req.query;
  const { pagina, limite, offset } = parsePaginacao(req.query);

  try {
    let where = `
      WHERE e.status = 'agendado'
        AND (
          e.tipo_evento != 'musical'
          OR EXISTS (
            SELECT 1 FROM contratos c
            WHERE c.evento_id = e.id AND c.status_aceite = 'aceito'
          )
        )
    `;
    const params = [];
    let i = 1;

    if (cidade) {
      where += ` AND LOWER(pc.cidade) LIKE LOWER($${i++})`;
      params.push(`%${cidade}%`);
    }
    if (estado) {
      where += ` AND LOWER(pc.estado) = LOWER($${i++})`;
      params.push(estado);
    }
    if (data_inicio) {
      where += ` AND e.data_inicio >= $${i++}`;
      params.push(data_inicio);
    }
    if (tipo_evento) {
      if (!TIPOS_EVENTO.includes(tipo_evento)) {
        return res.status(400).json({ error: `tipo_evento inválido. Use: ${TIPOS_EVENTO.join(', ')}` });
      }
      where += ` AND e.tipo_evento = $${i++}`;
      params.push(tipo_evento);
    }

    const countRes = await pool.query(
      `SELECT COUNT(*)::int AS total
       FROM eventos e
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       ${where}`,
      params
    );
    const total = countRes.rows[0].total;

    const { rows } = await pool.query(
      `SELECT e.id, e.titulo, e.descricao, e.data_inicio, e.data_fim,
              e.local_nome, e.local_endereco,
              e.latitude, e.longitude,
              e.valor_ingresso, e.foto_capa_url, e.status, e.tipo_evento,
              pc.nome_entidade AS comunidade,
              pc.cidade, pc.estado,
              banda.nome_artistico AS banda
       FROM eventos e
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       LEFT JOIN LATERAL (
         SELECT pb.nome_artistico
         FROM contratos c
         JOIN perfis_bandas pb ON pb.usuario_id = c.banda_id
         WHERE c.evento_id = e.id AND c.status_aceite = 'aceito'
         LIMIT 1
       ) banda ON true
       ${where}
       ORDER BY e.data_inicio ASC
       LIMIT $${i++} OFFSET $${i++}`,
      [...params, limite, offset]
    );

    return res.json(respostaPaginada(rows, pagina, limite, total));

  } catch (err) {
    console.error('Erro ao listar eventos:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/eventos/:id
 * RF15 – Perfil público completo do evento.
 */
const buscarPorId = async (req, res) => {
  const { id } = req.params;

  try {
    const eventoRes = await pool.query(
      `SELECT e.id, e.titulo, e.descricao, e.data_inicio, e.data_fim,
              e.local_nome, e.local_endereco,
              e.latitude, e.longitude,
              e.valor_ingresso, e.foto_capa_url, e.status, e.tipo_evento,
              e.capacidade_maxima,
              pc.usuario_id AS comunidade_id,
              pc.nome_entidade AS comunidade,
              pc.whatsapp AS comunidade_whatsapp,
              pc.cidade, pc.estado
       FROM eventos e
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       WHERE e.id = $1`,
      [id]
    );
    if (eventoRes.rows.length === 0) {
      return res.status(404).json({ error: 'Evento não encontrado' });
    }

    const evento = eventoRes.rows[0];
    const souDono = req.usuario?.tipo === 'comunidade'
      && Number(req.usuario.id) === Number(evento.comunidade_id);

    if (!souDono) {
      const precisaConfirmacao = evento.tipo_evento === 'musical';
      if (precisaConfirmacao) {
        const contratoAceito = await pool.query(
          `SELECT 1 FROM contratos WHERE evento_id = $1 AND status_aceite = 'aceito' LIMIT 1`,
          [id]
        );
        if (contratoAceito.rows.length === 0) {
          return res.status(404).json({ error: 'Evento não encontrado' });
        }
      }
    }

    const diasRes = await pool.query(
      `SELECT id, data, data_fim_dia, hora_inicio, hora_fim, observacao
       FROM evento_dias
       WHERE evento_id = $1
       ORDER BY data ASC, hora_inicio ASC`,
      [id]
    );

    const bandasRes = await pool.query(
      `SELECT pb.usuario_id, pb.nome_artistico, pb.estilo_musical,
              c.id AS contrato_id, c.status_aceite
       FROM contratos c
       JOIN perfis_bandas pb ON pb.usuario_id = c.banda_id
       WHERE c.evento_id = $1`,
      [id]
    );

    const midiasRes = await pool.query(
      `SELECT id, tipo, url, titulo, descricao, ordem
       FROM evento_midias
       WHERE evento_id = $1
       ORDER BY ordem ASC`,
      [id]
    );

    let vagas_restantes = null;
    if (evento.capacidade_maxima != null) {
      const ocupacaoRes = await pool.query(
        `SELECT COALESCE(SUM(quantidade), 0)::int AS total FROM reservas
         WHERE evento_id = $1 AND status_pagamento IN ('pendente', 'confirmado')`,
        [id]
      );
      vagas_restantes = Math.max(0, evento.capacidade_maxima - ocupacaoRes.rows[0].total);
    }

    return res.json({
      ...evento,
      vagas_restantes,
      esgotado: vagas_restantes !== null && vagas_restantes <= 0,
      dias: diasRes.rows,
      bandas: bandasRes.rows,
      midias: midiasRes.rows,
    });

  } catch (err) {
    console.error('Erro ao buscar evento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * POST /api/eventos
 * RF06 – Criar evento (somente comunidade autenticada).
 *
 * Aceita multipart/form-data com campo "foto_capa" (imagem opcional).
 * O middleware uploadCapaEvento deve ser aplicado na rota antes deste controller.
 *
 * Campos de texto no body:
 *   titulo*, descricao, data_inicio*, data_fim*,
 *   local_nome, local_endereco, valor_ingresso, foto_capa_url (fallback string)
 */
const criar = async (req, res) => {
  const comunidade_id = req.usuario.id;
  const {
    titulo, descricao, data_inicio, data_fim,
    local_nome, local_endereco, valor_ingresso, tipo_evento, capacidade_maxima,
  } = req.body;

  if (!titulo || !data_inicio || !data_fim) {
    return res.status(400).json({ error: 'Campos obrigatórios: titulo, data_inicio, data_fim' });
  }

  if (tipo_evento && !TIPOS_EVENTO.includes(tipo_evento)) {
    return res.status(400).json({ error: `tipo_evento inválido. Use: ${TIPOS_EVENTO.join(', ')}` });
  }

  if (new Date(data_fim) < new Date(data_inicio)) {
    return res.status(400).json({ error: 'data_fim não pode ser anterior a data_inicio' });
  }

  const vendedoresRes = await pool.query(
    `SELECT COUNT(*)::int AS total FROM vendedores WHERE comunidade_id = $1 AND ativo = true`,
    [comunidade_id]
  );
  if (vendedoresRes.rows[0].total < VENDEDORES_MINIMO) {
    return res.status(422).json({
      error: `É preciso ter pelo menos ${VENDEDORES_MINIMO} vendedores ativos cadastrados para criar um evento.`,
    });
  }

  const foto_capa_url = resolverFotoCapa(req) ?? null;

  let latitude = null;
  let longitude = null;
  if (local_endereco) {
    const cleanAddress = local_endereco.includes(';')
      ? local_endereco.split(';').filter(p => p.trim()).join(', ')
      : local_endereco;
    const coords = await geocodificarEndereco(cleanAddress);
    if (coords) {
      latitude = coords.latitude;
      longitude = coords.longitude;
    }
  }

  try {
    // 1. Criação do evento na tabela 'eventos'
    const { rows } = await pool.query(
      `INSERT INTO eventos
          (comunidade_id, titulo, descricao, data_inicio, data_fim,
           local_nome, local_endereco, valor_ingresso, foto_capa_url, latitude, longitude, tipo_evento, capacidade_maxima)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,COALESCE($12,'musical'),$13)
        RETURNING id, titulo, data_inicio, data_fim, foto_capa_url, status, latitude, longitude, tipo_evento, capacidade_maxima`,
      [
        comunidade_id,
        titulo.trim(),
        descricao || null,
        data_inicio,
        data_fim,
        local_nome || null,
        local_endereco || null,
        valor_ingresso != null ? parseFloat(valor_ingresso) : null,
        foto_capa_url,
        latitude,
        longitude,
        tipo_evento || null,
        req.body.capacidade_maxima != null ? parseInt(req.body.capacidade_maxima, 10) : null,
      ]
    );

    const novoEvento = rows[0];

    return res.status(201).json({
      message: 'Evento criado com sucesso',
      evento: novoEvento
    });

  } catch (err) {
    console.error('Erro ao criar evento:', err.message, err.detail || '');
    if (err.code === '23514') {
      return res.status(400).json({ error: 'URL da foto de capa inválida.' });
    }
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PUT /api/eventos/:id
 * RF06, RF20 – Editar evento (somente a comunidade dona do evento).
 *
 * Aceita multipart/form-data com campo "foto_capa" (imagem opcional).
 * O middleware uploadCapaEvento deve ser aplicado na rota antes deste controller.
 */
const atualizar = async (req, res) => {
  const { id } = req.params;
  const comunidade_id = req.usuario.id;
  const {
    titulo, descricao, data_inicio, data_fim,
    local_nome, local_endereco, valor_ingresso, status, tipo_evento, capacidade_maxima,
  } = req.body;

  if (data_inicio && data_fim && new Date(data_fim) < new Date(data_inicio)) {
    return res.status(400).json({ error: 'data_fim não pode ser anterior a data_inicio' });
  }

  const statusValidos = ['agendado', 'cancelado', 'finalizado'];
  if (status && !statusValidos.includes(status)) {
    return res.status(400).json({ error: `Status inválido. Use: ${statusValidos.join(', ')}` });
  }

  if (tipo_evento && !TIPOS_EVENTO.includes(tipo_evento)) {
    return res.status(400).json({ error: `tipo_evento inválido. Use: ${TIPOS_EVENTO.join(', ')}` });
  }

  // Verifica ownership antes de montar o UPDATE
  const dono = await pool.query(
    'SELECT id, status FROM eventos WHERE id = $1 AND comunidade_id = $2',
    [id, comunidade_id]
  );
  if (dono.rows.length === 0) {
    return res.status(404).json({ error: 'Evento não encontrado ou sem permissão' });
  }

  // Transições de status válidas: só saindo de "agendado", pra cancelado ou
  // finalizado. "cancelado" e "finalizado" são estados terminais — não dá
  // pra "reviver" um evento cancelado/finalizado nem pular direto pra eles
  // sem ter passado por "agendado".
  const statusAtual = dono.rows[0].status;
  if (status && status !== statusAtual) {
    const transicoesValidas = { agendado: ['cancelado', 'finalizado'] };
    const permitido = (transicoesValidas[statusAtual] || []).includes(status);
    if (!permitido) {
      return res.status(409).json({
        error: `Não é possível mudar o status de "${statusAtual}" para "${status}"`,
      });
    }
  }

  const foto_capa_url = resolverFotoCapa(req); // undefined = não alterar

  let latitude = undefined;
  let longitude = undefined;
  if (local_endereco !== undefined) {
    if (local_endereco) {
      const cleanAddress = local_endereco.includes(';')
        ? local_endereco.split(';').filter(p => p.trim()).join(', ')
        : local_endereco;
      const coords = await geocodificarEndereco(cleanAddress);
      if (coords) {
        latitude = coords.latitude;
        longitude = coords.longitude;
      } else {
        latitude = null;
        longitude = null;
      }
    } else {
      latitude = null;
      longitude = null;
    }
  }

  try {
    const sets = [];
    const params = [];
    let i = 1;

    const campo = (coluna, valor) => {
      if (valor !== undefined && valor !== null && valor !== '') {
        sets.push(`${coluna} = $${i++}`);
        params.push(valor);
      }
    };

    campo('titulo', titulo?.trim());
    campo('descricao', descricao);
    campo('data_inicio', data_inicio);
    campo('data_fim', data_fim);
    campo('local_nome', local_nome);
    campo('local_endereco', local_endereco);
    campo('valor_ingresso', valor_ingresso != null ? parseFloat(valor_ingresso) : undefined);
    campo('status', status);
    campo('foto_capa_url', foto_capa_url);
    campo('tipo_evento', tipo_evento);
    if (capacidade_maxima !== undefined && capacidade_maxima !== '') {
      sets.push(`capacidade_maxima = $${i++}`);
      params.push(capacidade_maxima != null ? parseInt(capacidade_maxima, 10) : null);
    }

    if (latitude !== undefined) {
      sets.push(`latitude = $${i++}`);
      params.push(latitude);
    }
    if (longitude !== undefined) {
      sets.push(`longitude = $${i++}`);
      params.push(longitude);
    }

    if (sets.length === 0) {
      return res.status(400).json({ error: 'Nenhum campo fornecido para atualização' });
    }

    params.push(id);
    await pool.query(
      `UPDATE eventos SET ${sets.join(', ')} WHERE id = $${i}`,
      params
    );

    return res.json({ message: 'Evento atualizado com sucesso' });

  } catch (err) {
    console.error('Erro ao atualizar evento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * DELETE /api/eventos/:id
 * RF20 – Cancelar evento (soft: status → 'cancelado').
 */
const cancelar = async (req, res) => {
  const { id } = req.params;
  const comunidade_id = req.usuario.id;

  try {
    const result = await pool.query(
      `UPDATE eventos SET status = 'cancelado'
       WHERE id = $1 AND comunidade_id = $2
         AND status = 'agendado'
       RETURNING id`,
      [id, comunidade_id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Evento não encontrado, sem permissão ou já cancelado' });
    }
    return res.json({ message: 'Evento cancelado com sucesso' });

  } catch (err) {
    console.error('Erro ao cancelar evento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

// ─────────────────────────────────────────────────────────────
//  Dias do evento
// ─────────────────────────────────────────────────────────────

/**
 * POST /api/eventos/:id/dias
 * RF06 – Adicionar dia ao evento.
 */
const adicionarDia = async (req, res) => {
  const { id: evento_id } = req.params;
  const comunidade_id = req.usuario.id;
  const { data, data_fim_dia, hora_inicio, hora_fim, observacao } = req.body;

  if (!data || !hora_inicio || !hora_fim) {
    return res.status(400).json({ error: 'Campos obrigatórios: data, hora_inicio, hora_fim' });
  }

  // Verifica ownership e busca o período do evento para validar a data do dia
  const dono = await pool.query(
    'SELECT id, data_inicio, data_fim FROM eventos WHERE id = $1 AND comunidade_id = $2',
    [evento_id, comunidade_id]
  );
  if (dono.rows.length === 0) {
    return res.status(404).json({ error: 'Evento não encontrado ou sem permissão' });
  }

  const dataInicioStr = toDateStr(dono.rows[0].data_inicio);
  const dataFimStr = toDateStr(dono.rows[0].data_fim);
  if (data < dataInicioStr || data > dataFimStr) {
    const descricaoRange = dataInicioStr === dataFimStr
      ? `o dia ${formatDateBR(dataInicioStr)}`
      : `entre ${formatDateBR(dataInicioStr)} e ${formatDateBR(dataFimStr)}`;
    return res.status(400).json({
      error: `A data do dia deve ser ${descricaoRange} (o período do evento).`,
    });
  }

  try {
    const { rows } = await pool.query(
      `INSERT INTO evento_dias (evento_id, data, data_fim_dia, hora_inicio, hora_fim, observacao)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, data, hora_inicio, hora_fim`,
      [evento_id, data, data_fim_dia || data, hora_inicio, hora_fim, observacao || null]
    );
    return res.status(201).json({ message: 'Dia adicionado', dia: rows[0] });

  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Já existe um dia cadastrado nesta data para o evento' });
    }
    if (err.code === '23514') {
      return res.status(400).json({ error: 'data_fim_dia deve ser igual à data ou o dia seguinte' });
    }
    console.error('Erro ao adicionar dia:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * DELETE /api/eventos/:id/dias/:dia_id
 * RF06 – Remover dia do evento.
 */
const removerDia = async (req, res) => {
  const { id: evento_id, dia_id } = req.params;
  const comunidade_id = req.usuario.id;

  const dono = await pool.query(
    'SELECT id FROM eventos WHERE id = $1 AND comunidade_id = $2',
    [evento_id, comunidade_id]
  );
  if (dono.rows.length === 0) {
    return res.status(404).json({ error: 'Evento não encontrado ou sem permissão' });
  }

  try {
    const result = await pool.query(
      'DELETE FROM evento_dias WHERE id = $1 AND evento_id = $2 RETURNING id',
      [dia_id, evento_id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Dia não encontrado' });
    }
    return res.json({ message: 'Dia removido com sucesso' });

  } catch (err) {
    console.error('Erro ao remover dia:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

// ─────────────────────────────────────────────────────────────
//  Mídias do evento
// ─────────────────────────────────────────────────────────────

/**
 * POST /api/eventos/:id/midias
 * RF12 – Adicionar mídia ao evento (upload local).
 *
 * Aceita multipart/form-data:
 *   arquivo*  — arquivo de imagem ou vídeo
 *   titulo    — título opcional
 *   descricao — descrição opcional
 *   ordem     — número inteiro opcional (padrão 0)
 *
 * O middleware uploadMidiaEvento deve ser aplicado na rota antes deste controller.
 */
const adicionarMidia = async (req, res) => {
  const { id: evento_id } = req.params;
  const comunidade_id = req.usuario.id;

  if (!req.file) {
    return res.status(400).json({ error: 'Arquivo obrigatório (campo: arquivo)' });
  }

  // Verifica ownership
  const dono = await pool.query(
    'SELECT id FROM eventos WHERE id = $1 AND comunidade_id = $2',
    [evento_id, comunidade_id]
  );
  if (dono.rows.length === 0) {
    return res.status(404).json({ error: 'Evento não encontrado ou sem permissão' });
  }

  const url = caminhoParaUrl(req.file.path, req);
  const tipo = req.file.mimetype.startsWith('video/') ? 'video' : 'imagem';
  const titulo = req.body.titulo || null;
  const descricao = req.body.descricao || null;
  const ordem = parseInt(req.body.ordem, 10) || 0;

  try {
    const { rows } = await pool.query(
      `INSERT INTO evento_midias (evento_id, tipo, url, titulo, descricao, ordem)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, tipo, url, titulo, ordem`,
      [evento_id, tipo, url, titulo, descricao, ordem]
    );
    return res.status(201).json({ message: 'Mídia adicionada', midia: rows[0] });

  } catch (err) {
    if (err.code === '23514') {
      return res.status(400).json({ error: 'URL da mídia inválida.' });
    }
    console.error('Erro ao adicionar mídia do evento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * DELETE /api/eventos/:id/midias/:midia_id
 * RF12 – Remover mídia do evento.
 */
const removerMidia = async (req, res) => {
  const { id: evento_id, midia_id } = req.params;
  const comunidade_id = req.usuario.id;

  const dono = await pool.query(
    'SELECT id FROM eventos WHERE id = $1 AND comunidade_id = $2',
    [evento_id, comunidade_id]
  );
  if (dono.rows.length === 0) {
    return res.status(404).json({ error: 'Evento não encontrado ou sem permissão' });
  }

  try {
    const result = await pool.query(
      'DELETE FROM evento_midias WHERE id = $1 AND evento_id = $2 RETURNING id',
      [midia_id, evento_id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Mídia não encontrada' });
    }
    return res.json({ message: 'Mídia removida com sucesso' });

  } catch (err) {
    console.error('Erro ao remover mídia do evento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

// ─────────────────────────────────────────────────────────────
//  Contratos (convite de banda)
// ─────────────────────────────────────────────────────────────

/**
 * POST /api/eventos/:id/contratos
 * RF07 – Convidar banda para evento (somente comunidade dona do evento).
 */
const convidarBanda = async (req, res) => {
  const { id: evento_id } = req.params;
  const comunidade_id = req.usuario.id;
  const { banda_id } = req.body;

  if (!banda_id) {
    return res.status(400).json({ error: 'Campo obrigatório: banda_id' });
  }

  const dono = await pool.query(
    'SELECT id, titulo FROM eventos WHERE id = $1 AND comunidade_id = $2',
    [evento_id, comunidade_id]
  );
  if (dono.rows.length === 0) {
    return res.status(404).json({ error: 'Evento não encontrado ou sem permissão' });
  }

  // Verifica se a banda existe
  const banda = await pool.query(
    'SELECT usuario_id FROM perfis_bandas WHERE usuario_id = $1',
    [banda_id]
  );
  if (banda.rows.length === 0) {
    return res.status(404).json({ error: 'Banda não encontrada' });
  }

  try {
    const { rows } = await pool.query(
      `INSERT INTO contratos (evento_id, banda_id)
       VALUES ($1, $2)
       RETURNING id, status_aceite`,
      [evento_id, banda_id]
    );

    criarNotificacao({
      usuario_id: banda_id,
      tipo: 'contrato_recebido',
      titulo: 'Novo convite de evento',
      mensagem: `Você recebeu um convite para tocar em "${dono.rows[0].titulo}".`,
      payload: { evento_id: Number(evento_id), contrato_id: rows[0].id },
    });

    return res.status(201).json({ message: 'Convite enviado à banda', contrato: rows[0] });

  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Banda já convidada para este evento' });
    }
    console.error('Erro ao convidar banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * DELETE /api/eventos/:id/contratos/:contrato_id
 * RF07 – Remove o convite de uma banda (somente a comunidade dona do evento).
 * Usado ao trocar ou limpar a banda na edição do evento.
 */
const removerContrato = async (req, res) => {
  const { id: evento_id, contrato_id } = req.params;
  const comunidade_id = req.usuario.id;

  const dono = await pool.query(
    'SELECT id FROM eventos WHERE id = $1 AND comunidade_id = $2',
    [evento_id, comunidade_id]
  );
  if (dono.rows.length === 0) {
    return res.status(404).json({ error: 'Evento não encontrado ou sem permissão' });
  }

  try {
    const result = await pool.query(
      'DELETE FROM contratos WHERE id = $1 AND evento_id = $2 RETURNING id',
      [contrato_id, evento_id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Convite não encontrado' });
    }
    return res.json({ message: 'Convite removido com sucesso' });

  } catch (err) {
    console.error('Erro ao remover convite:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PATCH /api/eventos/contratos/:contrato_id/responder
 * RF07 – Banda responde ao convite (aceitar ou recusar).
 */
const responderContrato = async (req, res) => {
  const { contrato_id } = req.params;
  const banda_id = req.usuario.id;
  // Aceita 'status_aceite' (frontend contratos.jsx) ou 'resposta' (legado)
  const resposta = req.body.status_aceite || req.body.resposta;

  const respostasValidas = ['aceito', 'recusado'];
  if (!respostasValidas.includes(resposta)) {
    return res.status(400).json({ error: `Resposta inválida. Use: ${respostasValidas.join(', ')}` });
  }

  try {
    const contratoRes = await pool.query(
      `SELECT c.id, c.status_aceite, c.evento_id, e.titulo AS evento_titulo,
              e.comunidade_id, pb.nome_artistico AS banda_nome
       FROM contratos c
       JOIN eventos e ON e.id = c.evento_id
       JOIN perfis_bandas pb ON pb.usuario_id = c.banda_id
       WHERE c.id = $1 AND c.banda_id = $2`,
      [contrato_id, banda_id]
    );
    if (contratoRes.rows.length === 0) {
      return res.status(404).json({ error: 'Contrato não encontrado ou sem permissão' });
    }

    const contrato = contratoRes.rows[0];

    if (contrato.status_aceite !== 'pendente') {
      return res.status(409).json({ error: 'Contrato já respondido' });
    }

    const dataAssinatura = resposta === 'aceito' ? 'NOW()' : 'NULL';

    await pool.query(
      `UPDATE contratos SET status_aceite = $1, data_assinatura = ${dataAssinatura}
       WHERE id = $2`,
      [resposta, contrato_id]
    );

    // Log de auditoria
    await pool.query(
      `INSERT INTO logs_status_contratos (contrato_id, status_anterior, status_novo, usuario_id)
       VALUES ($1, 'pendente', $2, $3)`,
      [contrato_id, resposta, banda_id]
    );

    criarNotificacao({
      usuario_id: contrato.comunidade_id,
      tipo: resposta === 'aceito' ? 'contrato_confirmado' : 'contrato_recusado',
      titulo: resposta === 'aceito' ? 'Banda confirmou presença' : 'Banda recusou o convite',
      mensagem: `${contrato.banda_nome} ${resposta === 'aceito' ? 'aceitou' : 'recusou'} o convite para "${contrato.evento_titulo}".`,
      payload: { evento_id: contrato.evento_id, contrato_id: Number(contrato_id) },
    });

    return res.json({ message: `Contrato ${resposta} com sucesso` });

  } catch (err) {
    console.error('Erro ao responder contrato:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

const calendario = async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT e.id, e.titulo, e.data_inicio, e.data_fim, e.status,
              pc.usuario_id AS comunidade_id, pc.nome_entidade AS comunidade,
              pc.cidade, pc.estado
       FROM eventos e
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       WHERE e.status != 'cancelado'
       ORDER BY e.data_inicio ASC`
    );
    return res.json(rows);
  } catch (err) {
    console.error('Erro ao buscar calendário:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/eventos/:id/dashboard
 * Dashboard exclusivo da comunidade dona do evento.
 * Retorna métricas de reservas, vendedores, bandas, dias e histórico.
 */
const dashboardEvento = async (req, res) => {
  const { id } = req.params;
  const comunidade_id = req.usuario.id;

  try {
    // Guard: verifica que a comunidade autenticada é dona do evento
    const donoRes = await pool.query(
      `SELECT e.id, e.titulo, e.descricao, e.data_inicio, e.data_fim,
              e.local_nome, e.local_endereco, e.valor_ingresso,
              e.foto_capa_url, e.status, e.tipo_evento,
              e.capacidade_maxima, e.latitude, e.longitude,
              pc.nome_entidade AS comunidade, pc.cidade, pc.estado
       FROM eventos e
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       WHERE e.id = $1 AND e.comunidade_id = $2`,
      [id, comunidade_id]
    );

    if (donoRes.rows.length === 0) {
      return res.status(404).json({ error: 'Evento não encontrado ou sem permissão' });
    }

    const evento = donoRes.rows[0];

    // ── Métricas de reservas ──────────────────────────────────
    const reservasMetricsRes = await pool.query(
      `SELECT
         COUNT(*)::int                                                         AS total_reservas,
         COUNT(*) FILTER (WHERE status_pagamento = 'pendente')::int           AS reservas_pendentes,
         COUNT(*) FILTER (WHERE status_pagamento = 'confirmado')::int         AS reservas_confirmadas,
         COUNT(*) FILTER (WHERE status_pagamento = 'cancelado')::int          AS reservas_canceladas,
         COUNT(*) FILTER (WHERE status_pagamento = 'rejeitado')::int          AS reservas_rejeitadas,
         COALESCE(SUM(quantidade) FILTER
           (WHERE status_pagamento IN ('pendente','confirmado')), 0)::int     AS total_ingressos_reservados,
         COALESCE(SUM(quantidade) FILTER
           (WHERE status_pagamento = 'confirmado'), 0)::int                   AS total_ingressos_confirmados,
         COALESCE(SUM(quantidade * COALESCE($2::numeric, 0)) FILTER
           (WHERE status_pagamento = 'confirmado'), 0)::float                 AS receita_estimada
       FROM reservas
       WHERE evento_id = $1`,
      [id, evento.valor_ingresso]
    );

    const metricas = reservasMetricsRes.rows[0];

    // ── Lista de reservas (últimas 50) ────────────────────────
    const reservasRes = await pool.query(
      `SELECT r.id, r.quantidade, r.status_pagamento, r.forma_pagamento,
              r.nome_retirada, r.criado_em,
              pp.nome AS comprador_nome, u.email AS comprador_email,
              v.nome AS vendedor_nome, v.whatsapp AS vendedor_whatsapp
       FROM reservas r
       JOIN usuarios u ON u.id = r.comprador_id
       LEFT JOIN perfis_pessoais pp ON pp.usuario_id = r.comprador_id
       LEFT JOIN vendedores v ON v.id = r.vendedor_id
       WHERE r.evento_id = $1
       ORDER BY r.criado_em DESC
       LIMIT 50`,
      [id]
    );

    // ── Vendedores ativos da comunidade ───────────────────────
    const vendedoresRes = await pool.query(
      `SELECT v.id, v.nome, v.whatsapp, v.ativo, v.criado_em,
              COALESCE(SUM(r.quantidade) FILTER
                (WHERE r.evento_id = $1 AND r.status_pagamento = 'confirmado'), 0)::int
                AS ingressos_vendidos_evento,
              COALESCE(SUM(r.quantidade * COALESCE(e2.valor_ingresso, 0)) FILTER
                (WHERE r.evento_id = $1 AND r.status_pagamento = 'confirmado'), 0)::float
                AS receita_evento
       FROM vendedores v
       LEFT JOIN reservas r ON r.vendedor_id = v.id
       LEFT JOIN eventos e2 ON e2.id = r.evento_id
       WHERE v.comunidade_id = $2 AND v.ativo = true
       GROUP BY v.id
       ORDER BY v.nome ASC`,
      [id, comunidade_id]
    );

    // ── Bandas / contratos ────────────────────────────────────
    const bandasRes = await pool.query(
      `SELECT c.id AS contrato_id, c.status_aceite, c.data_assinatura,
              pb.usuario_id AS banda_id, pb.nome_artistico, pb.estilo_musical, pb.whatsapp
       FROM contratos c
       JOIN perfis_bandas pb ON pb.usuario_id = c.banda_id
       WHERE c.evento_id = $1
       ORDER BY c.criado_em ASC`,
      [id]
    );

    // ── Dias do evento ────────────────────────────────────────
    const diasRes = await pool.query(
      `SELECT id, data, data_fim_dia, hora_inicio, hora_fim, observacao
       FROM evento_dias
       WHERE evento_id = $1
       ORDER BY data ASC, hora_inicio ASC`,
      [id]
    );

    // ── Histórico de logs de pagamento ────────────────────────
    const historicoRes = await pool.query(
      `SELECT lp.id, lp.reserva_id, lp.status_anterior, lp.status_novo, lp.criado_em,
              pp.nome AS operador_nome, u.email AS operador_email
       FROM logs_status_pagamentos lp
       JOIN reservas r ON r.id = lp.reserva_id
       LEFT JOIN usuarios u ON u.id = lp.usuario_id
       LEFT JOIN perfis_pessoais pp ON pp.usuario_id = lp.usuario_id
       WHERE r.evento_id = $1
       ORDER BY lp.criado_em DESC
       LIMIT 100`,
      [id]
    );

    // ── Crescimento de reservas por dia ───────────────────────
    const crescimentoRes = await pool.query(
      `SELECT DATE(r.criado_em AT TIME ZONE 'America/Sao_Paulo') AS data,
              COUNT(*)::int AS novas_reservas,
              SUM(quantidade)::int AS novos_ingressos
       FROM reservas r
       WHERE r.evento_id = $1
       GROUP BY DATE(r.criado_em AT TIME ZONE 'America/Sao_Paulo')
       ORDER BY 1 ASC`,
      [id]
    );

    return res.json({
      evento,
      metricas: {
        ...metricas,
        capacidade_maxima: evento.capacidade_maxima,
        percentual_ocupacao:
          evento.capacidade_maxima && metricas.total_ingressos_confirmados
            ? Math.round((metricas.total_ingressos_confirmados / evento.capacidade_maxima) * 100)
            : null,
      },
      reservas: reservasRes.rows,
      vendedores: vendedoresRes.rows,
      bandas: bandasRes.rows,
      dias: diasRes.rows,
      historico_pagamentos: historicoRes.rows,
      crescimento: crescimentoRes.rows,
    });

  } catch (err) {
    console.error('Erro ao buscar dashboard do evento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = {
  listar,
  buscarPorId,
  criar,
  atualizar,
  cancelar,
  adicionarDia,
  removerDia,
  adicionarMidia,
  removerMidia,
  convidarBanda,
  removerContrato,
  responderContrato,
  calendario,
  dashboardEvento,
};