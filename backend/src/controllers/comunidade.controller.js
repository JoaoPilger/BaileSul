const pool = require('../config/database');
const { geocodificarEndereco } = require('../services/external.service');
const { parsePaginacao, respostaPaginada } = require('../utils/pagination');
const { whatsappValido } = require('../utils/validators');

/**
 * GET /api/comunidades
 * RF15 – Listar comunidades publicamente
 */
const listar = async (req, res) => {
  const { cidade, estado } = req.query;
  const { pagina, limite, offset } = parsePaginacao(req.query);

  try {
    let where = 'WHERE 1=1';
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

    const countRes = await pool.query(
      `SELECT COUNT(*)::int AS total FROM perfis_comunidades pc ${where}`,
      params
    );
    const total = countRes.rows[0].total;

    const { rows } = await pool.query(
      `SELECT pc.usuario_id, pc.nome_entidade, pc.descricao,
              pc.whatsapp, pc.cidade, pc.estado, pc.endereco,
              pc.latitude, pc.longitude, pc.cnpj_validado
       FROM perfis_comunidades pc
       ${where}
       ORDER BY pc.nome_entidade ASC
       LIMIT $${i++} OFFSET $${i++}`,
      [...params, limite, offset]
    );

    return res.json(respostaPaginada(rows, pagina, limite, total));

  } catch (err) {
    console.error('Erro ao listar comunidades:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/comunidades/:id
 * RF15 – Perfil público da comunidade com eventos ativos
 */
const buscarPorId = async (req, res) => {
  const { id } = req.params;

  try {
    const comRes = await pool.query(
      `SELECT pc.usuario_id, pc.nome_entidade, pc.descricao,
              pc.whatsapp, pc.cidade, pc.estado, pc.endereco,
              pc.latitude, pc.longitude, pc.cnpj_validado
       FROM perfis_comunidades pc
       WHERE pc.usuario_id = $1`,
      [id]
    );
    if (comRes.rows.length === 0) {
      return res.status(404).json({ error: 'Comunidade não encontrada' });
    }

    const eventosRes = await pool.query(
      `SELECT id, titulo, data_inicio, data_fim, local_nome,
              valor_ingresso, foto_capa_url, status,
              latitude, longitude
       FROM eventos
       WHERE comunidade_id = $1
         AND status = 'agendado'
         AND data_inicio >= NOW()
       ORDER BY data_inicio ASC`,
      [id]
    );

    const midiasRes = await pool.query(
      `SELECT id, tipo, url, titulo, ordem
       FROM perfil_midias
       WHERE dono_tipo = 'comunidade' AND dono_id = $1
       ORDER BY ordem ASC`,
      [id]
    );

    return res.json({
      ...comRes.rows[0],
      eventos: eventosRes.rows,
      midias: midiasRes.rows,
    });

  } catch (err) {
    console.error('Erro ao buscar comunidade:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PUT /api/comunidades/me/perfil
 * RF12, RF20 – Editar vitrine da comunidade (somente comunidade autenticada)
 */
const atualizarPerfil = async (req, res) => {
  const usuario_id = req.usuario.id;
  const { nome_entidade, descricao, whatsapp, endereco, cidade, estado } = req.body;

  if (whatsapp && !whatsappValido(whatsapp)) {
    return res.status(400).json({
      error: 'WhatsApp inválido. Use 10 a 15 dígitos (ex.: 5547999999999)',
    });
  }

  try {
    const params = [
      nome_entidade || null,
      descricao || null,
      whatsapp || null,
      endereco || null,
      cidade || null,
      estado || null,
    ];
    let coordsUpdate = '';

    if (endereco || cidade) {
      const endGeo = [endereco, cidade, estado, 'Brasil'].filter(Boolean).join(', ');
      const coords = await geocodificarEndereco(endGeo);
      if (coords?.latitude && coords?.longitude) {
        params.push(coords.latitude, coords.longitude);
        coordsUpdate = `, latitude = $${params.length - 1}, longitude = $${params.length}`;
      }
    }

    params.push(usuario_id);
    const whereIdx = params.length;

    await pool.query(
      `UPDATE perfis_comunidades SET
         nome_entidade = COALESCE($1, nome_entidade),
         descricao     = COALESCE($2, descricao),
         whatsapp      = COALESCE($3, whatsapp),
         endereco      = COALESCE($4, endereco),
         cidade        = COALESCE($5, cidade),
         estado        = COALESCE($6, estado)
         ${coordsUpdate}
       WHERE usuario_id = $${whereIdx}`,
      params
    );
    return res.json({ message: 'Perfil atualizado com sucesso' });

  } catch (err) {
    console.error('Erro ao atualizar perfil da comunidade:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = { listar, buscarPorId, atualizarPerfil };
