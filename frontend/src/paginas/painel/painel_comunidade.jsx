import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import api from '../../services/api'
import { loadCommunityById } from '../../utils/communities'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import styles from './painel.module.css'
import GerenciadorMidiasModal from './GerenciadorMidiasModal'

const ICONS = {
  calendar: <><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></>,
  clock: <><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></>,
  check: <><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></>,
  users: <><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></>,
  plus: <><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></>,
  list: <><line x1="8" y1="6" x2="21" y2="6" /><line x1="8" y1="12" x2="21" y2="12" /><line x1="8" y1="18" x2="21" y2="18" /><line x1="3" y1="6" x2="3.01" y2="6" /><line x1="3" y1="12" x2="3.01" y2="12" /><line x1="3" y1="18" x2="3.01" y2="18" /></>,
  wallet: <><rect x="2" y="6" width="20" height="14" rx="2" /><path d="M16 12h4" /><path d="M2 10h20" /></>,
  settings: <><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" /></>,
  chevronLeft: <><polyline points="15 18 9 12 15 6" /></>,
  chevronRight: <><polyline points="9 18 15 12 9 6" /></>,
  image: <><rect x="3" y="3" width="18" height="18" rx="2" ry="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" /></>,
}

function Icon({ name }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      {ICONS[name]}
    </svg>
  )
}

const WEEKDAYS = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
const MONTHS = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
]

/** Extrai YYYY-MM-DD de uma string de data (aceita ISO timestamp ou só data) */
function extrairData(str) {
  if (!str) return null
  // Suporte a "2026-07-10T00:00:00.000Z" e "2026-07-10"
  return str.slice(0, 10)
}

/** Constrói Date local sem deslocamento de timezone */
function dataLocal(str) {
  const s = extrairData(str)
  if (!s) return null
  const [y, m, d] = s.split('-').map(Number)
  return new Date(y, m - 1, d)
}

