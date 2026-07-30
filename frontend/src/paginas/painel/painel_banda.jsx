import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import api from '../../services/api'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import styles from './painel.module.css'

const ICONS = {
  calendar: <><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></>,
  clock: <><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></>,
  check: <><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></>,
  alert: <><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" /></>,
  settings: <><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" /></>,
  contract: <><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /><line x1="16" y1="13" x2="8" y2="13" /><line x1="16" y1="17" x2="8" y2="17" /><polyline points="10 9 9 9 8 9" /></>,
}

function Icon({ name }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      {ICONS[name]}
    </svg>
  )
}

const BADGE = {
  pendente: { label: 'Pendente', cls: 'pn-badge--pendente' },
  aceito: { label: 'Aceito', cls: 'pn-badge--aceito' },
  recusado: { label: 'Recusado', cls: 'pn-badge--recusado' },
}

export default function PainelBanda() {
  const { usuario, token } = useAuth()
  const [agenda, setAgenda] = useState([])
  const [carregando, setCarregando] = useState(true)
  const [processandoId, setProcessandoId] = useState(null)

  useEffect(() => {
    api.get('/bandas/me/agenda')
      .then((r) => setAgenda(Array.isArray(r.data) ? r.data : []))
      .catch(() => setAgenda([]))
      .finally(() => setCarregando(false))
  }, [])

  const responder = async (contrato_id, evento_id, aceitar) => {
    setProcessandoId(contrato_id)
    try {
      await api.patch(
        `/eventos/${evento_id}/contratos/${contrato_id}`,
        { status_aceite: aceitar ? 'aceito' : 'recusado' },
        { headers: { Authorization: `Bearer ${token}` } },
      )
      setAgenda((prev) => prev.map((a) => (
        a.contrato_id === contrato_id ? { ...a, status_aceite: aceitar ? 'aceito' : 'recusado' } : a
      )))
    } finally {
      setProcessandoId(null)
    }
  }

  const pendentes = agenda.filter((a) => a.status_aceite === 'pendente')
  const aceitos = agenda.filter((a) => a.status_aceite === 'aceito')

  const hoje = new Date()
  hoje.setHours(0, 0, 0, 0)
  const proximos = aceitos
    .map((a) => {
      // data_inicio vem como TIMESTAMPTZ (string ISO completa, ex: "2026-07-10T00:00:00.000Z"),
      // então passamos direto pro Date — concatenar 'T00:00:00' aqui gerava string inválida
      // (ex: "...000ZT00:00:00"), o que fazia `dias` virar NaN e o evento sumir do filtro.
      const data = a.data_inicio ? new Date(a.data_inicio) : null
      const diaBase = data
        ? new Date(data.getFullYear(), data.getMonth(), data.getDate())
        : null
      const dias = diaBase ? Math.round((diaBase - hoje) / (1000 * 60 * 60 * 24)) : null
      return { ...a, dias }
    })
    .filter((a) => a.dias === null || a.dias >= 0)
    .sort((a, b) => (a.dias ?? 0) - (b.dias ?? 0))
    .slice(0, 5)

  const stats = [
    { label: 'Contratos Pendentes', value: pendentes.length, tone: 'warning', icon: 'alert' },
    { label: 'Confirmados', value: aceitos.length, tone: 'green', icon: 'check' },
    { label: 'Total na Agenda', value: agenda.length, tone: 'blue', icon: 'calendar' },
  ]

  return (
    <div className={styles['pn-shell']}>
      <Header />
      <main className={styles['pn-main']}>
        <div className={styles['pn-page-header']}>
          <h1 className={styles['pn-title']}>Painel da Banda</h1>
          <p className={styles['pn-subtitle']}>
            Bem-vindo{usuario?.email ? `, ${usuario.email}` : ''}. Seus contratos e agenda em um só lugar.
          </p>
        </div>

        {carregando ? (
          <div className={styles['pn-empty']}>Carregando seu painel...</div>
        ) : (
          <>
            <div className={styles['pn-stats-grid']}>
              {stats.map((s) => (
                <div key={s.label} className={styles['pn-stat-card']}>
                  <div className={styles['pn-stat-info']}>
                    <span className={styles['pn-stat-label']}>{s.label}</span>
                    <span className={styles['pn-stat-value']}>{s.value}</span>
                  </div>
                  <div className={`${styles['pn-stat-icon']} ${styles[`pn-stat-icon--${s.tone}`]}`}>
                    <Icon name={s.icon} />
                  </div>
                </div>
              ))}
            </div>

            <h2 className={styles['pn-section-title']}>Atalhos</h2>
            <div className={styles['pn-actions-grid']}>
              <Link to="/contratos" className={styles['pn-action-card']}>
                <div className={styles['pn-action-icon']}>
                  <Icon name="contract" />
                </div>
                <div>
                  <div className={styles['pn-action-label']}>Contratos</div>
                  <div className={styles['pn-action-sub']}>
                    {pendentes.length > 0
                      ? `${pendentes.length} pendente${pendentes.length > 1 ? 's' : ''}`
                      : 'Ver convites das comunidades'}
                  </div>
                </div>
              </Link>
              <Link to="/configuracoes" className={styles['pn-action-card']}>
                <div className={styles['pn-action-icon']}>
                  <Icon name="settings" />
                </div>
                <div>
                  <div className={styles['pn-action-label']}>Editar Vitrine</div>
                  <div className={styles['pn-action-sub']}>Nome, estilo, foto, vídeo</div>
                </div>
              </Link>
            </div>

            {pendentes.length > 0 && (
              <>
                <h2 className={styles['pn-section-title']}>Convites pendentes</h2>
                <div className={styles['pn-list']}>
                  {pendentes.map((a) => (
                    <div key={a.contrato_id} className={styles['pn-list-item']}>
                      <div className={styles['pn-list-item-info']}>
                        <div className={styles['pn-list-item-title']}>{a.titulo}</div>
                        <div className={styles['pn-list-item-sub']}>
                          {a.comunidade}{a.cidade ? ` · ${a.cidade}` : ''}
                        </div>
                      </div>
                      <button
                        type="button"
                        className={styles['pn-btn-solid']}
                        disabled={processandoId === a.contrato_id}
                        onClick={() => responder(a.contrato_id, a.id, true)}
                      >
                        Aceitar
                      </button>
                      <button
                        type="button"
                        className={styles['pn-btn-ghost']}
                        disabled={processandoId === a.contrato_id}
                        onClick={() => responder(a.contrato_id, a.id, false)}
                      >
                        Recusar
                      </button>
                    </div>
                  ))}
                </div>
              </>
            )}

            <h2 className={styles['pn-section-title']}>Próximos eventos confirmados</h2>
            {proximos.length > 0 ? (
              <div className={styles['pn-list']}>
                {proximos.map((a) => (
                  <div key={a.contrato_id} className={styles['pn-list-item']}>
                    <div className={styles['pn-list-item-info']}>
                      <div className={styles['pn-list-item-title']}>{a.titulo}</div>
                      <div className={styles['pn-list-item-sub']}>
                        {a.comunidade}
                        {a.dias === 0 ? ' · Hoje' : a.dias === 1 ? ' · Amanhã' : a.dias != null ? ` · Em ${a.dias} dias` : ''}
                      </div>
                    </div>
                    <span className={`${styles['pn-badge']} ${styles[BADGE.aceito.cls]}`}>
                      {BADGE.aceito.label}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <div className={styles['pn-empty']}>Nenhum evento confirmado no momento.</div>
            )}
          </>
        )}
      </main>
      <Footer />
    </div>
  )
}
