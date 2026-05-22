const pool = require('../config/database');
const { geocodificarEndereco, calcularDistanciaKm } = require('../services/external.service');

// Status válidos para transição manual (comunidade não pode pular para 'finalizado' diretamente)
const TRANSICOES_VALIDAS = {
  agendado: ['cancelado'],
  cancelado: [],
  finalizado: [],
};

/**
 * GET /api/eventos
 * RF14, RF16 – Listar eventos com filtros:
 *   ?data=&banda=&estilo=&cidade=&estado=&lat=&lng=&raio_km=
 * Público
 */
const listar = async (req, res) => {
  const { data, banda, estilo, cidade, estado, lat, lng, raio_km } = req.query;

  try {
    let query = `
      SELECT
        e.id, e.titulo, e.descricao, e.data_inicio, e.data_fim,
        e.local_nome, e.valor_ingresso, e.status, e.foto_capa_url,
        e.latitude, e.longitude,
        pc.nome_entidade AS comunidade_nome,
        pc.cidade AS comunidade_cidade,
        pc.estado AS comunidade_estado
      FROM eventos e
      JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
      WHERE e.status = 'agendado'
    `;
    const params = [];
    let i = 1;

    if (data) {
      query += ` AND e.data_inicio::date = $${i++}`;
      params.push(data);
    }
    if (cidade) {
      query += ` AND LOWER(pc.cidade) LIKE LOWER($${i++})`;
      params.push(`%${cidade}%`);
    }
    if (estado) {
      query += ` AND LOWER(pc.estado) = LOWER($${i++})`;
      params.push(estado);
    }
    if (estilo) {
      query += ` AND e.id IN (
        SELECT c.evento_id FROM contratos c
        JOIN perfis_bandas pb ON pb.usuario_id = c.banda_id
        WHERE LOWER(pb.estilo_musical) LIKE LOWER($${i++})
      )`;
      params.push(`%${estilo}%`);
    }
    if (banda) {
      query += ` AND e.id IN (
        SELECT c.evento_id FROM contratos c
        JOIN perfis_bandas pb ON pb.usuario_id = c.banda_id
        WHERE LOWER(pb.nome_artistico) LIKE LOWER($${i++})
      )`;
      params.push(`%${banda}%`);
    }

    query += ' ORDER BY e.data_inicio ASC';

    const { rows } = await pool.query(query, params);

    // RF16 – Filtro por proximidade geográfica (client-side com geolib/Haversine)
    // Filtramos após a query para não perder eventos sem coordenadas
    if (lat && lng && raio_km) {
      const latNum = parseFloat(lat);
      const lngNum = parseFloat(lng);
      const raio = parseFloat(raio_km);

      if (!isNaN(latNum) && !isNaN(lngNum) && !isNaN(raio)) {
        const filtrados = rows.filter((e) => {
          if (!e.latitude || !e.longitude) return true; // inclui sem coords
          const dist = calcularDistanciaKm(latNum, lngNum, e.latitude, e.longitude);
          return dist <= raio;
        });
        return res.json(filtrados);
      }
    }

    return res.json(rows);

  } catch (err) {
    console.error('Erro ao listar eventos:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/eventos/:id
 * RF17 – Página exclusiva do evento com detalhes completos
 * Público
 */
const buscarPorId = async (req, res) => {
  const { id } = req.params;

  try {
    const eventoRes = await pool.query(
      `SELECT e.*, pc.nome_entidade, pc.whatsapp AS comunidade_whatsapp,
              pc.cidade, pc.estado, pc.endereco
       FROM eventos e
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       WHERE e.id = $1`,
      [id]
    );
    if (eventoRes.rows.length === 0) {
      return res.status(404).json({ error: 'Evento não encontrado' });
    }

    const bandasRes = await pool.query(
      `SELECT pb.usuario_id, pb.nome_artistico, pb.estilo_musical, pb.whatsapp,
              c.status_aceite
       FROM contratos c
       JOIN perfis_bandas pb ON pb.usuario_id = c.banda_id
       WHERE c.evento_id = $1`,
      [id]
    );

    const vendedoresRes = await pool.query(
      `SELECT v.id, v.nome, v.whatsapp
       FROM vendedores v
       WHERE v.comunidade_id = $1 AND v.ativo = true`,
      [eventoRes.rows[0].comunidade_id]
    );

    const diasRes = await pool.query(
      'SELECT * FROM evento_dias WHERE evento_id = $1 ORDER BY data',
      [id]
    );

    const midiasRes = await pool.query(
      `SELECT id, tipo, url, titulo, ordem
       FROM evento_midias
       WHERE evento_id = $1
       ORDER BY ordem ASC`,
      [id]
    );

    return res.json({
      ...eventoRes.rows[0],
      bandas: bandasRes.rows,
      vendedores: vendedoresRes.rows,
      dias: diasRes.rows,
      midias: midiasRes.rows,
    });

  } catch (err) {
    console.error('Erro ao buscar evento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * POST /api/eventos
 * RF07 – Criar evento (somente comunidade)
 * RF06 – Verificar conflito de datas no calendário compartilhado
 */
const criar = async (req, res) => {

  console.log("Headers recebidos:", req.headers);
  console.log("Corpo recebido:", req.body);
  
  const {
    titulo, descricao, data_inicio, data_fim,
    local_nome, local_endereco, valor_ingresso, foto_capa_url,
    bandas,
    dias,
  } = req.body;

  if (!titulo || !data_inicio || !data_fim) {
    return res.status(400).json({ error: 'Campos obrigatórios: titulo, data_inicio, data_fim' });
  }

  if (new Date(data_fim) < new Date(data_inicio)) {
    return res.status(400).json({ error: 'data_fim não pode ser anterior a data_inicio' });
  }

  if (foto_capa_url && !/^https?:\/\//.test(foto_capa_url)) {
    return res.status(400).json({ error: 'foto_capa_url deve começar com http:// ou https://' });
  }

  const comunidade_id = req.usuario.id;

  // Geocodificação do local do evento
  const enderecoGeo = local_endereco || local_nome;
  const coords = enderecoGeo ? await geocodificarEndereco(enderecoGeo + ', Brasil') : null;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // RF06 – Detectar sobreposição de datas na mesma cidade
    const conflito = await client.query(
      `SELECT e.id, e.titulo, pc.cidade
       FROM eventos e
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       JOIN perfis_comunidades pc2 ON pc2.usuario_id = $1
       WHERE e.status = 'agendado'
         AND pc.cidade = pc2.cidade
         AND (e.data_inicio, e.data_fim) OVERLAPS ($2::date, $3::date)`,
      [comunidade_id, data_inicio, data_fim]
    );

    // INSERT evento
    const eventoRes = await client.query(
      `INSERT INTO eventos
         (comunidade_id, titulo, descricao, data_inicio, data_fim, local_nome,
          local_endereco, latitude, longitude, valor_ingresso, foto_capa_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING id`,
      [
        comunidade_id, titulo, descricao || null, data_inicio, data_fim,
        local_nome || null, local_endereco || null,
        coords?.latitude ?? null, coords?.longitude ?? null,
        valor_ingresso || null, foto_capa_url || null,
      ]
    );
    const evento_id = eventoRes.rows[0].id;

    // INSERT contratos para bandas informadas
    if (Array.isArray(bandas)) {
      for (const banda_id of bandas) {
        // Verifica que a banda existe antes de inserir
        const bandaExiste = await client.query(
          'SELECT usuario_id FROM perfis_bandas WHERE usuario_id = $1',
          [banda_id]
        );
        if (bandaExiste.rows.length === 0) {
          await client.query('ROLLBACK');
          return res.status(404).json({ error: `Banda com id ${banda_id} não encontrada` });
        }
        await client.query(
          'INSERT INTO contratos (evento_id, banda_id) VALUES ($1, $2)',
          [evento_id, banda_id]
        );
      }
    }

    // INSERT dias do evento com validação
    if (Array.isArray(dias)) {
      for (const dia of dias) {
        if (!dia.data || !dia.hora_inicio || !dia.hora_fim) {
          await client.query('ROLLBACK');
          return res.status(400).json({
            error: 'Cada dia deve ter: data, hora_inicio, hora_fim',
          });
        }
        const data_fim_dia = dia.data_fim_dia || dia.data;
        await client.query(
          `INSERT INTO evento_dias (evento_id, data, data_fim_dia, hora_inicio, hora_fim, observacao)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [evento_id, dia.data, data_fim_dia, dia.hora_inicio, dia.hora_fim, dia.observacao || null]
        );
      }
    }

    await client.query('COMMIT');

    return res.status(201).json({
      message: 'Evento criado com sucesso',
      evento_id,
      conflitos_de_data: conflito.rows,
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erro ao criar evento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  } finally {
    client.release();
  }
};

/**
 * PUT /api/eventos/:id
 * RF07 – Editar evento (somente comunidade dona)
 * Status: apenas transições válidas permitidas.
 */
const atualizar = async (req, res) => {
  const { id } = req.params;
  const comunidade_id = req.usuario.id;

  try {
    const dono = await pool.query(
      'SELECT id, status FROM eventos WHERE id = $1 AND comunidade_id = $2',
      [id, comunidade_id]
    );
    if (dono.rows.length === 0) {
      return res.status(403).json({ error: 'Evento não encontrado ou sem permissão' });
    }

    const statusAtual = dono.rows[0].status;
    const {
      titulo, descricao, data_inicio, data_fim,
      local_nome, local_endereco, valor_ingresso, foto_capa_url, status
    } = req.body;

    // Validar transição de status
    if (status && status !== statusAtual) {
      const transicoesPermitidas = TRANSICOES_VALIDAS[statusAtual] || [];
      if (!transicoesPermitidas.includes(status)) {
        return res.status(400).json({
          error: `Transição de status inválida: '${statusAtual}' → '${status}'. Permitidas: ${transicoesPermitidas.join(', ') || 'nenhuma'}`,
        });
      }
    }

    if (foto_capa_url && !/^https?:\/\//.test(foto_capa_url)) {
      return res.status(400).json({ error: 'foto_capa_url deve começar com http:// ou https://' });
    }

    // Re-geocodificar se endereço mudou
    let lat = undefined;
    let lng = undefined;
    if (local_endereco || local_nome) {
      const endGeo = local_endereco || local_nome;
      const coords = await geocodificarEndereco(endGeo + ', Brasil');
      if (coords) {
        lat = coords.latitude;
        lng = coords.longitude;
      }
    }

    await pool.query(
      `UPDATE eventos SET
         titulo         = COALESCE($1, titulo),
         descricao      = COALESCE($2, descricao),
         data_inicio    = COALESCE($3, data_inicio),
         data_fim       = COALESCE($4, data_fim),
         local_nome     = COALESCE($5, local_nome),
         local_endereco = COALESCE($6, local_endereco),
         latitude       = COALESCE($7, latitude),
         longitude      = COALESCE($8, longitude),
         valor_ingresso = COALESCE($9, valor_ingresso),
         foto_capa_url  = COALESCE($10, foto_capa_url),
         status         = COALESCE($11, status)
       WHERE id = $12`,
      [titulo, descricao, data_inicio, data_fim, local_nome, local_endereco,
       lat ?? null, lng ?? null, valor_ingresso, foto_capa_url, status, id]
    );

    return res.json({ message: 'Evento atualizado com sucesso' });

  } catch (err) {
    console.error('Erro ao atualizar evento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * DELETE /api/eventos/:id
 * RF07 – Remover evento (somente comunidade dona) — soft delete via status
 */
const remover = async (req, res) => {
  const { id } = req.params;
  const comunidade_id = req.usuario.id;

  try {
    const dono = await pool.query(
      'SELECT id FROM eventos WHERE id = $1 AND comunidade_id = $2',
      [id, comunidade_id]
    );
    if (dono.rows.length === 0) {
      return res.status(403).json({ error: 'Evento não encontrado ou sem permissão' });
    }

    await pool.query(
      "UPDATE eventos SET status = 'cancelado' WHERE id = $1",
      [id]
    );

    return res.json({ message: 'Evento cancelado com sucesso' });

  } catch (err) {
    console.error('Erro ao remover evento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/eventos/calendario
 * RF06 – Calendário compartilhado entre comunidades (somente comunidade)
 */
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

/**
 * PATCH /api/eventos/:id/contratos/:contrato_id
 * Banda aceita ou recusa contrato de participação em evento.
 */
const responderContrato = async (req, res) => {
  const { id: evento_id, contrato_id } = req.params;
  const banda_id = req.usuario.id;
  const { status_aceite } = req.body;

  if (!['aceito', 'recusado'].includes(status_aceite)) {
    return res.status(400).json({ error: "status_aceite deve ser 'aceito' ou 'recusado'" });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const contratoRes = await client.query(
      `SELECT id, status_aceite FROM contratos
       WHERE id = $1 AND evento_id = $2 AND banda_id = $3`,
      [contrato_id, evento_id, banda_id]
    );

    if (contratoRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Contrato não encontrado ou sem permissão' });
    }

    const statusAnterior = contratoRes.rows[0].status_aceite;

    if (statusAnterior !== 'pendente') {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Contrato já foi respondido anteriormente' });
    }

    await client.query(
      `UPDATE contratos SET
         status_aceite   = $1,
         data_assinatura = CASE WHEN $1 = 'aceito' THEN NOW() ELSE NULL END
       WHERE id = $2`,
      [status_aceite, contrato_id]
    );

    // Log de auditoria
    await client.query(
      `INSERT INTO logs_status_contratos (contrato_id, status_anterior, status_novo, usuario_id)
       VALUES ($1, $2, $3, $4)`,
      [contrato_id, statusAnterior, status_aceite, banda_id]
    );

    await client.query('COMMIT');
    return res.json({ message: `Contrato ${status_aceite} com sucesso` });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erro ao responder contrato:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  } finally {
    client.release();
  }
};

module.exports = { listar, buscarPorId, criar, atualizar, remover, calendario, responderContrato };