export default function PainelComunidade() {
  const { usuario } = useAuth()
  const navigate = useNavigate()
  const [eventos, setEventos] = useState([])
  const [eventosCalendario, setEventosCalendario] = useState([])
  const [vendedoresAtivos, setVendedoresAtivos] = useState(0)
  const [carregando, setCarregando] = useState(true)
  const [midiasModalOpen, setMidiasModalOpen] = useState(false)
  const [nomeExibicao, setNomeExibicao] = useState('')

  useEffect(() => {
    if (!usuario?.id) return
    let ativo = true
    loadCommunityById(usuario.id)
      .then((d) => { if (ativo && d?.title) setNomeExibicao(d.title) })
      .catch(() => {})
    return () => { ativo = false }
  }, [usuario?.id])

  // ── calendário ──────────────────────────────────────────────
  const hoje = new Date()
  hoje.setHours(0, 0, 0, 0)

  const [calView, setCalView] = useState({ year: hoje.getFullYear(), month: hoje.getMonth() })
  const [calSelected, setCalSelected] = useState({ day: hoje.getDate(), month: hoje.getMonth(), year: hoje.getFullYear() })

  useEffect(() => {
    Promise.all([
      api.get('/comunidades/me/eventos').then((r) => r.data.eventos || []).catch(() => []),
      api.get('/vendedores').then((r) => r.data || []).catch(() => []),
      // Calendário compartilhado (RF06): eventos de TODAS as comunidades,
      // pra saber quais dias já estão marcados antes de criar um evento novo.
      api.get('/eventos/calendario').then((r) => r.data || []).catch(() => []),
    ]).then(([eventosData, vendedoresData, calendarioData]) => {
      setEventos(eventosData)
      setVendedoresAtivos(vendedoresData.filter((v) => v.ativo).length)
      setEventosCalendario(calendarioData)
      setCarregando(false)
    })
  }, [])

  // ── próximos eventos ────────────────────────────────────────
  const proximos = eventos
    .filter((e) => e.status === 'agendado')
    .map((e) => {
      const data = dataLocal(e.data_inicio)
      const dias = data ? Math.ceil((data - hoje) / (1000 * 60 * 60 * 24)) : null
      return { ...e, dias, _dataLocal: data }
    })
    .filter((e) => e.dias === null || e.dias >= 0)
    .sort((a, b) => (a.dias ?? 0) - (b.dias ?? 0))
    .slice(0, 5)

  // ── estatísticas ────────────────────────────────────────────
  const stats = [
    { label: 'Total de Eventos', value: eventos.length, tone: 'blue', icon: 'calendar' },
    { label: 'Agendados', value: eventos.filter((e) => e.status === 'agendado').length, tone: 'green', icon: 'clock' },
    { label: 'Realizados', value: eventos.filter((e) => e.status === 'finalizado').length, tone: 'accent', icon: 'check' },
    { label: 'Vendedores Ativos', value: vendedoresAtivos, tone: 'warning', icon: 'users' },
  ]

  const acoes = [
    { to: '/criar-evento', label: 'Criar Evento', sub: 'Novo evento pra sua comunidade', icon: 'plus' },
    { to: '/meus-eventos', label: 'Meus Eventos', sub: 'Ver e gerenciar todos', icon: 'list' },
    { action: () => setMidiasModalOpen(true), label: 'Gerenciar Mídias', sub: 'Fotos e vídeos do CTG', icon: 'image' },
    { to: '/vendedores', label: 'Vendedores', sub: 'Gerenciar equipe de venda', icon: 'users' },
    { to: '/editar-perfil', label: 'Editar Vitrine', sub: 'Dados e perfil da comunidade', icon: 'settings' },
  ]

  // ── mini calendário ─────────────────────────────────────────
  const { year: viewYear, month: viewMonth } = calView

  const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
  const firstWeekday = new Date(viewYear, viewMonth, 1).getDay()

  function goToMonth(delta) {
    setCalView((cur) => {
      let m = cur.month + delta
      let y = cur.year
      if (m < 0) { m = 11; y -= 1 }
      else if (m > 11) { m = 0; y += 1 }
      return { year: y, month: m }
    })
  }

  /** Conjunto de dias (número) com evento no mês visualizado — de QUALQUER comunidade (calendário compartilhado) */
  const diasComEvento = new Set(
    eventosCalendario
      .filter((e) => {
        const s = extrairData(e.data_inicio)
        if (!s) return false
        const [y, m] = s.split('-').map(Number)
        return y === viewYear && m - 1 === viewMonth
      })
      .map((e) => Number(extrairData(e.data_inicio).split('-')[2]))
  )

  const isHoje = (d) =>
    d === hoje.getDate() && viewMonth === hoje.getMonth() && viewYear === hoje.getFullYear()

  const isSelecionado = (d) =>
    d === calSelected.day && viewMonth === calSelected.month && viewYear === calSelected.year

  /** Eventos do dia selecionado — de QUALQUER comunidade (calendário compartilhado) */
  const eventosDoDia = eventosCalendario.filter((e) => {
    const s = extrairData(e.data_inicio)
    if (!s) return false
    const [y, m, d] = s.split('-').map(Number)
    return y === calSelected.year && m - 1 === calSelected.month && d === calSelected.day
  })

  /** Data formatada YYYY-MM-DD para passar ao /criar-evento */
  const dateStartFormatted = `${calSelected.year}-${String(calSelected.month + 1).padStart(2, '0')}-${String(calSelected.day).padStart(2, '0')}`

  const dataSelecionadaLabel = new Date(calSelected.year, calSelected.month, calSelected.day)
    .toLocaleDateString('pt-BR', { weekday: 'long', day: '2-digit', month: 'long', year: 'numeric' })

  const cells = []
  for (let i = 0; i < firstWeekday; i++) cells.push(null)
  for (let d = 1; d <= daysInMonth; d++) cells.push(d)

  return (
    <div className={styles['pn-shell']}>
      <Header />
      <main className={styles['pn-main']}>
        <div className={styles['pn-page-header']}>
          <h1 className={styles['pn-title']}>Painel da Comunidade</h1>
          <p className={styles['pn-subtitle']}>
            Bem-vindo{nomeExibicao ? `, ${nomeExibicao}` : ''}. Aqui está um resumo do que está rolando.
          </p>
        </div>

        {carregando ? (
          <div className={styles['pn-empty']}>Carregando seu painel...</div>
        ) : (
          <>
            {vendedoresAtivos < 2 && (
              <div className={styles['pn-vendor-alert']}>
                <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                  <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                  <line x1="12" y1="9" x2="12" y2="13" />
                  <line x1="12" y1="17" x2="12.01" y2="17" />
                </svg>
                <div className={styles['pn-vendor-alert-text']}>
                  <strong>
                    {vendedoresAtivos === 0
                      ? 'Nenhum vendedor cadastrado'
                      : 'Só 1 vendedor cadastrado'}
                  </strong>
                  <span>
                    O ideal são pelo menos 2 vendedores ativos — sem isso, se o único vendedor
                    ficar indisponível, ninguém consegue confirmar pagamento dos compradores.
                  </span>
                </div>
                <Link to="/vendedores" className={styles['pn-btn-solid']}>Cadastrar vendedores</Link>
              </div>
            )}

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
              {acoes.map((a, idx) => (
                a.to ? (
                  <Link key={a.to || idx} to={a.to} className={styles['pn-action-card']}>
                    <div className={styles['pn-action-icon']}>
                      <Icon name={a.icon} />
                    </div>
                    <div>
                      <div className={styles['pn-action-label']}>{a.label}</div>
                      <div className={styles['pn-action-sub']}>{a.sub}</div>
                    </div>
                  </Link>
                ) : (
                  <button
                    key={idx}
                    type="button"
                    className={styles['pn-action-card']}
                    onClick={a.action}
                  >
                    <div className={styles['pn-action-icon']}>
                      <Icon name={a.icon} />
                    </div>
                    <div>
                      <div className={styles['pn-action-label']}>{a.label}</div>
                      <div className={styles['pn-action-sub']}>{a.sub}</div>
                    </div>
                  </button>
                )
              ))}
            </div>

            {/* ── Card Calendário ── */}
            <h2 className={styles['pn-section-title']}>Calendário</h2>
            <div className={styles['pn-cal-card']}>
              {/* Grid do calendário */}
              <div className={styles['pn-cal-left']}>
                <div className={styles['pn-cal-nav']}>
                  <span className={styles['pn-cal-month-title']}>
                    {MONTHS[viewMonth]} {viewYear}
                  </span>
                  <div className={styles['pn-cal-nav-btns']}>
                    <button type="button" className={styles['pn-cal-nav-btn']} onClick={() => goToMonth(-1)} aria-label="Mês anterior">
                      <Icon name="chevronLeft" />
                    </button>
                    <button type="button" className={styles['pn-cal-nav-btn']} onClick={() => goToMonth(1)} aria-label="Próximo mês">
                      <Icon name="chevronRight" />
                    </button>
                  </div>
                </div>

                <div className={styles['pn-cal-grid']}>
                  {WEEKDAYS.map((w, i) => (
                    <div key={`wd-${i}`} className={styles['pn-cal-weekday']}>{w}</div>
                  ))}
                  {cells.map((day, i) =>
                    day === null ? (
                      <div key={`e${i}`} className={styles['pn-cal-cell-empty']} />
                    ) : (
                      <button
                        key={`${viewYear}-${viewMonth}-${day}`}
                        type="button"
                        className={[
                          styles['pn-cal-cell'],
                          isSelecionado(day) ? styles['pn-cal-cell--selected'] : '',
                          isHoje(day) && !isSelecionado(day) ? styles['pn-cal-cell--today'] : '',
                          diasComEvento.has(day) ? styles['pn-cal-cell--has-event'] : '',
                        ].filter(Boolean).join(' ')}
                        onClick={() => setCalSelected({ day, month: viewMonth, year: viewYear })}
                        aria-label={`${day} de ${MONTHS[viewMonth]}`}
                        aria-pressed={isSelecionado(day)}
                      >
                        {day}
                        {diasComEvento.has(day) && <span className={styles['pn-cal-dot']} aria-hidden />}
                      </button>
                    )
                  )}
                </div>
              </div>

              {/* Painel lateral do dia */}
              <div className={styles['pn-cal-aside']}>
                <div className={styles['pn-cal-aside-head']}>
                  <div>
                    <p className={styles['pn-cal-aside-eyebrow']}>Agenda</p>
                    <p className={styles['pn-cal-aside-date']}>{dataSelecionadaLabel}</p>
                  </div>
                  <button
                    type="button"
                    className={styles['pn-btn-solid']}
                    onClick={() => navigate('/criar-evento', { state: { dateStart: dateStartFormatted } })}
                  >
                    <span className={styles['pn-cal-plus-icon']}>+</span>
                    Criar evento
                  </button>
                </div>

                {eventosDoDia.length === 0 ? (
                  <div className={styles['pn-cal-aside-empty']}>
                    <svg viewBox="0 0 24 24" fill="none" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round" width="36" height="36" aria-hidden>
                      <rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" />
                    </svg>
                    <p>Nenhum evento nesta data</p>
                    <span>Clique em "Criar evento" para adicionar</span>
                  </div>
                ) : (
                  <ul className={styles['pn-cal-event-list']}>
                    {eventosDoDia.map((e) => {
                      const souDono = Number(e.comunidade_id) === Number(usuario?.id)
                      return (
                      <li key={e.id} className={styles['pn-cal-event-item']}>
                        <div className={styles['pn-cal-event-dot']} />
                        <div className={styles['pn-cal-event-info']}>
                          <span className={styles['pn-cal-event-title']}>{e.titulo}</span>
                          <span className={styles['pn-cal-event-status']} data-status={e.status}>
                            {souDono ? 'Seu evento' : e.comunidade}
                            {' · '}
                            {e.status === 'agendado' ? 'Agendado' : e.status === 'finalizado' ? 'Realizado' : e.status}
                          </span>
                        </div>
                        <button
                          type="button"
                          className={styles['pn-btn-solid']}
                          onClick={() => navigate(souDono ? `/eventos/${e.id}/dashboard` : `/eventos/${e.id}`)}
                        >
                          Ver
                        </button>
                      </li>
                      )
                    })}
                  </ul>
                )}
              </div>
            </div>

            <h2 className={styles['pn-section-title']}>Próximos eventos</h2>
            {proximos.length > 0 ? (
              <div className={styles['pn-list']}>
                {proximos.map((e) => (
                  <div key={e.id} className={styles['pn-list-item']}>
                    <div className={styles['pn-list-item-info']}>
                      <div className={styles['pn-list-item-title']}>{e.titulo}</div>
                      <div className={styles['pn-list-item-sub']}>
                        {e.dias === 0 ? 'Hoje' : e.dias === 1 ? 'Amanhã' : e.dias != null ? `Em ${e.dias} dias` : ''}
                      </div>
                    </div>
                    <button
                      type="button"
                      className={styles['pn-btn-solid']}
                      onClick={() => navigate(`/eventos/${e.id}/dashboard`)}
                    >
                      Ver
                    </button>
                  </div>
                ))}
              </div>
            ) : (
              <div className={styles['pn-empty']}>Nenhum evento agendado no momento.</div>
            )}
          </>
        )}
      </main>

      <GerenciadorMidiasModal
        open={midiasModalOpen}
        onClose={() => setMidiasModalOpen(false)}
      />

      <Footer />
    </div>
  )
}
