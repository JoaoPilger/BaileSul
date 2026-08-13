const pool = require('../config/database');
const { criarNotificacao } = require('../services/notificacao.service');

const INTERVALO_MS = 60 * 60 * 1000; // 1 hora

/**
 * Marca como 'finalizado' os eventos 'agendado' cuja data de término já
 * passou — a mesma transição que o botão manual "Finalizar" (comunidade)
 * já realiza, só que automática. A listagem pública e a criação de reservas
 * já filtram por status = 'agendado', então evento finalizado some da
 * vitrine e para de aceitar reserva sem precisar de nenhuma outra mudança.
 */
const finalizarEventosEncerrados = async () => {
  const { rows } = await pool.query(
    `UPDATE eventos SET status = 'finalizado'
     WHERE status = 'agendado' AND data_fim < CURRENT_DATE
     RETURNING id`
  );
  return rows.length;
};

/**
 * Recusa reservas que ficaram 'pendente' (vendedor nunca confirmou nem
 * recusou o pagamento) de eventos cuja data de término já passou, e avisa
 * tanto o comprador quanto o vendedor responsável com "Reserva expirada".
 * Usa data_fim diretamente (não depende de finalizarEventosEncerrados já
 * ter rodado nesta mesma checagem) para também alcançar reservas pendentes
 * de eventos que já estavam encerrados antes dessa automação existir.
 */
const expirarReservasPendentes = async () => {
  const { rows } = await pool.query(
    `SELECT r.id AS reserva_id, r.comprador_id,
            v.usuario_id AS vendedor_usuario_id,
            e.id AS evento_id, e.titulo AS evento_titulo
     FROM reservas r
     JOIN eventos e ON e.id = r.evento_id
     LEFT JOIN vendedores v ON v.id = r.vendedor_id
     WHERE r.status_pagamento = 'pendente' AND e.data_fim < CURRENT_DATE`
  );

  for (const row of rows) {
    await pool.query(
      `UPDATE reservas SET status_pagamento = 'rejeitado' WHERE id = $1`,
      [row.reserva_id]
    );

    await pool.query(
      `INSERT INTO logs_status_pagamentos (reserva_id, status_anterior, status_novo, usuario_id)
       VALUES ($1, 'pendente', 'rejeitado', NULL)`,
      [row.reserva_id]
    );

    await criarNotificacao({
      usuario_id: row.comprador_id,
      tipo: 'reserva_expirada',
      titulo: 'Reserva expirada',
      mensagem: `Sua reserva para "${row.evento_titulo}" expirou porque o evento já foi encerrado.`,
      payload: { evento_id: row.evento_id, reserva_id: row.reserva_id },
    });

    if (row.vendedor_usuario_id) {
      await criarNotificacao({
        usuario_id: row.vendedor_usuario_id,
        tipo: 'reserva_expirada',
        titulo: 'Reserva expirada',
        mensagem: `Uma reserva pendente para "${row.evento_titulo}" expirou porque o evento já foi encerrado.`,
        payload: { evento_id: row.evento_id, reserva_id: row.reserva_id },
      });
    }
  }

  return rows.length;
};

/**
 * Notifica bandas com contrato aceito sobre eventos que começaram hoje
 * (ou antes) e ainda não foram notificados (evento_iniciado).
 */
const notificarEventosIniciados = async () => {
  const { rows } = await pool.query(
    `SELECT e.id AS evento_id, e.titulo, c.banda_id
     FROM eventos e
     JOIN contratos c ON c.evento_id = e.id AND c.status_aceite = 'aceito'
     WHERE e.data_inicio <= CURRENT_DATE
       AND e.status = 'agendado'
       AND NOT EXISTS (
         SELECT 1 FROM notificacoes n
         WHERE n.usuario_id = c.banda_id
           AND n.tipo = 'evento_iniciado'
           AND n.payload->>'evento_id' = e.id::text
       )`
  );

  for (const row of rows) {
    await criarNotificacao({
      usuario_id: row.banda_id,
      tipo: 'evento_iniciado',
      titulo: 'Seu evento começou',
      mensagem: `O evento "${row.titulo}" começou hoje.`,
      payload: { evento_id: row.evento_id },
    });
  }

  return rows.length;
};

/**
 * Notifica bandas com contrato aceito sobre eventos cuja data de término
 * já passou e ainda não foram notificados (evento_encerrado).
 */
const notificarEventosEncerrados = async () => {
  const { rows } = await pool.query(
    `SELECT e.id AS evento_id, e.titulo, c.banda_id
     FROM eventos e
     JOIN contratos c ON c.evento_id = e.id AND c.status_aceite = 'aceito'
     WHERE e.data_fim < CURRENT_DATE
       AND NOT EXISTS (
         SELECT 1 FROM notificacoes n
         WHERE n.usuario_id = c.banda_id
           AND n.tipo = 'evento_encerrado'
           AND n.payload->>'evento_id' = e.id::text
       )`
  );

  for (const row of rows) {
    await criarNotificacao({
      usuario_id: row.banda_id,
      tipo: 'evento_encerrado',
      titulo: 'Evento encerrado',
      mensagem: `O evento "${row.titulo}" foi encerrado.`,
      payload: { evento_id: row.evento_id },
    });
  }

  return rows.length;
};

const executarChecagem = async () => {
  try {
    const finalizados = await finalizarEventosEncerrados();
    const reservasExpiradas = await expirarReservasPendentes();
    const iniciados = await notificarEventosIniciados();
    const encerrados = await notificarEventosEncerrados();
    if (finalizados > 0 || reservasExpiradas > 0 || iniciados > 0 || encerrados > 0) {
      console.log(`🔔 Eventos: ${finalizados} finalizado(s), ${reservasExpiradas} reserva(s) expirada(s), ${iniciados} notificado(s) de início, ${encerrados} notificado(s) de encerramento`);
    }
  } catch (err) {
    console.error('Erro na checagem periódica de eventos:', err.message);
  }
};

/**
 * Inicia a checagem periódica de eventos iniciados/encerrados
 * (dispara notificações às bandas com contrato aceito).
 */
const iniciarChecagemPeriodica = () => {
  executarChecagem();
  return setInterval(executarChecagem, INTERVALO_MS);
};

module.exports = { iniciarChecagemPeriodica };
