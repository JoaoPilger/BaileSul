import { useState, useEffect } from 'react'
import { cn } from '../../utils/cn';
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import api from '../../services/api'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import styles from './meus_eventos_banda.module.css';

const TABS = [
  { key: 'todos', label: 'Todos' },
  { key: 'convites', label: 'Convites (Pendentes)' },
  { key: 'agendado', label: 'Agendados' },
  { key: 'finalizado', label: 'Realizados' },
  { key: 'cancelado', label: 'Cancelados/Recusados' },
]

const ICON_PATHS = {
  calendar: <><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></>,
  clock: <><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></>,
  check: <><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></>,
  x: <><circle cx="12" cy="12" r="10" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" /></>,
  star: <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />,
  users: <><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></>,
}

function StatusBadge({ status, status_aceite }) {
  if (status_aceite === 'pendente') {
    return <span className={cn(styles['mb-badge'], styles['mb-badge--pendente'])}>Pendente (Convite)</span>
  }
  if (status_aceite === 'recusado') {
    return <span className={cn(styles['mb-badge'], styles['mb-badge--recusado'])}>Recusado</span>
  }
  if (status === 'cancelado') {
    return <span className={cn(styles['mb-badge'], styles['mb-badge--cancelado'])}>Cancelado</span>
  }
  if (status === 'finalizado') {
    return <span className={cn(styles['mb-badge'], styles['mb-badge--realizado'])}>Realizado</span>
  }
  return <span className={cn(styles['mb-badge'], styles['mb-badge--agendado'])}>Agendado</span>
}

