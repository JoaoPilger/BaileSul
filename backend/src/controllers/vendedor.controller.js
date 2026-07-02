const pool = require('../config/database');
const { whatsappValido } = require('../utils/validators');

/**
 * GET /api/vendedores
 * RF08 – Listar vendedores da comunidade autenticada
 */
const listar = async (req, res) => {
  const comunidade_id = req.usuario.id;

  try {
    const { rows } = await pool.query(
      `SELECT v.id, v.nome, v.whatsapp, v.ativo, v.criado_em,
              v.usuario_id,
              pp.nome AS usuario_nome,
              u.email AS usuario_email,
              COALESCE(SUM(CASE WHEN r.status_pagamento = 'confirmado' THEN r.quantidade * COALESCE(e.valor_ingresso, 0) ELSE 0 END), 0)::FLOAT AS vendas_totais
       FROM vendedores v
       LEFT JOIN perfis_pessoais pp ON pp.usuario_id = v.usuario_id
       LEFT JOIN usuarios u ON u.id = v.usuario_id
       LEFT JOIN reservas r ON r.vendedor_id = v.id
       LEFT JOIN eventos e ON e.id = r.evento_id
       WHERE v.comunidade_id = $1 AND v.ativo = true
       GROUP BY v.id, pp.nome, u.email
       ORDER BY v.nome ASC`,
      [comunidade_id]
    );
    return res.json(rows);

  } catch (err) {
    console.error('Erro ao listar vendedores:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * POST /api/vendedores
 * RF08 – Adicionar ou Reativar vendedor na comunidade via Email.
 */
const adicionar = async (req, res) => {
  const comunidade_id = req.usuario.id;
  const { email, whatsapp } = req.body;

  if (!email || !whatsapp) {
    return res.status(400).json({ error: 'Campos obrigatórios: email, whatsapp' });
  }

  if (!whatsappValido(whatsapp)) {
    return res.status(400).json({
      error: 'WhatsApp inválido. Use 10 a 15 dígitos (ex.: 5547999999999)',
    });
  }

  try {
    // 1. Busca o usuário do tipo pessoal utilizando o e-mail informado
    const usuarioRes = await pool.query(
      `SELECT u.id, u.tipo, pp.nome AS nome_perfil
       FROM usuarios u
       LEFT JOIN perfis_pessoais pp ON pp.usuario_id = u.id
       WHERE LOWER(u.email) = LOWER($1)`,
      [email.trim()]
    );

    if (usuarioRes.rows.length === 0) {
      return res.status(404).json({ error: 'Nenhum usuário pessoal encontrado com esse e-mail.' });
    }

    if (usuarioRes.rows[0].tipo !== 'pessoal') {
      return res.status(400).json({ error: 'Apenas usuários do tipo pessoal podem ser vendedores.' });
    }

    const usuario_id = usuarioRes.rows[0].id;
    const nomeFinal = usuarioRes.rows[0].nome_perfil || 'Usuário Sem Nome';
    const whatsappFinal = whatsapp.replace(/\D/g, '');

    // 2. Executa o INSERT com a cláusula ON CONFLICT
    // IMPORTANTE: Assume que sua constraint de unicidade é nas colunas (comunidade_id, usuario_id)
    const { rows } = await pool.query(
      `INSERT INTO vendedores (comunidade_id, usuario_id, nome, whatsapp, ativo)
       VALUES ($1, $2, $3, $4, true)
       ON CONFLICT ON CONSTRAINT uq_vendedor_usuario_comunidade 
       DO UPDATE SET 
          ativo = true, 
          nome = EXCLUDED.nome, 
          whatsapp = EXCLUDED.whatsapp
       RETURNING id, nome, whatsapp, ativo, usuario_id`,
      [comunidade_id, usuario_id, nomeFinal.trim(), whatsappFinal]
    );

    return res.status(200).json({ message: 'Vendedor adicionado ou reativado com sucesso', vendedor: rows[0] });

  } catch (err) {
    console.error('Erro ao adicionar vendedor:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * DELETE /api/vendedores/:id
 * RF08 – Desativar vendedor (soft delete via ativo = false)
 */
const remover = async (req, res) => {
  const { id } = req.params;
  const comunidade_id = req.usuario.id;

  try {
    const result = await pool.query(
      `UPDATE vendedores SET ativo = false
       WHERE id = $1 AND comunidade_id = $2
       RETURNING id`,
      [id, comunidade_id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Vendedor não encontrado ou sem permissão' });
    }
    return res.json({ message: 'Vendedor desativado com sucesso' });

  } catch (err) {
    console.error('Erro ao remover vendedor:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PATCH /api/vendedores/reservas/:reserva_id/confirmar
 */
const confirmarPagamento = async (req, res) => {
  const { reserva_id } = req.params;
  const { id: usuario_id, tipo: usuario_tipo } = req.usuario;

  try {
    const reservaRes = await pool.query(
      `SELECT r.id, r.vendedor_id, r.status_pagamento,
              e.comunidade_id,
              v.usuario_id AS vendedor_usuario_id
       FROM reservas r
       JOIN eventos e ON e.id = r.evento_id
       LEFT JOIN vendedores v ON v.id = r.vendedor_id
       WHERE r.id = $1`,
      [reserva_id]
    );

    if (reservaRes.rows.length === 0) {
      return res.status(404).json({ error: 'Reserva não encontrada' });
    }

    const reserva = reservaRes.rows[0];

    if (reserva.status_pagamento !== 'pendente') {
      return res.status(409).json({ error: 'Reserva já confirmada ou cancelada' });
    }

    if (usuario_tipo === 'comunidade') {
      if (reserva.comunidade_id !== usuario_id) {
        return res.status(403).json({ error: 'Acesso não autorizado para este evento' });
      }
    } else if (usuario_tipo === 'pessoal') {
      if (!reserva.vendedor_usuario_id || reserva.vendedor_usuario_id !== usuario_id) {
        return res.status(403).json({ error: 'Você não é o vendedor responsável por esta reserva' });
      }
    } else {
      return res.status(403).json({ error: 'Acesso não autorizado para este perfil' });
    }

    await pool.query(
      `UPDATE reservas
       SET status_pagamento = 'confirmado'
       WHERE id = $1`,
      [reserva_id]
    );

    await pool.query(
      `INSERT INTO logs_status_pagamentos (reserva_id, status_anterior, status_novo, usuario_id)
       VALUES ($1, 'pendente', 'confirmado', $2)`,
      [reserva_id, usuario_id]
    );

    return res.json({ message: 'Pagamento confirmado com sucesso' });

  } catch (err) {
    console.error('Erro ao confirmar pagamento:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/vendedores/sugestoes?email=...
 */
const buscarSugestoes = async (req, res) => {
  const { email } = req.query;

  if (!email || !email.trim()) {
    return res.json([]);
  }

  try {
    const { rows } = await pool.query(
      `SELECT u.id, pp.nome, u.email
       FROM usuarios u
       INNER JOIN perfis_pessoais pp ON pp.usuario_id = u.id
       WHERE u.tipo = 'pessoal'
         AND LOWER(u.email) = LOWER($1)
       LIMIT 1`,
      [email.trim()]
    );

    return res.json(rows);

  } catch (err) {
    console.error('Erro ao buscar usuário por email:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/vendedores/me
 * RF08 – Lista as comunidades às quais o usuário 'pessoal' logado
 * está vinculado como vendedor ativo. Usado pelo front para decidir
 * se exibe o card "Comunidades vinculadas" em Configurações.
 */
const minhasComunidades = async (req, res) => {
  const { id: usuario_id, tipo: usuario_tipo } = req.usuario;

  if (usuario_tipo !== 'pessoal') {
    return res.json([]);
  }

  try {
    const { rows } = await pool.query(
      `SELECT v.id AS vendedor_id, v.comunidade_id, v.nome, v.whatsapp, v.criado_em,
              pc.nome_entidade AS comunidade_nome
       FROM vendedores v
       LEFT JOIN perfis_comunidades pc ON pc.usuario_id = v.comunidade_id
       WHERE v.usuario_id = $1 AND v.ativo = true
       ORDER BY pc.nome_entidade ASC`,
      [usuario_id]
    );
    return res.json(rows);

  } catch (err) {
    console.error('Erro ao buscar comunidades vinculadas:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = { listar, adicionar, remover, confirmarPagamento, buscarSugestoes, minhasComunidades };