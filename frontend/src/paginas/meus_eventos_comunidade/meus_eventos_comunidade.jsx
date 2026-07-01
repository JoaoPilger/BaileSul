import { useState, useEffect } from 'react'
import { cn } from '../../utils/cn';
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import api from '../../services/api'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import styles from './meus_eventos_comunidade.module.css';

const TABS = [
  { key: 'todos', label: 'Todos' },
  { key: 'agendado', label: 'Agendados' },
  { key: 'finalizado', label: 'Realizados' },
  { key: 'cancelado', label: 'Cancelados' },
]

const ICON_PATHS = {
  calendar: <><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></>,
  clock: <><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></>,
  check: <><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></>,
  x: <><circle cx="12" cy="12" r="10" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" /></>,
}

function StatusBadge({ status }) {
  const map = {
    agendado: { label: 'Agendado', cls: 'me-badge--agendado' },
    finalizado: { label: 'Realizado', cls: 'me-badge--realizado' },
    cancelado: { label: 'Cancelado', cls: 'me-badge--cancelado' },
  }
  const s = map[status] || { label: 'Agendado', cls: 'me-badge--agendado' }
  return <span className={cn(styles['me-badge'], styles[s.cls])}>{s.label}</span>
}

export default function MeusEventosComunidade() {
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
    } else if (usuario?.tipo !== 'comunidade') {
      navigate('/')
    }
  }, [isAuthenticated, usuario, navigate])

  useEffect(() => {
    if (isAuthenticated && usuario?.tipo === 'comunidade') {
      api.get('/comunidades/me/eventos')
        .then((res) => {
          setEventos(res.data.eventos || [])
          setCarregando(false)
        })
        .catch((err) => {
          console.error(err)
          setCarregando(false)
        })
    }
  }, [isAuthenticated, usuario])

  const handleCancelar = async (id) => {
    try {
      await api.delete(`/eventos/${id}`)
      setEventos((prev) => prev.map(e => e.id === id ? { ...e, status: 'cancelado' } : e))
    } catch (err) {
      console.error(err)
    }
  }

  const mappedEvents = eventos.map((ev) => {
    const bandMatch = ev.descricao ? ev.descricao.match(/Banda\/Artista:\s*(.*)/i) : null
    const subtitulo = bandMatch ? bandMatch[1].trim() : 'Organização'
    
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
    const city = localParts[3] || ev.local_nome || 'Concórdia, SC'

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
      titulo: ev.titulo,
      subtitulo: subtitulo,
      data: formattedDate,
      hora: '20:00',
      local: city,
      confirmados: Math.floor(Math.random() * 200) + 50,
      status: ev.status,
      diasFaltando: diasFaltando > 0 ? diasFaltando : 0,
      ultimaEdicao: 'Recente',
      dataRealizacao: formattedDate,
      dataCancelamento: formattedDate,
      image: image
    }
  })

  const total = mappedEvents.length
  const proximos = mappedEvents.filter(e => e.status === 'agendado' && e.diasFaltando <= 30 && e.diasFaltando > 0).length
  const realizados = mappedEvents.filter(e => e.status === 'finalizado').length
  const cancelados = mappedEvents.filter(e => e.status === 'cancelado').length

  const stats = [
    { key: 'total', label: 'Total de Eventos', sublabel: 'Todos os eventos criados', value: total, tone: 'blue', icon: 'calendar' },
    { key: 'proximos', label: 'Próximos Eventos', sublabel: 'Nos próximos 30 dias', value: proximos, tone: 'green', icon: 'clock' },
    { key: 'realizados', label: 'Eventos Realizados', sublabel: 'Eventos concluídos', value: realizados, tone: 'accent', icon: 'check' },
    { key: 'cancelados', label: 'Cancelados', sublabel: 'Eventos cancelados', value: cancelados, tone: 'red', icon: 'x' },
  ]

  const cidadesDisponiveis = Array.from(new Set(mappedEvents.map(e => e.local).filter(Boolean)))

  const eventosFiltrados = mappedEvents.filter((ev) => {
    const matchAba = abaAtiva === 'todos' || ev.status === abaAtiva
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
      <div className={styles['me-shell']}>
        <Header />
        <main className={styles['me-main']}>
          <div className={styles['me-empty']}>Carregando seus eventos...</div>
        </main>
        <Footer />
      </div>
    )
  }

  return (
    <div className={styles['me-shell']}>
      <Header />

      <main className={styles['me-main']}>
        <div className={styles['me-page-header']}>
          <h1 className={styles['me-title']}>Meus eventos</h1>
          <p className={styles['me-subtitle']}>Gerencie, acompanhe e visualize os eventos da sua comunidade</p>
        </div>

        <div className={styles['me-stats-grid']}>
          {stats.map((s) => (
            <div key={s.key} className={styles['me-stat-card']}>
              <div className={styles['me-stat-info']}>
                <span className={styles['me-stat-label']}>{s.label}</span>
                <span className={styles['me-stat-value']}>{s.value}</span>
                <span className={styles['me-stat-sublabel']}>{s.sublabel}</span>
              </div>
              <div className={cn(styles['me-stat-icon'], styles[`me-stat-icon--${s.tone}`])}>
                <svg viewBox="0 0 24 24">{ICON_PATHS[s.icon]}</svg>
              </div>
            </div>
          ))}
        </div>

        <div className={styles['me-filters-card']}>
          <div className={styles['me-search']}>
            <svg viewBox="0 0 24 24">
              <circle cx="11" cy="11" r="8" />
              <line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
            <input
              type="text"
              placeholder="Buscar meus eventos"
              value={busca}
              onChange={(e) => {
                setBusca(e.target.value)
                setPagina(1)
              }}
            />
          </div>

          <div className={styles['me-select-group']}>
            <span className={styles['me-select-label']}>Status</span>
            <select 
              className={styles['me-select']} 
              value={abaAtiva}
              onChange={(e) => {
                setAbaAtiva(e.target.value)
                setPagina(1)
              }}
            >
              <option value="todos">Todos</option>
              <option value="agendado">Agendado</option>
              <option value="finalizado">Realizado</option>
              <option value="cancelado">Cancelado</option>
            </select>
          </div>

          <div className={styles['me-select-group']}>
            <span className={styles['me-select-label']}>Periodo</span>
            <select 
              className={styles['me-select']} 
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

          <div className={styles['me-select-group']}>
            <span className={styles['me-select-label']}>Cidade</span>
            <select 
              className={styles['me-select']} 
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

          <div className={styles['me-select-group']}>
            <span className={styles['me-select-label']}>Ordenar por</span>
            <select 
              className={styles['me-select']} 
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

        <div className={styles['me-toolbar']}>
          <div className={styles['me-tabs']}>
            {TABS.map((t) => (
              <button
                key={t.key}
                className={cn(styles['me-tab'], abaAtiva === t.key && styles.active)}
                onClick={() => {
                  setAbaAtiva(t.key)
                  setPagina(1)
                }}
              >
                {t.label}
              </button>
            ))}
          </div>

          <div className={styles['me-view-toggle']}>
            <button
              className={cn(styles['me-view-btn'], viewMode === 'calendario' && styles.active)}
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
              className={cn(styles['me-view-btn'], viewMode === 'lista' && styles.active)}
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
          <div className={styles['me-events-list']}>
            <div className={styles['me-empty']}>Use a aba Calendário principal para visualizar em formato calendário.</div>
          </div>
        ) : (
          <div className={styles['me-events-list']}>
            {eventosPaginados.map((ev) => (
              <div key={ev.id} className={styles['me-event-item']}>
                {ev.image ? (
                  <img src={ev.image} alt={ev.titulo} className={styles['me-event-thumb']} />
                ) : (
                  <div className={styles['me-event-thumb-placeholder']}>
                    <svg viewBox="0 0 24 24">
                      <rect x="3" y="3" width="18" height="18" rx="2" />
                      <circle cx="8.5" cy="8.5" r="1.5" />
                      <polyline points="21 15 16 10 5 21" />
                    </svg>
                  </div>
                )}

                <div className={styles['me-event-info']}>
                  <div className={styles['me-event-name']}>{ev.titulo}</div>
                  <div className={styles['me-event-subtitle']}>{ev.subtitulo}</div>
                  <div className={styles['me-event-meta']}>
                    <span className={styles['me-event-meta-item']}>
                      <svg viewBox="0 0 24 24">
                        <rect x="3" y="4" width="18" height="18" rx="2" />
                        <line x1="16" y1="2" x2="16" y2="6" />
                        <line x1="8" y1="2" x2="8" y2="6" />
                        <line x1="3" y1="10" x2="21" y2="10" />
                      </svg>
                      {ev.data}
                    </span>
                    <span className={styles['me-event-meta-item']}>
                      <svg viewBox="0 0 24 24">
                        <circle cx="12" cy="12" r="10" />
                        <polyline points="12 6 12 12 16 14" />
                      </svg>
                      {ev.hora}
                    </span>
                    <span className={styles['me-event-meta-item']}>
                      <svg viewBox="0 0 24 24">
                        <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                        <circle cx="12" cy="10" r="3" />
                      </svg>
                      {ev.local}
                    </span>
                  </div>
                  <div className={styles['me-event-confirmados']}>
                    <svg viewBox="0 0 24 24">
                      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                      <circle cx="9" cy="7" r="4" />
                      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                    </svg>
                    {ev.confirmados} confirmados
                  </div>
                </div>

                <div className={styles['me-event-status']}>
                  <StatusBadge status={ev.status} />
                  <span className={styles['me-event-status-note']}>
                    {ev.status === 'agendado' && (ev.diasFaltando > 0 ? `Faltam ${ev.diasFaltando} dias` : 'Evento hoje')}
                    {ev.status === 'finalizado' && `Realizado em ${ev.dataRealizacao}`}
                    {ev.status === 'cancelado' && `Cancelado em ${ev.dataCancelamento}`}
                  </span>
                </div>

                <div className={styles['me-event-actions']}>
                  <Link to={`/eventos/${ev.id}`} className={styles['me-btn-ghost']}>Ver detalhes</Link>
                  {ev.status === 'agendado' && (
                    <button 
                      onClick={() => handleCancelar(ev.id)} 
                      className={cn(styles['me-btn-solid'], styles['me-badge--cancelado'])}
                      style={{ background: 'var(--danger)' }}
                    >
                      Cancelar Evento
                    </button>
                  )}
                </div>
              </div>
            ))}

            {eventosPaginados.length === 0 && (
              <div className={styles['me-empty']}>Nenhum evento encontrado para os filtros selecionados.</div>
            )}
          </div>
        )}

        {totalPaginas > 1 && (
          <div className={styles['me-pagination']}>
            <button
              className={styles['me-page-arrow']}
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
                className={cn(styles['me-page-num'], pagina === n && styles.active)}
                onClick={() => setPagina(n)}
              >
                {n}
              </button>
            ))}
            <button
              className={styles['me-page-arrow']}
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