export default function MeusEventosBanda() {
  const { usuario, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const [eventos, setEventos] = useState([])
  const [carregando, setCarregando] = useState(true)
  const [abaAtiva, setAbaAtiva] = useState('todos')
  const [busca, setBusca] = useState('')
  const [periodo, setPeriodo] = useState('todos')
  const [cidade, setCidade] = useState('todas')
  const [ordenarPor, setOrdenarPor] = useState('recentes')
  const [viewMode, setViewMode] = useState('lista')
  const [pagina, setPagina] = useState(1)

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login')
    } else if (usuario?.tipo !== 'banda') {
      navigate('/')
    }
  }, [isAuthenticated, usuario, navigate])

  useEffect(() => {
    if (isAuthenticated && usuario?.tipo === 'banda') {
      api.get('/bandas/me/agenda')
        .then((res) => {
          setEventos(res.data || [])
          setCarregando(false)
        })
        .catch((err) => {
          console.error(err)
          setCarregando(false)
        })
    }
  }, [isAuthenticated, usuario])

  const handleResponderContrato = async (eventoId, contratoId, resposta) => {
    try {
      await api.patch(`/eventos/${eventoId}/contratos/${contratoId}`, { resposta })
      setEventos((prev) => 
        prev.map(e => e.contrato_id === contratoId ? { ...e, status_aceite: resposta } : e)
      )
    } catch (err) {
      console.error(err)
      alert(err.response?.data?.error || 'Erro ao responder convite')
    }
  }

  const mappedEvents = eventos.map((ev) => {
    let formattedDate = ''
    if (ev.data_inicio) {
      const parts = ev.data_inicio.split('T')[0].split('-')
      if (parts.length === 3) {
        formattedDate = `${parts[2]}/${parts[1]}/${parts[0]}`
      }
    }

    const localParts = ev.local_endereco && ev.local_endereco.includes(';')
      ? ev.local_endereco.split(';')
      : []
    const city = localParts[3] || ev.local_nome || `${ev.cidade || 'Concórdia'}, ${ev.estado || 'SC'}`

    const dataInicioDate = new Date(ev.data_inicio + 'T00:00:00')
    const hoje = new Date()
    hoje.setHours(0, 0, 0, 0)
    const diffTime = dataInicioDate - hoje
    const diasFaltando = Math.ceil(diffTime / (1000 * 60 * 60 * 24))

    let image = ev.foto_capa_url || ''
    if (image && image.includes('/media/')) {
      const idx = image.indexOf('/media/')
      image = image.substring(idx)
    }

    return {
      id: ev.id,
      contrato_id: ev.contrato_id,
      titulo: ev.titulo,
      subtitulo: `Contratado por: ${ev.comunidade || 'Organização'}`,
      data: formattedDate,
      local: city,
      confirmados: Number(ev.confirmados) || 0,
      status: ev.status_evento,
      status_aceite: ev.status_aceite,
      diasFaltando: diasFaltando > 0 ? diasFaltando : 0,
      dataRealizacao: formattedDate,
      dataCancelamento: formattedDate,
      image: image
    }
  })

  const total = mappedEvents.length
  const proximos = mappedEvents.filter(e => e.status === 'agendado' && e.status_aceite === 'aceito' && e.diasFaltando <= 30 && e.diasFaltando > 0).length
  const realizados = mappedEvents.filter(e => e.status === 'finalizado').length
  const cancelados = mappedEvents.filter(e => e.status === 'cancelado' || e.status_aceite === 'recusado').length

  const stats = [
    { key: 'total', label: 'Total de Eventos', sublabel: 'Eventos contratados', value: total, tone: 'blue', icon: 'calendar' },
    { key: 'proximos', label: 'Próximos Eventos', sublabel: 'Confirmados (30 dias)', value: proximos, tone: 'green', icon: 'clock' },
    { key: 'realizados', label: 'Eventos Realizados', sublabel: 'Eventos concluídos', value: realizados, tone: 'accent', icon: 'check' },
    { key: 'cancelados', label: 'Cancelados/Recusados', sublabel: 'Eventos cancelados/recusados', value: cancelados, tone: 'red', icon: 'x' },
  ]

  const cidadesDisponiveis = Array.from(new Set(mappedEvents.map(e => e.local).filter(Boolean)))

  const eventosFiltrados = mappedEvents.filter((ev) => {
    let matchAba = true
    if (abaAtiva === 'convites') {
      matchAba = ev.status_aceite === 'pendente'
    } else if (abaAtiva === 'agendado') {
      matchAba = ev.status_aceite === 'aceito' && ev.status === 'agendado'
    } else if (abaAtiva === 'finalizado') {
      matchAba = ev.status === 'finalizado'
    } else if (abaAtiva === 'cancelado') {
      matchAba = ev.status === 'cancelado' || ev.status_aceite === 'recusado'
    }

    const matchBusca = ev.titulo.toLowerCase().includes(busca.toLowerCase())
    const matchPeriodo = periodo === 'todos' || (ev.diasFaltando <= parseInt(periodo, 10) && ev.diasFaltando >= 0)
    const matchCidade = cidade === 'todas' || ev.local.toLowerCase().includes(cidade.toLowerCase())
    return matchAba && matchBusca && matchPeriodo && matchCidade
  })

  eventosFiltrados.sort((a, b) => {
    if (ordenarPor === 'recentes') {
      const dateA = a.data ? a.data.split('/').reverse().join('-') : ''
      const dateB = b.data ? b.data.split('/').reverse().join('-') : ''
      return new Date(dateB) - new Date(dateA)
    }
    if (ordenarPor === 'antigos') {
      const dateA = a.data ? a.data.split('/').reverse().join('-') : ''
      const dateB = b.data ? b.data.split('/').reverse().join('-') : ''
      return new Date(dateA) - new Date(dateB)
    }
    if (ordenarPor === 'confirmados') {
      return b.confirmados - a.confirmados
    }
    return 0
  })

  const ITENS_POR_PAGINA = 5
  const totalPaginas = Math.ceil(eventosFiltrados.length / ITENS_POR_PAGINA)
  const inicio = (pagina - 1) * ITENS_POR_PAGINA
  const fim = inicio + ITENS_POR_PAGINA
  const eventosPaginados = eventosFiltrados.slice(inicio, fim)

  if (carregando) {
    return (
      <div className={styles['mb-shell']}>
        <Header />
        <main className={styles['mb-main']}>
          <div className={styles['mb-empty']}>Carregando seus eventos...</div>
        </main>
        <Footer />
      </div>
    )
  }

  return (
    <div className={styles['mb-shell']}>
      <Header />

      <main className={styles['mb-main']}>
        <div className={styles['mb-page-header']}>
          <h1 className={styles['mb-title']}>Meus eventos</h1>
          <p className={styles['mb-subtitle']}>Gerencie, acompanhe e visualize os eventos da sua banda</p>
        </div>

        <div className={styles['mb-stats-grid']}>
          {stats.map((s) => (
            <div key={s.key} className={styles['mb-stat-card']}>
              <div className={styles['mb-stat-info']}>
                <span className={styles['mb-stat-label']}>{s.label}</span>
                <span className={styles['mb-stat-value']}>{s.value}</span>
                <span className={styles['mb-stat-sublabel']}>{s.sublabel}</span>
              </div>
              <div className={cn(styles['mb-stat-icon'], styles[`mb-stat-icon--${s.tone}`])}>
                <svg viewBox="0 0 24 24">{ICON_PATHS[s.icon]}</svg>
              </div>
            </div>
          ))}
        </div>

        <div className={styles['mb-filters-card']}>
          <div className={styles['mb-search']}>
            <svg viewBox="0 0 24 24">
              <circle cx="11" cy="11" r="8" />
              <line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
            <input
              type="text"
              placeholder="Buscar eventos da banda"
              value={busca}
              onChange={(e) => {
                setBusca(e.target.value)
                setPagina(1)
              }}
            />
          </div>

          <div className={styles['mb-select-group']}>
            <span className={styles['mb-select-label']}>Status</span>
            <select 
              className={styles['mb-select']} 
              value={abaAtiva}
              onChange={(e) => {
                setAbaAtiva(e.target.value)
                setPagina(1)
              }}
            >
              <option value="todos">Todos</option>
              <option value="convites">Convites</option>
              <option value="agendado">Agendado</option>
              <option value="finalizado">Realizado</option>
              <option value="cancelado">Cancelado/Recusado</option>
            </select>
          </div>

          <div className={styles['mb-select-group']}>
            <span className={styles['mb-select-label']}>Periodo</span>
            <select 
              className={styles['mb-select']} 
              value={periodo}
              onChange={(e) => {
                setPeriodo(e.target.value)
                setPagina(1)
              }}
            >
              <option value="todos">Todos os períodos</option>
              <option value="7">Próximos 7 dias</option>
              <option value="30">Próximos 30 dias</option>
              <option value="90">Próximos 90 dias</option>
            </select>
          </div>

          <div className={styles['mb-select-group']}>
            <span className={styles['mb-select-label']}>Cidade</span>
            <select 
              className={styles['mb-select']} 
              value={cidade}
              onChange={(e) => {
                setCidade(e.target.value)
                setPagina(1)
              }}
            >
              <option value="todas">Todas as cidades</option>
              {cidadesDisponiveis.map(c => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </div>

          <div className={styles['mb-select-group']}>
            <span className={styles['mb-select-label']}>Ordenar por</span>
            <select 
              className={styles['mb-select']} 
              value={ordenarPor}
              onChange={(e) => {
                setOrdenarPor(e.target.value)
                setPagina(1)
              }}
            >
              <option value="recentes">Mais recentes</option>
              <option value="antigos">Mais antigos</option>
              <option value="confirmados">Mais confirmados</option>
            </select>
          </div>
        </div>

        <div className={styles['mb-toolbar']}>
          <div className={styles['mb-tabs']}>
            {TABS.map((t) => (
              <button
                key={t.key}
                className={cn(styles['mb-tab'], abaAtiva === t.key && styles.active)}
                onClick={() => {
                  setAbaAtiva(t.key)
                  setPagina(1)
                }}
              >
                {t.label}
              </button>
            ))}
          </div>

          <div className={styles['mb-view-toggle']}>
            <button
              className={cn(styles['mb-view-btn'], viewMode === 'calendario' && styles.active)}
              onClick={() => setViewMode('calendario')}
            >
              <svg viewBox="0 0 24 24">
                <rect x="3" y="4" width="18" height="18" rx="2" />
                <line x1="16" y1="2" x2="16" y2="6" />
                <line x1="8" y1="2" x2="8" y2="6" />
                <line x1="3" y1="10" x2="21" y2="10" />
              </svg>
              Calendário
            </button>
            <button
              className={cn(styles['mb-view-btn'], viewMode === 'lista' && styles.active)}
              onClick={() => setViewMode('lista')}
            >
              <svg viewBox="0 0 24 24">
                <line x1="8" y1="6" x2="21" y2="6" />
                <line x1="8" y1="12" x2="21" y2="12" />
                <line x1="8" y1="18" x2="21" y2="18" />
                <line x1="3" y1="6" x2="3.01" y2="6" />
                <line x1="3" y1="12" x2="3.01" y2="12" />
                <line x1="3" y1="18" x2="3.01" y2="18" />
              </svg>
              Lista
            </button>
          </div>
        </div>

        {viewMode === 'calendario' ? (
          <div className={styles['mb-events-list']}>
            <div className={styles['mb-empty']}>Use a aba Calendário principal para visualizar em formato calendário.</div>
          </div>
        ) : (
          <div className={styles['mb-events-list']}>
            {eventosPaginados.map((ev) => (
              <div key={ev.id} className={styles['mb-event-item']}>
                {ev.image ? (
                  <img src={ev.image} alt={ev.titulo} className={styles['mb-event-thumb']} />
                ) : (
                  <div className={styles['mb-event-thumb-placeholder']}>
                    <svg viewBox="0 0 24 24">
                      <rect x="3" y="3" width="18" height="18" rx="2" />
                      <circle cx="8.5" cy="8.5" r="1.5" />
                      <polyline points="21 15 16 10 5 21" />
                    </svg>
                  </div>
                )}

                <div className={styles['mb-event-info']}>
                  <div className={styles['mb-event-name']}>{ev.titulo}</div>
                  <div className={styles['mb-event-subtitle']}>{ev.subtitulo}</div>
                  <div className={styles['mb-event-meta']}>
                    <span className={styles['mb-event-meta-item']}>
                      <svg viewBox="0 0 24 24">
                        <rect x="3" y="4" width="18" height="18" rx="2" />
                        <line x1="16" y1="2" x2="16" y2="6" />
                        <line x1="8" y1="2" x2="8" y2="6" />
                        <line x1="3" y1="10" x2="21" y2="10" />
                      </svg>
                      {ev.data}
                    </span>
                    <span className={styles['mb-event-meta-item']}>
                      <svg viewBox="0 0 24 24">
                        <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                        <circle cx="12" cy="10" r="3" />
                      </svg>
                      {ev.local}
                    </span>
                  </div>
                  <div className={styles['mb-event-confirmados']}>
                    <svg viewBox="0 0 24 24">
                      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                      <circle cx="9" cy="7" r="4" />
                      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                    </svg>
                    {ev.confirmados} confirmados
                  </div>
                </div>

                <div className={styles['mb-event-status']}>
                  <StatusBadge status={ev.status} status_aceite={ev.status_aceite} />
                  <span className={styles['mb-event-status-note']}>
                    {ev.status_aceite === 'pendente' && 'Convite recebido'}
                    {ev.status_aceite === 'recusado' && 'Convite recusado'}
                    {ev.status_aceite === 'aceito' && ev.status === 'agendado' && (ev.diasFaltando > 0 ? `Faltam ${ev.diasFaltando} dias` : 'Evento hoje')}
                    {ev.status_aceite === 'aceito' && ev.status === 'finalizado' && `Realizado em ${ev.dataRealizacao}`}
                    {ev.status === 'cancelado' && `Cancelado em ${ev.dataCancelamento}`}
                  </span>
                </div>

                <div className={styles['mb-event-actions']}>
                  <Link to={`/eventos/${ev.id}`} className={styles['mb-btn-ghost']}>Ver detalhes</Link>
                  {ev.status_aceite === 'pendente' && (
                    <>
                      <button 
                        onClick={() => handleResponderContrato(ev.id, ev.contrato_id, 'aceito')} 
                        className={cn(styles['mb-btn-solid'])}
                        style={{ background: 'var(--success)' }}
                      >
                        Aceitar Convite
                      </button>
                      <button 
                        onClick={() => handleResponderContrato(ev.id, ev.contrato_id, 'recusado')} 
                        className={cn(styles['mb-btn-solid'])}
                        style={{ background: 'var(--danger)' }}
                      >
                        Recusar
                      </button>
                    </>
                  )}
                </div>
              </div>
            ))}

            {eventosPaginados.length === 0 && (
              <div className={styles['mb-empty']}>Nenhum evento encontrado para os filtros selecionados.</div>
            )}
          </div>
        )}

        {totalPaginas > 1 && (
          <div className={styles['mb-pagination']}>
            <button
              className={styles['mb-page-arrow']}
              onClick={() => setPagina((p) => Math.max(1, p - 1))}
              disabled={pagina === 1}
            >
              <svg viewBox="0 0 24 24">
                <polyline points="15 18 9 12 15 6" />
              </svg>
            </button>
            {Array.from({ length: totalPaginas }, (_, i) => i + 1).map((n) => (
              <button
                key={n}
                className={cn(styles['mb-page-num'], pagina === n && styles.active)}
                onClick={() => setPagina(n)}
              >
                {n}
              </button>
            ))}
            <button
              className={styles['mb-page-arrow']}
              onClick={() => setPagina((p) => Math.min(totalPaginas, p + 1))}
              disabled={pagina === totalPaginas}
            >
              <svg viewBox="0 0 24 24">
                <polyline points="9 18 15 12 9 6" />
              </svg>
            </button>
          </div>
        )}
      </main>

      <Footer />
    </div>
  )
}
