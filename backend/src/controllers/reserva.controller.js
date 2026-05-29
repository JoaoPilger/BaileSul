const pool = require('../config/database');

const QUANTIDADE_MAX = 10; // limite por reserva
const RESERVAS_MAX_POR_USUARIO_EVENTO = 1; // um usuário, uma reserva por evento

/**
 * POST /api/eventos/:id/reserva
 * RF11 – Usuário pessoal reserva ingresso e recebe contato do vendedor via wa.me
 */
const criar = async (req, res) => {
  const evento_id = req.params.evento_id;
  const comprador_id = req.usuario.id;
  const quantidade = parseInt(req.body.quantidade, 10);

  if (isNaN(quantidade) || quantidade < 1 || quantidade > QUANTIDADE_MAX) {
    return res.status(400).json({
      error: `Quantidade deve ser um número entre 1 e ${QUANTIDADE_MAX}`,
    });
  }

  try {
    // Verificar se evento existe e está agendado
    const eventoRes = await pool.query(
      "SELECT id, comunidade_id, titulo FROM eventos WHERE id = $1 AND status = 'agendado'",
      [evento_id]
    );
    if (eventoRes.rows.length === 0) {
      return res.status(404).json({ error: 'Evento não encontrado ou não está disponível' });
    }

    const { comunidade_id, titulo } = eventoRes.rows[0];

    // Anti-duplicata: usuário já tem reserva pendente/confirmada para este evento?
    const duplicataRes = await pool.query(
      `SELECT id FROM reservas
       WHERE comprador_id = $1 AND evento_id = $2
         AND status_pagamento IN ('pendente', 'confirmado')`,
      [comprador_id, evento_id]
    );
    if (duplicataRes.rows.length >= RESERVAS_MAX_POR_USUARIO_EVENTO) {
      return res.status(409).json({
        error: 'Você já possui uma reserva ativa para este evento',
      });
    }

    // Round-robin real: vendedor com menor número de reservas pendentes
    const vendedorRes = await pool.query(
      `SELECT v.id, v.nome, v.whatsapp
       FROM vendedores v
       LEFT JOIN reservas r ON r.vendedor_id = v.id
         AND r.status_pagamento = 'pendente'
       WHERE v.comunidade_id = $1 AND v.ativo = true
       GROUP BY v.id, v.nome, v.whatsapp
       ORDER BY COUNT(r.id) ASC, v.id ASC
       LIMIT 1`,
      [comunidade_id]
    );
    if (vendedorRes.rows.length === 0) {
      return res.status(422).json({
        error: 'Nenhum vendedor disponível para este evento no momento',
      });
    }

    const vendedor = vendedorRes.rows[0];

    // INSERT reserva
    const reservaRes = await pool.query(
      `INSERT INTO reservas (evento_id, comprador_id, vendedor_id, quantidade)
       VALUES ($1, $2, $3, $4)
       RETURNING id`,
      [evento_id, comprador_id, vendedor.id, quantidade]
    );

    const reserva_id = reservaRes.rows[0].id;

    // Montar link wa.me
    const mensagem = encodeURIComponent(
      `Olá! Quero confirmar minha reserva:\n` +
      `📅 Evento: ${titulo}\n` +
      `🎟️ Quantidade: ${quantidade} ingresso(s)\n` +
      `🔑 Reserva ID: #${reserva_id}`
    );
    const whatsapp_link = `https://wa.me/${vendedor.whatsapp.replace(/\D/g, '')}?text=${mensagem}`;

    return res.status(201).json({
      message: 'Reserva criada! Entre em contato com o vendedor para confirmar o pagamento.',
      reserva_id,
      vendedor: {
        nome: vendedor.nome,
        whatsapp: vendedor.whatsapp,
        whatsapp_link,
      },
    });

  } catch (err) {
    console.error('Erro ao criar reserva:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/reservas/minhas
 * RF11 – Listar reservas do usuário pessoal autenticado
 */
const minhasReservas = async (req, res) => {
  const comprador_id = req.usuario.id;

  try {
    const { rows } = await pool.query(
      `SELECT r.id, r.quantidade, r.status_pagamento, r.criado_em,
              e.titulo AS evento, e.data_inicio, e.local_nome,
              v.nome AS vendedor_nome, v.whatsapp AS vendedor_whatsapp
       FROM reservas r
       JOIN eventos e ON e.id = r.evento_id
       LEFT JOIN vendedores v ON v.id = r.vendedor_id
       WHERE r.comprador_id = $1
       ORDER BY r.criado_em DESC`,
      [comprador_id]
    );
    return res.json(rows);

  } catch (err) {
    console.error('Erro ao buscar reservas:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = { criar, minhasReservas };