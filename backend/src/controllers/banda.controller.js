const pool = require('../config/database');
const { parsePaginacao, respostaPaginada } = require('../utils/pagination');
const { whatsappValido, urlHttpValida } = require('../utils/validators');

/**
 * GET /api/bandas
 * RF10, RF15 – Listar bandas públicas com filtro opcional: ?estilo=&cidade=
 */
const listar = async (req, res) => {
  const { estilo, cidade } = req.query;
  const { pagina, limite, offset } = parsePaginacao(req.query);

  try {
    let where = 'WHERE 1=1';
    const params = [];
    let i = 1;

    if (estilo) {
      where += ` AND LOWER(pb.estilo_musical) LIKE LOWER($${i++})`;
      params.push(`%${estilo}%`);
    }

    if (cidade) {
      where += `
        AND pb.usuario_id IN (
          SELECT c.banda_id
          FROM contratos c
          JOIN eventos e ON e.id = c.evento_id
          JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
          WHERE c.status_aceite = 'aceito'
            AND e.status = 'agendado'
            AND LOWER(pc.cidade) LIKE LOWER($${i++})
        )
      `;
      params.push(`%${cidade}%`);
    }

    const countRes = await pool.query(
      `SELECT COUNT(DISTINCT pb.usuario_id)::int AS total
       FROM perfis_bandas pb
       JOIN usuarios u ON u.id = pb.usuario_id
       ${where}`,
      params
    );
    const total = countRes.rows[0].total;

    const { rows } = await pool.query(
      `SELECT DISTINCT pb.usuario_id, pb.nome_artistico, pb.estilo_musical,
             pb.descricao, pb.whatsapp, pb.cnpj_validado, pb.foto_perfil_url
       FROM perfis_bandas pb
       JOIN usuarios u ON u.id = pb.usuario_id
       ${where}
       ORDER BY pb.nome_artistico ASC
       LIMIT $${i++} OFFSET $${i++}`,
      [...params, limite, offset]
    );

    return res.json(respostaPaginada(rows, pagina, limite, total));

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
              pb.descricao, pb.whatsapp, pb.video_url, pb.cnpj_validado, pb.foto_perfil_url
       FROM perfis_bandas pb
       WHERE pb.usuario_id = $1`,
      [id]
    );
    if (bandaRes.rows.length === 0) {
      return res.status(404).json({ error: 'Banda não encontrada' });
    }

    // data_inicio é DATE (sem hora). Comparar com NOW() força um cast pra
    // timestamp de hoje às 00:00, o que excluía eventos do próprio dia assim
    // que passava da meia-noite. CURRENT_DATE compara data com data.
    const eventosRes = await pool.query(
      `SELECT e.id, e.titulo, e.data_inicio, e.data_fim, e.status,
              e.local_nome, e.foto_capa_url, pc.nome_entidade AS comunidade,
              pc.cidade, pc.estado
       FROM contratos c
       JOIN eventos e ON e.id = c.evento_id
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       WHERE c.banda_id = $1
         AND c.status_aceite = 'aceito'
         AND e.data_inicio >= CURRENT_DATE
         AND e.status = 'agendado'
       ORDER BY e.data_inicio ASC`,
      [id]
    );

    const midiasRes = await pool.query(
      `SELECT id, tipo, url, titulo, ordem
       FROM perfil_midias
       WHERE dono_tipo = 'banda' AND dono_id = $1
       ORDER BY ordem ASC`,
      [id]
    );

    const statsRes = await pool.query(
      `SELECT
         (SELECT COUNT(*)::int FROM perfil_seguidores WHERE dono_tipo = 'banda' AND dono_id = $1) AS seguidores,
         (SELECT ROUND(AVG(nota)::numeric, 1)::float FROM perfil_avaliacoes WHERE dono_tipo = 'banda' AND dono_id = $1) AS media_avaliacao,
         (SELECT COUNT(*)::int FROM perfil_avaliacoes WHERE dono_tipo = 'banda' AND dono_id = $1) AS total_avaliacoes`,
      [id]
    );

    let seguindo = false;
    let minha_avaliacao = null;
    if (req.usuario) {
      const pessoalRes = await pool.query(
        `SELECT
           EXISTS(SELECT 1 FROM perfil_seguidores WHERE usuario_id = $1 AND dono_tipo = 'banda' AND dono_id = $2) AS seguindo,
           (SELECT nota FROM perfil_avaliacoes WHERE usuario_id = $1 AND dono_tipo = 'banda' AND dono_id = $2) AS nota`,
        [req.usuario.id, id]
      );
      seguindo = pessoalRes.rows[0].seguindo;
      minha_avaliacao = pessoalRes.rows[0].nota;
    }

    return res.json({
      ...bandaRes.rows[0],
      eventos: eventosRes.rows,
      midias: midiasRes.rows,
      seguidores: statsRes.rows[0].seguidores,
      media_avaliacao: statsRes.rows[0].media_avaliacao,
      total_avaliacoes: statsRes.rows[0].total_avaliacoes,
      seguindo,
      minha_avaliacao,
    });

  } catch (err) {
    console.error('Erro ao buscar banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * POST /api/bandas/:id/seguir
 */
const seguir = async (req, res) => {
  const { id } = req.params;
  const usuario_id = req.usuario.id;

  if (Number(id) === usuario_id) {
    return res.status(400).json({ error: 'Você não pode seguir seu próprio perfil' });
  }

  try {
    const bandaRes = await pool.query('SELECT usuario_id FROM perfis_bandas WHERE usuario_id = $1', [id]);
    if (bandaRes.rows.length === 0) {
      return res.status(404).json({ error: 'Banda não encontrada' });
    }

    await pool.query(
      `INSERT INTO perfil_seguidores (usuario_id, dono_tipo, dono_id)
       VALUES ($1, 'banda', $2)
       ON CONFLICT (usuario_id, dono_tipo, dono_id) DO NOTHING`,
      [usuario_id, id]
    );
    return res.status(201).json({ seguindo: true });

  } catch (err) {
    console.error('Erro ao seguir banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * DELETE /api/bandas/:id/seguir
 */
const deixarDeSeguir = async (req, res) => {
  const { id } = req.params;
  const usuario_id = req.usuario.id;

  try {
    await pool.query(
      `DELETE FROM perfil_seguidores WHERE usuario_id = $1 AND dono_tipo = 'banda' AND dono_id = $2`,
      [usuario_id, id]
    );
    return res.json({ seguindo: false });

  } catch (err) {
    console.error('Erro ao deixar de seguir banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PUT /api/bandas/:id/avaliar
 * Cria ou atualiza a nota (1 a 5) do usuário autenticado para a banda.
 */
const avaliar = async (req, res) => {
  const { id } = req.params;
  const usuario_id = req.usuario.id;
  const nota = parseInt(req.body.nota, 10);

  if (Number(id) === usuario_id) {
    return res.status(400).json({ error: 'Você não pode avaliar seu próprio perfil' });
  }

  if (isNaN(nota) || nota < 1 || nota > 5) {
    return res.status(400).json({ error: 'Nota deve ser um número inteiro entre 1 e 5' });
  }

  try {
    const bandaRes = await pool.query('SELECT usuario_id FROM perfis_bandas WHERE usuario_id = $1', [id]);
    if (bandaRes.rows.length === 0) {
      return res.status(404).json({ error: 'Banda não encontrada' });
    }

    await pool.query(
      `INSERT INTO perfil_avaliacoes (usuario_id, dono_tipo, dono_id, nota)
       VALUES ($1, 'banda', $2, $3)
       ON CONFLICT (usuario_id, dono_tipo, dono_id) DO UPDATE SET nota = EXCLUDED.nota`,
      [usuario_id, id, nota]
    );

    const mediaRes = await pool.query(
      `SELECT ROUND(AVG(nota)::numeric, 1)::float AS media, COUNT(*)::int AS total
       FROM perfil_avaliacoes WHERE dono_tipo = 'banda' AND dono_id = $1`,
      [id]
    );

    return res.json({
      minha_avaliacao: nota,
      media_avaliacao: mediaRes.rows[0].media,
      total_avaliacoes: mediaRes.rows[0].total,
    });

  } catch (err) {
    console.error('Erro ao avaliar banda:', err.message);
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
      `SELECT c.id AS contrato_id,
              e.id, e.titulo, e.data_inicio, e.data_fim, e.local_nome,
              e.status AS status_evento, c.status_aceite,
              pc.nome_entidade AS comunidade, pc.whatsapp AS comunidade_whatsapp,
              pc.cidade, pc.estado,
              (SELECT COALESCE(SUM(r.quantidade), 0)
                 FROM reservas r
                WHERE r.evento_id = e.id
                  AND r.status_pagamento = 'confirmado')::int AS confirmados
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

  if (whatsapp && !whatsappValido(whatsapp)) {
    return res.status(400).json({
      error: 'WhatsApp inválido. Use 10 a 15 dígitos (ex.: 5547999999999)',
    });
  }

  if (video_url && !urlHttpValida(video_url)) {
    return res.status(400).json({
      error: 'video_url deve ser uma URL http(s) válida com domínio completo',
    });
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

/**
 * GET /api/bandas/sugestoes?nome=...
 * Autocomplete para o formulário de criar evento: retorna até 5 bandas
 * cujo nome_artistico é parecido com o texto digitado.
 */
const buscarSugestoes = async (req, res) => {
  const { nome } = req.query;

  if (!nome || !nome.trim()) {
    return res.json([]);
  }

  try {
    const { rows } = await pool.query(
      `SELECT pb.usuario_id, pb.nome_artistico, pb.estilo_musical
       FROM perfis_bandas pb
       WHERE LOWER(pb.nome_artistico) LIKE LOWER($1)
       ORDER BY pb.nome_artistico ASC
       LIMIT 5`,
      [`%${nome.trim()}%`]
    );

    return res.json(rows);

  } catch (err) {
    console.error('Erro ao buscar sugestões de banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

const { caminhoParaUrl } = require('../middlewares/upload');

/**
 * POST /api/bandas/me/foto-perfil
 * Define/substitui a foto de perfil (avatar) da banda.
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
      `UPDATE perfis_bandas SET foto_perfil_url = $1 WHERE usuario_id = $2`,
      [url, usuario_id]
    );
    return res.json({ foto_perfil_url: url });
  } catch (err) {
    console.error('Erro ao atualizar foto de perfil da banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * POST /api/bandas/me/midias
 * Adiciona imagem ou vídeo na galeria da banda.
 * O arquivo chega via multipart/form-data (campo "arquivo"), processado
 * pelo middleware midiaUploadSingle antes deste controller. O tipo
 * (imagem/video) é inferido automaticamente do mimetype do arquivo.
 */
const adicionarMidia = async (req, res) => {
  const banda_id = req.usuario.id;
  const { titulo } = req.body;

  if (!req.file) {
    return res.status(400).json({ error: 'Nenhum arquivo enviado. Selecione uma imagem ou vídeo.' });
  }

  const tipo = req.file.mimetype.startsWith('video') ? 'video' : 'imagem';
  const url = caminhoParaUrl(req.file.path, req);

  try {
    const { rows } = await pool.query(
      `INSERT INTO perfil_midias (dono_tipo, dono_id, tipo, url, titulo, ordem)
       VALUES ('banda', $1, $2, $3, $4, COALESCE((SELECT MAX(ordem)+1 FROM perfil_midias WHERE dono_tipo='banda' AND dono_id=$1), 1))
       RETURNING id, tipo, url, titulo, ordem`,
      [banda_id, tipo, url, titulo || null]
    );
    return res.status(201).json(rows[0]);
  } catch (err) {
    console.error('Erro ao adicionar mídia de banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * DELETE /api/bandas/me/midias/:midia_id
 * Remove imagem ou video da galeria da banda
 */
const removerMidia = async (req, res) => {
  const banda_id = req.usuario.id;
  const { midia_id } = req.params;

  try {
    const { rowCount } = await pool.query(
      `DELETE FROM perfil_midias
       WHERE id = $1 AND dono_tipo = 'banda' AND dono_id = $2`,
      [midia_id, banda_id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ error: 'Mídia não encontrada ou não pertence a esta banda' });
    }

    return res.json({ message: 'Mídia removida com sucesso' });
  } catch (err) {
    console.error('Erro ao remover mídia de banda:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = {
  listar, buscarPorId, agenda, atualizarPerfil, atualizarFotoPerfil, buscarSugestoes,
  adicionarMidia, removerMidia, seguir, deixarDeSeguir, avaliar,
};