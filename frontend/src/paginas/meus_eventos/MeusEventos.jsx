import { useState, useEffect } from 'react'
import { cn } from '../../utils/cn'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import api from '../../services/api'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import Snackbar from '../../components/ui/Snackbar'
import EditarEventoModal from '../../components/evento/EditarEventoModal'
import styles from './MeusEventos.module.css'

const ICON_PATHS = {
  calendar: <><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></>,
  clock: <><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></>,
  check: <><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></>,
  x: <><circle cx="12" cy="12" r="10" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" /></>,
}

const TABS_BANDA = [
  { key: 'todos', label: 'Todos' },
  { key: 'convites', label: 'Convites (Pendentes)' },
  { key: 'agendado', label: 'Agendados' },
  { key: 'finalizado', label: 'Realizados' },
  { key: 'cancelado', label: 'Cancelados/Recusados' },
]

const TABS_COMUNIDADE = [
  { key: 'todos', label: 'Todos' },
  { key: 'agendado', label: 'Agendados' },
  { key: 'finalizado', label: 'Realizados' },
  { key: 'cancelado', label: 'Cancelados' },
]

function StatusBadgeBanda({ status, status_aceite }) {
  if (status_aceite === 'pendente') {
    return <span className={cn(styles['mx-badge'], styles['mx-badge--pendente'])}>Pendente (Convite)</span>
  }
  if (status_aceite === 'recusado') {
    return <span className={cn(styles['mx-badge'], styles['mx-badge--recusado'])}>Recusado</span>
  }
  if (status === 'cancelado') {
    return <span className={cn(styles['mx-badge'], styles['mx-badge--cancelado'])}>Cancelado</span>
  }
  if (status === 'finalizado') {
    return <span className={cn(styles['mx-badge'], styles['mx-badge--realizado'])}>Realizado</span>
  }
  return <span className={cn(styles['mx-badge'], styles['mx-badge--agendado'])}>Agendado</span>
}

function StatusBadgeComunidade({ status }) {
  const map = {
    agendado: { label: 'Agendado', cls: 'mx-badge--agendado' },
    finalizado: { label: 'Realizado', cls: 'mx-badge--realizado' },
    cancelado: { label: 'Cancelado', cls: 'mx-badge--cancelado' },
  }
  const s = map[status] || map.agendado
  return <span className={cn(styles['mx-badge'], styles[s.cls])}>{s.label}</span>
}

function mapDataLocal(ev, fallbackCidadeEstado) {
  let formattedDate = ''
  if (ev.data_inicio) {
    const parts = ev.data_inicio.split('T')[0].split('-')
    if (parts.length === 3) formattedDate = `${parts[2]}/${parts[1]}/${parts[0]}`
  }

  const localParts = ev.local_endereco && ev.local_endereco.includes(';')
    ? ev.local_endereco.split(';')
    : []
  const city = localParts[3] || ev.local_nome || fallbackCidadeEstado
  const cidade = ((localParts[3] || ev.local_nome || String(fallbackCidadeEstado).split(',')[0]) || '').trim()

  // data_inicio vem como TIMESTAMPTZ (string ISO completa, ex: "2026-07-10T00:00:00.000Z")
  // — concatenar 'T00:00:00' aqui gerava string inválida (ex: "...000ZT00:00:00"), o que
  // fazia `diasFaltando` virar NaN (e ser zerado pelo clamp abaixo) pra todo evento.
  let dataInicioDate = null
  if (ev.data_inicio) {
    const [y, m, d] = String(ev.data_inicio).slice(0, 10).split('-').map(Number)
    dataInicioDate = new Date(y, m - 1, d)
  }
  const hoje = new Date()
  hoje.setHours(0, 0, 0, 0)
  const diasFaltando = dataInicioDate ? Math.ceil((dataInicioDate - hoje) / (1000 * 60 * 60 * 24)) : 0

  const image = ev.foto_capa_url || ''

  return { formattedDate, city, cidade, diasFaltando: diasFaltando > 0 ? diasFaltando : 0, image }
}

