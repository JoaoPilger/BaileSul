const pool = require('../config/database');
const { parsePaginacao, respostaPaginada } = require('../utils/pagination');
const { caminhoParaUrl } = require('../middlewares/upload');

// ─────────────────────────────────────────────────────────────
//  Helpers internos
// ─────────────────────────────────────────────────────────────

/**
 * Extrai a URL da foto de capa da requisição.
 *
 * - Se foi enviado um arquivo via multipart (multer), usa o caminho gerado.
 * - Se o corpo contém foto_capa_url (string), mantém compatibilidade.
 * - Caso contrário, retorna undefined (não altera o valor existente).
 */
const resolverFotoCapa = (req) => {
  if (req.file) {
    return caminhoParaUrl(req.file.path);
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
  const { cidade, estado, data_inicio } = req.query;
  const { pagina, limite, offset } = parsePaginacao(req.query);

  try {
    let where = "WHERE e.status = 'agendado'";
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

    const countRes = await pool.query(
      `SELECT COUNT(*)::int AS total
       FROM eventos e
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       ${where}`,
      params
    );
    const total = countRes.rows[0].total;

    const { rows } = await pool.query(
      `SELECT e.id, e.titulo, e.data_inicio, e.data_fim,
              e.local_nome, e.local_endereco,
              e.latitude, e.longitude,
              e.valor_ingresso, e.foto_capa_url, e.status,
              pc.nome_entidade AS comunidade,
              pc.cidade, pc.estado
       FROM eventos e
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
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
              e.valor_ingresso, e.foto_capa_url, e.status,
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

    const diasRes = await pool.query(
      `SELECT id, data, data_fim_dia, hora_inicio, hora_fim, observacao
       FROM evento_dias
       WHERE evento_id = $1
       ORDER BY data ASC, hora_inicio ASC`,
      [id]
    );

    const bandasRes = await pool.query(
      `SELECT pb.usuario_id, pb.nome_artistico, pb.estilo_musical,
              c.status_aceite
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

    return res.json({
      ...eventoRes.rows[0],
      dias:   diasRes.rows,
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
    local_nome, local_endereco, valor_ingresso,
  } = req.body;

  if (!titulo || !data_inicio || !data_fim) {
    return res.status(400).json({ error: 'Campos obrigatórios: titulo, data_inicio, data_fim' });
  }

  if (new Date(data_fim) < new Date(data_inicio)) {
    return res.status(400).json({ error: 'data_fim não pode ser anterior a data_inicio' });
  }

  const foto_capa_url = resolverFotoCapa(req) ?? null;

  try {
    const { rows } = await pool.query(
      `INSERT INTO eventos
         (comunidade_id, titulo, descricao, data_inicio, data_fim,
          local_nome, local_endereco, valor_ingresso, foto_capa_url)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING id, titulo, data_inicio, data_fim, foto_capa_url, status`,
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
      ]
    );

    return res.status(201).json({ message: 'Evento criado com sucesso', evento: rows[0] });

  } catch (err) {
    console.error('Erro ao criar evento:', err.message);
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
  const { id }       = req.params;
  const comunidade_id = req.usuario.id;
  const {
    titulo, descricao, data_inicio, data_fim,
    local_nome, local_endereco, valor_ingresso, status,
  } = req.body;

  if (data_inicio && data_fim && new Date(data_fim) < new Date(data_inicio)) {
    return res.status(400).json({ error: 'data_fim não pode ser anterior a data_inicio' });
  }

  const statusValidos = ['agendado', 'cancelado', 'finalizado'];
  if (status && !statusValidos.includes(status)) {
    return res.status(400).json({ error: `Status inválido. Use: ${statusValidos.join(', ')}` });
  }

  // Verifica ownership antes de montar o UPDATE
  const dono = await pool.query(
    'SELECT id FROM eventos WHERE id = $1 AND comunidade_id = $2',
    [id, comunidade_id]
  );
  if (dono.rows.length === 0) {
    return res.status(404).json({ error: 'Evento não encontrado ou sem permissão' });
  }

  const foto_capa_url = resolverFotoCapa(req); // undefined = não alterar

  try {
    const sets  = [];
    const params = [];
    let i = 1;

    const campo = (coluna, valor) => {
      if (valor !== undefined && valor !== null && valor !== '') {
        sets.push(`${coluna} = $${i++}`);
        params.push(valor);
      }
    };

    campo('titulo',         titulo?.trim());
    campo('descricao',      descricao);
    campo('data_inicio',    data_inicio);
    campo('data_fim',       data_fim);
    campo('local_nome',     local_nome);
    campo('local_endereco', local_endereco);
    campo('valor_ingresso', valor_ingresso != null ? parseFloat(valor_ingresso) : undefined);
    campo('status',         status);
    campo('foto_capa_url',  foto_capa_url);

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
  const { id }       = req.params;
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
  const comunidade_id     = req.usuario.id;
  const { data, data_fim_dia, hora_inicio, hora_fim, observacao } = req.body;

  if (!data || !hora_inicio || !hora_fim) {
    return res.status(400).json({ error: 'Campos obrigatórios: data, hora_inicio, hora_fim' });
  }

  // Verifica ownership
  const dono = await pool.query(
    'SELECT id FROM eventos WHERE id = $1 AND comunidade_id = $2',
    [evento_id, comunidade_id]
  );
  if (dono.rows.length === 0) {
    return res.status(404).json({ error: 'Evento não encontrado ou sem permissão' });
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
  const comunidade_id             = req.usuario.id;

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
  const comunidade_id     = req.usuario.id;

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

  const url       = caminhoParaUrl(req.file.path);
  const tipo      = req.file.mimetype.startsWith('video/') ? 'video' : 'imagem';
  const titulo    = req.body.titulo    || null;
  const descricao = req.body.descricao || null;
  const ordem     = parseInt(req.body.ordem, 10) || 0;

  try {
    const { rows } = await pool.query(
      `INSERT INTO evento_midias (evento_id, tipo, url, titulo, descricao, ordem)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, tipo, url, titulo, ordem`,
      [evento_id, tipo, url, titulo, descricao, ordem]
    );
    return res.status(201).json({ message: 'Mídia adicionada', midia: rows[0] });

  } catch (err) {
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
  const comunidade_id               = req.usuario.id;

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
  const comunidade_id     = req.usuario.id;
  const { banda_id }      = req.body;

  if (!banda_id) {
    return res.status(400).json({ error: 'Campo obrigatório: banda_id' });
  }

  const dono = await pool.query(
    'SELECT id FROM eventos WHERE id = $1 AND comunidade_id = $2',
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
 * PATCH /api/eventos/contratos/:contrato_id/responder
 * RF07 – Banda responde ao convite (aceitar ou recusar).
 */
const responderContrato = async (req, res) => {
  const { contrato_id } = req.params;
  const banda_id        = req.usuario.id;
  const { resposta }    = req.body; // 'aceito' | 'recusado'

  const respostasValidas = ['aceito', 'recusado'];
  if (!respostasValidas.includes(resposta)) {
    return res.status(400).json({ error: `Resposta inválida. Use: ${respostasValidas.join(', ')}` });
  }

  try {
    const contratoRes = await pool.query(
      'SELECT id, status_aceite FROM contratos WHERE id = $1 AND banda_id = $2',
      [contrato_id, banda_id]
    );
    if (contratoRes.rows.length === 0) {
      return res.status(404).json({ error: 'Contrato não encontrado ou sem permissão' });
    }

    if (contratoRes.rows[0].status_aceite !== 'pendente') {
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
              pc.nome_entidade AS comunidade, pc.cidade, pc.estado
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
  responderContrato,
  calendario
};