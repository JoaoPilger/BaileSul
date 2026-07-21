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
              pc.latitude, pc.longitude, pc.cnpj_validado, pc.foto_perfil_url
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
              pc.latitude, pc.longitude, pc.cnpj_validado, pc.foto_perfil_url
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
 * GET /api/comunidades/me/eventos
 * Lista todos os eventos da comunidade autenticada (gestão / Meus Eventos).
 */
const listarMeusEventos = async (req, res) => {
  const comunidade_id = req.usuario.id;

  try {
    const { rows } = await pool.query(
      `SELECT id, titulo, descricao, data_inicio, data_fim, local_nome,
              local_endereco, valor_ingresso, foto_capa_url, status,
              latitude, longitude
       FROM eventos
       WHERE comunidade_id = $1
       ORDER BY data_inicio DESC`,
      [comunidade_id]
    );

    return res.json({ eventos: rows });

  } catch (err) {
    console.error('Erro ao listar eventos da comunidade:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PUT /api/comunidades/me/perfil
 * RF12, RF20 – Editar vitrine da comunidade (somente comunidade autenticada)
 */
const atualizarPerfil = async (req, res) => {
  const usuario_id = req.usuario.id;
  const { nome_entidade, descricao, whatsapp, endereco, cidade, estado, latitude, longitude } = req.body;

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

    // Se o cliente enviou coordenadas manuais (pino ajustado no mapa), elas
    // têm prioridade sobre a geocodificação automática do endereço.
    const latManual = parseFloat(latitude);
    const lngManual = parseFloat(longitude);

    if (Number.isFinite(latManual) && Number.isFinite(lngManual)) {
      params.push(latManual, lngManual);
      coordsUpdate = `, latitude = $${params.length - 1}, longitude = $${params.length}`;
    } else if (endereco || cidade) {
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

const { caminhoParaUrl } = require('../middlewares/upload');

/**
 * POST /api/comunidades/me/foto-perfil
 * Define/substitui a foto de perfil (avatar) da comunidade.
 * O arquivo chega via multipart/form-data (campo "arquivo").
 */
const atualizarFotoPerfil = async (req, res) => {
  const usuario_id = req.usuario.id;

  if (!req.file) {
    return res.status(400).json({ error: 'Nenhum arquivo enviado. Selecione uma imagem.' });
  }

  if (req.file.mimetype.startsWith('video')) {
    return res.status(400).json({ error: 'Envie uma imagem para a foto de perfil.' });
  }

  const url = caminhoParaUrl(req.file.path, req);

  try {
    await pool.query(
      `UPDATE perfis_comunidades SET foto_perfil_url = $1 WHERE usuario_id = $2`,
      [url, usuario_id]
    );
    return res.json({ foto_perfil_url: url });
  } catch (err) {
    console.error('Erro ao atualizar foto de perfil da comunidade:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * POST /api/comunidades/me/midias
 * Adiciona imagem ou vídeo na galeria da comunidade.
 * O arquivo chega via multipart/form-data (campo "arquivo"), processado
 * pelo middleware midiaUploadSingle antes deste controller. O tipo
 * (imagem/video) é inferido automaticamente do mimetype do arquivo.
 */
const adicionarMidia = async (req, res) => {
  const comunidade_id = req.usuario.id;
  const { titulo } = req.body;

  if (!req.file) {
    return res.status(400).json({ error: 'Nenhum arquivo enviado. Selecione uma imagem ou vídeo.' });
  }

  const tipo = req.file.mimetype.startsWith('video') ? 'video' : 'imagem';
  const url = caminhoParaUrl(req.file.path, req);

  try {
    const { rows } = await pool.query(
      `INSERT INTO perfil_midias (dono_tipo, dono_id, tipo, url, titulo, ordem)
       VALUES ('comunidade', $1, $2, $3, $4, COALESCE((SELECT MAX(ordem)+1 FROM perfil_midias WHERE dono_tipo='comunidade' AND dono_id=$1), 1))
       RETURNING id, tipo, url, titulo, ordem`,
      [comunidade_id, tipo, url, titulo || null]
    );
    return res.status(201).json(rows[0]);
  } catch (err) {
    console.error('Erro ao adicionar mídia de comunidade:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * DELETE /api/comunidades/me/midias/:midia_id
 * Remove imagem ou video da galeria da comunidade
 */
const removerMidia = async (req, res) => {
  const comunidade_id = req.usuario.id;
  const { midia_id } = req.params;

  try {
    const { rowCount } = await pool.query(
      `DELETE FROM perfil_midias
       WHERE id = $1 AND dono_tipo = 'comunidade' AND dono_id = $2`,
      [midia_id, comunidade_id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ error: 'Mídia não encontrada ou não pertence a esta comunidade' });
    }

    return res.json({ message: 'Mídia removida com sucesso' });
  } catch (err) {
    console.error('Erro ao remover mídia de comunidade:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = { listar, buscarPorId, listarMeusEventos, atualizarPerfil, atualizarFotoPerfil, adicionarMidia, removerMidia };