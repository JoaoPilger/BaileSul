const pool = require('../config/database');
const { criarNotificacao } = require('../services/notificacao.service');

const INTERVALO_MS = 60 * 60 * 1000; // 1 hora

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
    const iniciados = await notificarEventosIniciados();
    const encerrados = await notificarEventosEncerrados();
    if (iniciados > 0 || encerrados > 0) {
      console.log(`🔔 Notificações de evento: ${iniciados} iniciado(s), ${encerrados} encerrado(s)`);
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