export default function MeusEventos({ tipo }) {
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
  const [eventoEditando, setEventoEditando] = useState(null)
  const [snackbar, setSnackbar] = useState({ open: false, message: '' })

  const notificar = (message) => setSnackbar({ open: true, message })

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login')
    } else if (tipo === 'comunidade' && usuario?.tipo === 'banda') {
      navigate('/meus-eventos/banda')
    } else if (usuario?.tipo !== tipo) {
      navigate('/')
    }
  }, [isAuthenticated, usuario, navigate, tipo])

  const carregarEventos = async () => {
    try {
      if (tipo === 'banda') {
        const res = await api.get('/bandas/me/agenda')
        setEventos(res.data || [])
      } else {
        const res = await api.get('/comunidades/me/eventos')
        setEventos(res.data.eventos || [])
      }
    } catch (err) {
      console.error(err)
    } finally {
      setCarregando(false)
    }
  }

  useEffect(() => {
    if (isAuthenticated && usuario?.tipo === tipo) {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- carrega a lista ao entrar na tela ou trocar de tipo
      carregarEventos()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated, usuario, tipo])

  const handleResponderContrato = async (eventoId, contratoId, resposta) => {
    try {
      await api.patch(`/eventos/${eventoId}/contratos/${contratoId}`, { resposta })
      setEventos((prev) =>
        prev.map((e) => (e.contrato_id === contratoId ? { ...e, status_aceite: resposta } : e))
      )
    } catch (err) {
      console.error(err)
      notificar(err.response?.data?.error || 'Erro ao responder convite')
    }
  }

  const handleCancelar = async (id) => {
    try {
      await api.delete(`/eventos/${id}`)
      setEventos((prev) => prev.map((e) => (e.id === id ? { ...e, status: 'cancelado' } : e)))
    } catch (err) {
      console.error(err)
      notificar(err.response?.data?.error || 'Erro ao cancelar evento')
    }
  }

  const handleFinalizar = async (id) => {
    try {
      await api.put(`/eventos/${id}`, { status: 'finalizado' })
      setEventos((prev) => prev.map((e) => (e.id === id ? { ...e, status: 'finalizado' } : e)))
      notificar('Evento finalizado.')
    } catch (err) {
      console.error(err)
      notificar(err.response?.data?.error || 'Erro ao finalizar evento')
    }
  }

  const mappedEvents = eventos.map((ev) => {
    if (tipo === 'banda') {
      const { formattedDate, city, cidade, diasFaltando, image } = mapDataLocal(ev, `${ev.cidade || 'Concórdia'}, ${ev.estado || 'SC'}`)
      return {
        id: ev.id,
        contrato_id: ev.contrato_id,
        titulo: ev.titulo,
        subtitulo: `Contratado por: ${ev.comunidade || 'Organização'}`,
        data: formattedDate,
        local: city,
        cidade,
        confirmados: Number(ev.confirmados) || 0,
        status: ev.status_evento,
        status_aceite: ev.status_aceite,
        diasFaltando,
        dataRealizacao: formattedDate,
        dataCancelamento: formattedDate,
        image,
      }
    }

    const bandMatch = ev.descricao ? ev.descricao.match(/Banda\/Artista:\s*(.*)/i) : null
    const subtitulo = bandMatch ? bandMatch[1].trim() : 'Organização'
    const { formattedDate, city, cidade, diasFaltando, image } = mapDataLocal(ev, 'Concórdia, SC')

    let valorFormatado = 'Grátis'
    if (ev.valor_ingresso != null && ev.valor_ingresso !== '' && Number(ev.valor_ingresso) > 0) {
      valorFormatado = `R$ ${Number(ev.valor_ingresso).toFixed(2).replace('.', ',')}`
    }

    const hojeRef = new Date()
    hojeRef.setHours(0, 0, 0, 0)
    const fimStr = (ev.data_fim || ev.data_inicio || '').split('T')[0]
    const dataFimEvento = fimStr ? new Date(`${fimStr}T00:00:00`) : null
    const eventoEncerrado = dataFimEvento ? dataFimEvento < hojeRef : false
    const statusEfetivo = ev.status === 'agendado' && eventoEncerrado ? 'finalizado' : ev.status

    return {
      id: ev.id,
      titulo: ev.titulo,
      subtitulo,
      data: formattedDate,
      local: city,
      cidade,
      valor: valorFormatado,
      confirmados: Number(ev.confirmados) || 0,
      status: statusEfetivo,
      diasFaltando,
      dataRealizacao: formattedDate,
      dataCancelamento: formattedDate,
      image,
    }
  })

  const total = mappedEvents.length
  // diasFaltando >= 0 inclui o evento de hoje — mesmo critério já usado no
  // filtro de período abaixo (matchPeriodo). Com > 0 estrito, um evento
  // acontecendo hoje mesmo (diasFaltando === 0) ficava fora da contagem.
  const proximos = tipo === 'banda'
    ? mappedEvents.filter((e) => e.status === 'agendado' && e.status_aceite === 'aceito' && e.diasFaltando <= 30 && e.diasFaltando >= 0).length
    : mappedEvents.filter((e) => e.status === 'agendado' && e.diasFaltando <= 30 && e.diasFaltando >= 0).length
  const realizados = mappedEvents.filter((e) => e.status === 'finalizado').length
  const cancelados = tipo === 'banda'
    ? mappedEvents.filter((e) => e.status === 'cancelado' || e.status_aceite === 'recusado').length
    : mappedEvents.filter((e) => e.status === 'cancelado').length

  const stats = [
    { key: 'total', label: 'Total de Eventos', sublabel: tipo === 'banda' ? 'Eventos contratados' : 'Todos os eventos criados', value: total, tone: 'blue', icon: 'calendar' },
    { key: 'proximos', label: 'Próximos Eventos', sublabel: tipo === 'banda' ? 'Confirmados (30 dias)' : 'Nos próximos 30 dias', value: proximos, tone: 'green', icon: 'clock' },
    { key: 'realizados', label: 'Eventos Realizados', sublabel: 'Eventos concluídos', value: realizados, tone: 'accent', icon: 'check' },
    { key: 'cancelados', label: tipo === 'banda' ? 'Cancelados/Recusados' : 'Cancelados', sublabel: tipo === 'banda' ? 'Eventos cancelados/recusados' : 'Eventos cancelados', value: cancelados, tone: 'red', icon: 'x' },
  ]

  const cidadesDisponiveis = Array.from(new Set(mappedEvents.map((e) => e.cidade).filter(Boolean)))

  const eventosFiltrados = mappedEvents.filter((ev) => {
    let matchAba = true
    if (tipo === 'banda') {
      if (abaAtiva === 'convites') matchAba = ev.status_aceite === 'pendente'
      else if (abaAtiva === 'agendado') matchAba = ev.status_aceite === 'aceito' && ev.status === 'agendado'
      else if (abaAtiva === 'finalizado') matchAba = ev.status === 'finalizado'
      else if (abaAtiva === 'cancelado') matchAba = ev.status === 'cancelado' || ev.status_aceite === 'recusado'
    } else {
      matchAba = abaAtiva === 'todos' || ev.status === abaAtiva
    }

    const matchBusca = ev.titulo.toLowerCase().includes(busca.toLowerCase())
    const matchPeriodo = periodo === 'todos' || (ev.diasFaltando <= parseInt(periodo, 10) && ev.diasFaltando >= 0)
    const matchCidade = cidade === 'todas' || (ev.cidade || '').toLowerCase() === cidade.toLowerCase()
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
    if (ordenarPor === 'confirmados') return b.confirmados - a.confirmados
    return 0
  })

  const ITENS_POR_PAGINA = 5
  const totalPaginas = Math.ceil(eventosFiltrados.length / ITENS_POR_PAGINA)
  const inicio = (pagina - 1) * ITENS_POR_PAGINA
  const eventosPaginados = eventosFiltrados.slice(inicio, inicio + ITENS_POR_PAGINA)

  const tabs = tipo === 'banda' ? TABS_BANDA : TABS_COMUNIDADE
  const detalhesLink = (ev) => (tipo === 'banda' ? `/eventos/${ev.id}` : `/eventos/${ev.id}/dashboard`)

  if (carregando) {
    return (
      <div className={styles['mx-shell']}>
        <Header />
        <main className={styles['mx-main']}>
          <div className={styles['mx-empty']}>Carregando seus eventos...</div>
        </main>
        <Footer />
      </div>
    )
  }

  return (
    <div className={styles['mx-shell']}>
      <Header />

      <main className={styles['mx-main']}>
        <div className={styles['mx-page-header']}>
          <h1 className={styles['mx-title']}>Meus eventos</h1>
          <p className={styles['mx-subtitle']}>
            Gerencie, acompanhe e visualize os eventos {tipo === 'banda' ? 'da sua banda' : 'da sua comunidade'}
          </p>
        </div>

        <div className={styles['mx-stats-grid']}>
          {stats.map((s) => (
            <div key={s.key} className={styles['mx-stat-card']}>
              <div className={styles['mx-stat-info']}>
                <span className={styles['mx-stat-label']}>{s.label}</span>
                <span className={styles['mx-stat-value']}>{s.value}</span>
                <span className={styles['mx-stat-sublabel']}>{s.sublabel}</span>
              </div>
              <div className={cn(styles['mx-stat-icon'], styles[`mx-stat-icon--${s.tone}`])}>
                <svg viewBox="0 0 24 24">{ICON_PATHS[s.icon]}</svg>
              </div>
            </div>
          ))}
        </div>

        <div className={styles['mx-filters-card']}>
          <div className={styles['mx-search']}>
            <svg viewBox="0 0 24 24">
              <circle cx="11" cy="11" r="8" />
              <line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
            <input
              type="text"
              placeholder={tipo === 'banda' ? 'Buscar eventos da banda' : 'Buscar meus eventos'}
              value={busca}
              onChange={(e) => { setBusca(e.target.value); setPagina(1) }}
            />
          </div>

          <div className={styles['mx-select-group']}>
            <span className={styles['mx-select-label']}>Status</span>
            <select className={styles['mx-select']} value={abaAtiva} onChange={(e) => { setAbaAtiva(e.target.value); setPagina(1) }}>
              {tabs.map((t) => <option key={t.key} value={t.key}>{t.label}</option>)}
            </select>
          </div>

          <div className={styles['mx-select-group']}>
            <span className={styles['mx-select-label']}>Periodo</span>
            <select className={styles['mx-select']} value={periodo} onChange={(e) => { setPeriodo(e.target.value); setPagina(1) }}>
              <option value="todos">Todos os períodos</option>
              <option value="7">Próximos 7 dias</option>
              <option value="30">Próximos 30 dias</option>
              <option value="90">Próximos 90 dias</option>
            </select>
          </div>

          <div className={styles['mx-select-group']}>
            <span className={styles['mx-select-label']}>Cidade</span>
            <select className={styles['mx-select']} value={cidade} onChange={(e) => { setCidade(e.target.value); setPagina(1) }}>
              <option value="todas">Todas as cidades</option>
              {cidadesDisponiveis.map((c) => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>

          <div className={styles['mx-select-group']}>
            <span className={styles['mx-select-label']}>Ordenar por</span>
            <select className={styles['mx-select']} value={ordenarPor} onChange={(e) => { setOrdenarPor(e.target.value); setPagina(1) }}>
              <option value="recentes">Mais recentes</option>
              <option value="antigos">Mais antigos</option>
              <option value="confirmados">Mais confirmados</option>
            </select>
          </div>
        </div>

        <div className={styles['mx-toolbar']}>
          <div className={styles['mx-tabs']}>
            {tabs.map((t) => (
              <button
                key={t.key}
                className={cn(styles['mx-tab'], abaAtiva === t.key && styles.active)}
                onClick={() => { setAbaAtiva(t.key); setPagina(1) }}
              >
                {t.label}
              </button>
            ))}
          </div>

          {tipo === 'banda' && (
            <div className={styles['mx-view-toggle']}>
              <button className={cn(styles['mx-view-btn'], viewMode === 'calendario' && styles.active)} onClick={() => setViewMode('calendario')}>
                <svg viewBox="0 0 24 24">
                  <rect x="3" y="4" width="18" height="18" rx="2" />
                  <line x1="16" y1="2" x2="16" y2="6" />
                  <line x1="8" y1="2" x2="8" y2="6" />
                  <line x1="3" y1="10" x2="21" y2="10" />
                </svg>
                Calendário
              </button>
              <button className={cn(styles['mx-view-btn'], viewMode === 'lista' && styles.active)} onClick={() => setViewMode('lista')}>
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
          )}
        </div>

        {tipo === 'banda' && viewMode === 'calendario' ? (
          <div className={styles['mx-events-list']}>
            <div className={styles['mx-empty']}>Use a aba Calendário principal para visualizar em formato calendário.</div>
          </div>
        ) : (
          <div className={styles['mx-events-list']}>
            {eventosPaginados.map((ev) => (
              <div key={ev.id} className={styles['mx-event-item']}>
                {ev.image ? (
                  <img src={ev.image} alt={ev.titulo} className={styles['mx-event-thumb']} />
                ) : (
                  <div className={styles['mx-event-thumb-placeholder']}>
                    <svg viewBox="0 0 24 24">
                      <rect x="3" y="3" width="18" height="18" rx="2" />
                      <circle cx="8.5" cy="8.5" r="1.5" />
                      <polyline points="21 15 16 10 5 21" />
                    </svg>
                  </div>
                )}

                <div className={styles['mx-event-info']}>
                  <div className={styles['mx-event-name']}>{ev.titulo}</div>
                  <div className={styles['mx-event-subtitle']}>{ev.subtitulo}</div>
                  <div className={styles['mx-event-meta']}>
                    <span className={styles['mx-event-meta-item']}>
                      <svg viewBox="0 0 24 24">
                        <rect x="3" y="4" width="18" height="18" rx="2" />
                        <line x1="16" y1="2" x2="16" y2="6" />
                        <line x1="8" y1="2" x2="8" y2="6" />
                        <line x1="3" y1="10" x2="21" y2="10" />
                      </svg>
                      {ev.data}
                    </span>
                    <span className={styles['mx-event-meta-item']}>
                      <svg viewBox="0 0 24 24">
                        <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                        <circle cx="12" cy="10" r="3" />
                      </svg>
                      {ev.local}
                    </span>
                    {tipo === 'comunidade' && (
                      <span className={styles['mx-event-meta-item']}>
                        <svg viewBox="0 0 24 24">
                          <path d="M4 6a2 2 0 0 0-2 2v3a2 2 0 0 1 0 4v3a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-3a2 2 0 0 1 0-4V8a2 2 0 0 0-2-2z" />
                          <line x1="12" y1="6" x2="12" y2="20" />
                        </svg>
                        {ev.valor}
                      </span>
                    )}
                  </div>
                  <div className={styles['mx-event-confirmados']}>
                    <svg viewBox="0 0 24 24">
                      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                      <circle cx="9" cy="7" r="4" />
                      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                    </svg>
                    {ev.confirmados} confirmados
                  </div>
                </div>

                <div className={styles['mx-event-status']}>
                  {tipo === 'banda'
                    ? <StatusBadgeBanda status={ev.status} status_aceite={ev.status_aceite} />
                    : <StatusBadgeComunidade status={ev.status} />}
                  <span className={styles['mx-event-status-note']}>
                    {tipo === 'banda' && ev.status_aceite === 'pendente' && 'Convite recebido'}
                    {tipo === 'banda' && ev.status_aceite === 'recusado' && 'Convite recusado'}
                    {(tipo === 'comunidade' || ev.status_aceite === 'aceito') && ev.status === 'agendado' && (ev.diasFaltando > 0 ? `Faltam ${ev.diasFaltando} dias` : 'Evento hoje')}
                    {ev.status === 'finalizado' && `Realizado em ${ev.dataRealizacao}`}
                    {ev.status === 'cancelado' && `Cancelado em ${ev.dataCancelamento}`}
                  </span>
                </div>

                <div className={styles['mx-event-actions']}>
                  <Link to={detalhesLink(ev)} className={styles['mx-btn-ghost']}>Ver detalhes</Link>
                  {tipo === 'banda' && ev.status_aceite === 'pendente' && (
                    <>
                      <button
                        onClick={() => handleResponderContrato(ev.id, ev.contrato_id, 'aceito')}
                        className={cn(styles['mx-btn-solid'], styles['mx-btn-solid--success'])}
                      >
                        Aceitar Convite
                      </button>
                      <button
                        onClick={() => handleResponderContrato(ev.id, ev.contrato_id, 'recusado')}
                        className={cn(styles['mx-btn-solid'], styles['mx-btn-solid--danger'])}
                      >
                        Recusar
                      </button>
                    </>
                  )}
                  {tipo === 'comunidade' && ev.status === 'agendado' && (
                    <>
                      <button onClick={() => setEventoEditando({ id: ev.id })} className={styles['mx-btn-solid']}>
                        Editar
                      </button>
                      <button
                        onClick={() => handleFinalizar(ev.id)}
                        className={cn(styles['mx-btn-solid'], styles['mx-btn-solid--success'])}
                      >
                        Finalizar Evento
                      </button>
                      <button
                        onClick={() => handleCancelar(ev.id)}
                        className={cn(styles['mx-btn-solid'], styles['mx-btn-solid--danger'])}
                      >
                        Cancelar Evento
                      </button>
                    </>
                  )}
                </div>
              </div>
            ))}

            {eventosPaginados.length === 0 && (
              <div className={styles['mx-empty']}>Nenhum evento encontrado para os filtros selecionados.</div>
            )}
          </div>
        )}

        {totalPaginas > 1 && (
          <div className={styles['mx-pagination']}>
            <button className={styles['mx-page-arrow']} onClick={() => setPagina((p) => Math.max(1, p - 1))} disabled={pagina === 1}>
              <svg viewBox="0 0 24 24"><polyline points="15 18 9 12 15 6" /></svg>
            </button>
            {Array.from({ length: totalPaginas }, (_, i) => i + 1).map((n) => (
              <button key={n} className={cn(styles['mx-page-num'], pagina === n && styles.active)} onClick={() => setPagina(n)}>
                {n}
              </button>
            ))}
            <button className={styles['mx-page-arrow']} onClick={() => setPagina((p) => Math.min(totalPaginas, p + 1))} disabled={pagina === totalPaginas}>
              <svg viewBox="0 0 24 24"><polyline points="9 18 15 12 9 6" /></svg>
            </button>
          </div>
        )}
      </main>

      {tipo === 'comunidade' && eventoEditando && (
        <EditarEventoModal
          evento={eventoEditando}
          onFechar={() => setEventoEditando(null)}
          onSalvo={carregarEventos}
        />
      )}

      <Footer />
      <Snackbar
        open={snackbar.open}
        message={snackbar.message}
        onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
      />
    </div>
  )
}
