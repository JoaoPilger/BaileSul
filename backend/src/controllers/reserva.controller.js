const pool = require('../config/database');
const { criarNotificacao } = require('../services/notificacao.service');

const QUANTIDADE_MAX = 10; // limite por reserva
const RESERVAS_MAX_POR_USUARIO_EVENTO = 1; // um usuário, uma reserva por evento

/**
 * POST /api/eventos/:id/reserva
 * RF11 – Usuário pessoal reserva ingresso e recebe contato do vendedor via wa.me
 */
const criar = async (req, res) => {
  const evento_id = req.params.evento_id ?? req.params.id;
  const comprador_id = req.usuario.id;
  const quantidade = parseInt(req.body.quantidade, 10);
  const forma_pagamento = ['presencial', 'whatsapp'].includes(req.body.forma_pagamento)
    ? req.body.forma_pagamento
    : 'presencial';
  const nome_retirada = typeof req.body.nome_retirada === 'string'
    ? req.body.nome_retirada.trim().slice(0, 120)
    : null;

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

    // Sorteia aleatoriamente um vendedor ativo da comunidade para confirmar o pagamento
    const vendedorRes = await pool.query(
      `SELECT v.id, v.nome, v.whatsapp
       FROM vendedores v
       WHERE v.comunidade_id = $1 AND v.ativo = true
       ORDER BY RANDOM()
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
      `INSERT INTO reservas (evento_id, comprador_id, vendedor_id, quantidade, forma_pagamento, nome_retirada)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id`,
      [evento_id, comprador_id, vendedor.id, quantidade, forma_pagamento, nome_retirada || null]
    );

    const reserva_id = reservaRes.rows[0].id;

    const formaPagLabel = forma_pagamento === 'whatsapp' ? 'Via WhatsApp' : 'Presencial';
    const mensagem = encodeURIComponent(
      `Olá! Quero confirmar minha reserva:\n` +
      `📅 Evento: ${titulo}\n` +
      `🎟️ Quantidade: ${quantidade} ingresso(s)\n` +
      `💳 Pagamento: ${formaPagLabel}\n` +
      (nome_retirada ? `👤 Nome retirada: ${nome_retirada}\n` : '') +
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
  const { status, tipo_evento, busca } = req.query;

  const statusValidos = ['pendente', 'confirmado', 'cancelado'];
  if (status && !statusValidos.includes(status)) {
    return res.status(400).json({ error: `status inválido. Use: ${statusValidos.join(', ')}` });
  }

  try {
    let where = 'WHERE r.comprador_id = $1';
    const params = [comprador_id];
    let i = 2;

    if (status) {
      where += ` AND r.status_pagamento = $${i++}`;
      params.push(status);
    }
    if (tipo_evento) {
      where += ` AND e.tipo_evento = $${i++}`;
      params.push(tipo_evento);
    }
    if (busca) {
      where += ` AND (LOWER(e.titulo) LIKE LOWER($${i}) OR CAST(e.data_inicio AS TEXT) LIKE $${i})`;
      params.push(`%${busca}%`);
      i++;
    }

    const { rows } = await pool.query(
      `SELECT r.id, r.quantidade, r.status_pagamento, r.criado_em,
              e.id AS evento_id, e.titulo AS evento, e.data_inicio, e.data_fim,
              e.local_nome, e.foto_capa_url, e.tipo_evento, e.valor_ingresso,
              pc.nome_entidade AS comunidade, pc.cidade, pc.estado,
              pb.nome_artistico AS banda,
              v.nome AS vendedor_nome, v.whatsapp AS vendedor_whatsapp
       FROM reservas r
       JOIN eventos e ON e.id = r.evento_id
       JOIN perfis_comunidades pc ON pc.usuario_id = e.comunidade_id
       LEFT JOIN vendedores v ON v.id = r.vendedor_id
       LEFT JOIN LATERAL (
         SELECT pb.nome_artistico
         FROM contratos c
         JOIN perfis_bandas pb ON pb.usuario_id = c.banda_id
         WHERE c.evento_id = e.id AND c.status_aceite = 'aceito'
         LIMIT 1
       ) pb ON true
       ${where}
       ORDER BY r.criado_em DESC`,
      params
    );
    return res.json(rows);

  } catch (err) {
    console.error('Erro ao buscar reservas:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PATCH /api/reservas/:reserva_id/cancelar
 * Cancelamento pelo próprio comprador, somente enquanto a reserva
 * ainda está pendente de confirmação do vendedor.
 */
const cancelar = async (req, res) => {
  const { reserva_id } = req.params;
  const comprador_id = req.usuario.id;

  try {
    const reservaRes = await pool.query(
      `SELECT r.id, r.status_pagamento, r.comprador_id,
              v.usuario_id AS vendedor_usuario_id,
              e.titulo AS evento_titulo, e.id AS evento_id
       FROM reservas r
       LEFT JOIN vendedores v ON v.id = r.vendedor_id
       JOIN eventos e ON e.id = r.evento_id
       WHERE r.id = $1`,
      [reserva_id]
    );

    if (reservaRes.rows.length === 0) {
      return res.status(404).json({ error: 'Reserva não encontrada' });
    }

    const reserva = reservaRes.rows[0];

    if (reserva.comprador_id !== comprador_id) {
      return res.status(403).json({ error: 'Você não é o dono desta reserva' });
    }

    if (reserva.status_pagamento !== 'pendente') {
      return res.status(409).json({ error: 'Só é possível cancelar reservas pendentes' });
    }

    await pool.query(
      `UPDATE reservas SET status_pagamento = 'cancelado' WHERE id = $1`,
      [reserva_id]
    );

    await pool.query(
      `INSERT INTO logs_status_pagamentos (reserva_id, status_anterior, status_novo, usuario_id)
       VALUES ($1, 'pendente', 'cancelado', $2)`,
      [reserva_id, comprador_id]
    );

    if (reserva.vendedor_usuario_id) {
      criarNotificacao({
        usuario_id: reserva.vendedor_usuario_id,
        tipo: 'reserva_cancelada',
        titulo: 'Reserva cancelada',
        mensagem: `Uma reserva para "${reserva.evento_titulo}" foi cancelada pelo comprador.`,
        payload: { evento_id: reserva.evento_id, reserva_id: Number(reserva_id) },
      });
    }

    return res.json({ message: 'Reserva cancelada com sucesso' });

  } catch (err) {
    console.error('Erro ao cancelar reserva:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = { criar, minhasReservas, cancelar };