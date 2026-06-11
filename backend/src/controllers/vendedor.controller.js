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
              pp.nome AS usuario_nome
       FROM vendedores v
       LEFT JOIN perfis_pessoais pp ON pp.usuario_id = v.usuario_id
       WHERE v.comunidade_id = $1
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
 * RF08 – Adicionar vendedor à comunidade.
 *
 * Dois modos:
 *   A) Cadastro simples: apenas nome + whatsapp (sem conta na plataforma).
 *   B) Vinculação: fornece usuario_id de um usuário tipo 'pessoal' existente.
 *      Nesse caso, o sistema valida que o usuário existe e é do tipo pessoal.
 */
const adicionar = async (req, res) => {
  const comunidade_id = req.usuario.id;
  const { nome, whatsapp, usuario_id } = req.body;

  if (!nome || !whatsapp) {
    return res.status(400).json({ error: 'Campos obrigatórios: nome, whatsapp' });
  }

  if (!whatsappValido(whatsapp)) {
    return res.status(400).json({
      error: 'WhatsApp inválido. Use 10 a 15 dígitos (ex.: 5547999999999)',
    });
  }

  try {
    // Se usuario_id foi fornecido, valida que existe e é pessoal
    if (usuario_id) {
      const usuarioRes = await pool.query(
        "SELECT id, tipo FROM usuarios WHERE id = $1",
        [usuario_id]
      );
      if (usuarioRes.rows.length === 0) {
        return res.status(404).json({ error: 'Usuário não encontrado' });
      }
      if (usuarioRes.rows[0].tipo !== 'pessoal') {
        return res.status(400).json({ error: 'Apenas usuários do tipo pessoal podem ser vendedores' });
      }
    }

    const { rows } = await pool.query(
      `INSERT INTO vendedores (comunidade_id, usuario_id, nome, whatsapp)
       VALUES ($1, $2, $3, $4)
       RETURNING id, nome, whatsapp, ativo, usuario_id`,
      [comunidade_id, usuario_id || null, nome.trim(), whatsapp]
    );
    return res.status(201).json({ message: 'Vendedor adicionado', vendedor: rows[0] });

  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Este usuário já é vendedor desta comunidade' });
    }
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
 * RF13 – Confirmar pagamento de ingresso manualmente.
 *
 * Quem pode confirmar:
 *   1. A própria comunidade dona do evento (autorizar('comunidade'))
 *   2. O usuário pessoal que está vinculado como vendedor da reserva
 *      (autenticado como 'pessoal' e sendo o vendedor_id da reserva)
 *
 * A rota aceita ambos os casos; o middleware de autorização permite
 * comunidade OU pessoal. A lógica aqui restringe o pessoal ao
 * vendedor vinculado.
 */
const confirmarPagamento = async (req, res) => {
  const { reserva_id } = req.params;
  const { id: usuario_id, tipo: usuario_tipo } = req.usuario;

  try {
    // Busca a reserva com dados do evento e do vendedor vinculado
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

    // Verificar permissão:
    // - comunidade: deve ser a dona do evento
    // - pessoal: deve ser o usuario_id vinculado ao vendedor da reserva
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

    // Confirmar pagamento
    await pool.query(
      `UPDATE reservas
       SET status_pagamento = 'confirmado'
       WHERE id = $1`,
      [reserva_id]
    );

    // Log de auditoria
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

module.exports = { listar, adicionar, remover, confirmarPagamento };