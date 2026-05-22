const pool = require('../config/database');
const { geocodificarEndereco } = require('../services/external.service');

/**
 * GET /api/bandas
 * RF10, RF15 – Listar bandas públicas com filtro opcional: ?estilo=&cidade=
 *
 * Filtro por cidade: aplica sobre eventos contratados da banda
 * (cidade da comunidade organizadora) ou sobre a cidade da
 * comunidade mais próxima associada — como bandas não têm
 * cidade própria no perfil, o filtro busca bandas que já
 * tocaram/tocam em eventos na cidade informada.
 */
const listar = async (req, res) => {
  const { estilo, cidade } = req.query;

  try {
    let query = `
      SELECT DISTINCT pb.usuario_id, pb.nome_artistico, pb.estilo_musical,
             pb.descricao, pb.whatsapp, pb.cnpj_validado
      FROM perfis_bandas pb
      JOIN usuarios u ON u.id = pb.usuario_id
      WHERE 1=1
    `;
    const params = [];
    let i = 1;

    if (estilo) {
      query += ` AND LOWER(pb.estilo_musical) LIKE LOWER($${i++})`;
      params.push(`%${estilo}%`);
    }

    // Filtro de cidade: bandas com contratos em eventos de comunidades nessa cidade
    if (cidade) {
      query += `
        AND pb.usuario_id IN (
          SELECT c.banda_id
          FROM contratos c
          JOIN eventos e ON e.id = c.evento_id
          JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
          WHERE LOWER(pc.cidade) LIKE LOWER($${i++})
        )
      `;
      params.push(`%${cidade}%`);
    }

    query += ' ORDER BY pb.nome_artistico ASC';

    const { rows } = await pool.query(query, params);
    return res.json(rows);

  } catch (err) {
    console.error('Erro ao listar bandas:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/bandas/:id
 * RF15 – Perfil público detalhado da banda
 */
const buscarPorId = async (req, res) => {
  const { id } = req.params;

  try {
    const bandaRes = await pool.query(
      `SELECT pb.usuario_id, pb.nome_artistico, pb.estilo_musical,
              pb.descricao, pb.whatsapp, pb.video_url, pb.cnpj_validado
       FROM perfis_bandas pb
       WHERE pb.usuario_id = $1`,
      [id]
    );
    if (bandaRes.rows.length === 0) {
      return res.status(404).json({ error: 'Banda não encontrada' });
    }

    // Eventos futuros contratados (aceitos)
    const eventosRes = await pool.query(
      `SELECT e.id, e.titulo, e.data_inicio, e.data_fim,
              e.local_nome, pc.nome_entidade AS comunidade,
              pc.cidade, pc.estado
       FROM contratos c
       JOIN eventos e ON e.id = c.evento_id
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       WHERE c.banda_id = $1
         AND c.status_aceite = 'aceito'
         AND e.data_inicio >= NOW()
         AND e.status = 'agendado'
       ORDER BY e.data_inicio ASC`,
      [id]
    );

    // Mídias da banda
    const midiasRes = await pool.query(
      `SELECT id, tipo, url, titulo, ordem
       FROM perfil_midias
       WHERE dono_tipo = 'banda' AND dono_id = $1
       ORDER BY ordem ASC`,
      [id]
    );

    return res.json({
      ...bandaRes.rows[0],
      eventos: eventosRes.rows,
      midias: midiasRes.rows,
    });

  } catch (err) {
    console.error('Erro ao buscar banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/bandas/me/agenda
 * RF18 – Agenda de eventos contratados (somente banda autenticada)
 */
const agenda = async (req, res) => {
  const banda_id = req.usuario.id;

  try {
    const { rows } = await pool.query(
      `SELECT e.id, e.titulo, e.data_inicio, e.data_fim, e.local_nome,
              e.status AS status_evento, c.status_aceite,
              pc.nome_entidade AS comunidade, pc.whatsapp AS comunidade_whatsapp,
              pc.cidade, pc.estado
       FROM contratos c
       JOIN eventos e ON e.id = c.evento_id
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       WHERE c.banda_id = $1
       ORDER BY e.data_inicio ASC`,
      [banda_id]
    );
    return res.json(rows);

  } catch (err) {
    console.error('Erro ao buscar agenda da banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PUT /api/bandas/me/perfil
 * RF12, RF20 – Editar vitrine da banda (somente banda autenticada)
 */
const atualizarPerfil = async (req, res) => {
  const usuario_id = req.usuario.id;
  const { nome_artistico, estilo_musical, descricao, whatsapp, video_url } = req.body;

  // Validação de video_url se fornecida
  if (video_url && !/^https?:\/\//.test(video_url)) {
    return res.status(400).json({ error: 'video_url deve começar com http:// ou https://' });
  }

  try {
    await pool.query(
      `UPDATE perfis_bandas SET
         nome_artistico = COALESCE($1, nome_artistico),
         estilo_musical = COALESCE($2, estilo_musical),
         descricao      = COALESCE($3, descricao),
         whatsapp       = COALESCE($4, whatsapp),
         video_url      = COALESCE($5, video_url)
       WHERE usuario_id = $6`,
      [nome_artistico || null, estilo_musical || null, descricao || null,
       whatsapp || null, video_url || null, usuario_id]
    );
    return res.json({ message: 'Perfil atualizado com sucesso' });

  } catch (err) {
    console.error('Erro ao atualizar perfil da banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = { listar, buscarPorId, agenda, atualizarPerfil };