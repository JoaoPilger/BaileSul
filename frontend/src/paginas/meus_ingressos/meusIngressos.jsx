import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, ArrowLeft, Calendar, Clock, MapPin } from 'lucide-react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { useAuth } from '../../contexts/AuthContext'
import { cn } from '../../utils/cn'
import api from '../../services/api'
import styles from './meusIngressos.module.css'

const DEFAULT_IMAGE =
  'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=200&q=80'

const TIPOS_EVENTO = [
  { value: '',                 label: 'Todos os tipos' },
  { value: 'musical_gaucha',   label: 'Musical (Gaúcha)' },
  { value: 'musical_bandinha', label: 'Musical (Bandinha)' },
  { value: 'almoco',           label: 'Almoço' },
  { value: 'bingo',            label: 'Bingo' },
  { value: 'expos',            label: 'Expos' },
  { value: 'futebol',          label: 'Futebol' },
]

function formatDate(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  if (Number.isNaN(d.getTime())) return dateStr
  return d.toLocaleDateString('pt-BR')
}

function formatTime(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  if (Number.isNaN(d.getTime())) return ''
  return d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}

function useDebouncedValue(value, delay = 300) {
  const [debounced, setDebounced] = useState(value)
  useEffect(() => {
    const t = setTimeout(() => setDebounced(value), delay)
    return () => clearTimeout(t)
  }, [value, delay])
  return debounced
}

function IngressoCard({ reserva, onVerDetalhes }) {
  const isConfirmado = reserva.status_pagamento === 'confirmado'
  const cidade = [reserva.cidade, reserva.estado].filter(Boolean).join(', ')

  return (
    <div className={styles['mi-card']}>
      <img
        src={reserva.foto_capa_url || DEFAULT_IMAGE}
        alt={reserva.evento}
        className={styles['mi-card-img']}
      />
      <div className={styles['mi-card-body']}>
        <div className={styles['mi-card-title']}>{reserva.evento}</div>
        <div className={styles['mi-card-sub']}>
          {reserva.banda || reserva.comunidade || 'Banda/Artista'}
        </div>
        <div className={styles['mi-card-meta']}>
          <span
            className={cn(
              styles['mi-card-badge'],
              styles[isConfirmado ? 'confirmado' : 'pendente'],
            )}
          >
            {isConfirmado ? 'Pago' : 'Reservado'}
          </span>
          {reserva.data_inicio && (
            <span>
              <Calendar />
              {formatDate(reserva.data_inicio)}
            </span>
          )}
          {reserva.data_inicio && (
            <span>
              <Clock />
              {formatTime(reserva.data_inicio) || '00:00'}
            </span>
          )}
          {cidade && (
            <span>
              <MapPin />
              {cidade}
            </span>
          )}
        </div>
      </div>
      <button
        type="button"
        className={styles['mi-card-action']}
        onClick={() => onVerDetalhes(reserva.evento_id)}
      >
        Ver detalhes
      </button>
    </div>
  )
}

export default function MeusIngressosPage() {
  const navigate = useNavigate()
  const { token } = useAuth()

  const [reservas, setReservas] = useState([])
  const [isLoading, setIsLoading] = useState(true)
  const [erro, setErro] = useState('')

  const [statusFiltro, setStatusFiltro] = useState('todos') // todos | pendente | confirmado
  const [tipoFiltro, setTipoFiltro] = useState('')
  const [busca, setBusca] = useState('')
  const buscaDebounced = useDebouncedValue(busca, 300)

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [])

  useEffect(() => {
    let cancelled = false
    setIsLoading(true)
    setErro('')

    api
      .get('/reservas/minhas', {
        headers: { Authorization: `Bearer ${token}` },
      })
      .then(({ data }) => {
        if (!cancelled) setReservas(Array.isArray(data) ? data : [])
      })
      .catch(() => {
        if (!cancelled) setErro('Não foi possível carregar seus ingressos.')
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false)
      })

    return () => {
      cancelled = true
    }
  }, [token])

  const filtradas = useMemo(() => {
    const termo = buscaDebounced.trim().toLowerCase()

    return reservas.filter((r) => {
      if (tipoFiltro && r.tipo_evento !== tipoFiltro) return false

      if (termo) {
        const titulo = (r.evento || '').toLowerCase()
        const dataFmt = formatDate(r.data_inicio).toLowerCase()
        const dataIso = (r.data_inicio || '').toLowerCase()
        const matches =
          titulo.includes(termo) ||
          dataFmt.includes(termo) ||
          dataIso.includes(termo)
        if (!matches) return false
      }

      return true
    })
  }, [reservas, tipoFiltro, buscaDebounced])

  const comprados = filtradas.filter((r) => r.status_pagamento === 'confirmado')
  const reservados = filtradas.filter((r) => r.status_pagamento === 'pendente')

  const mostrarComprados = statusFiltro === 'todos' || statusFiltro === 'confirmado'
  const mostrarReservados = statusFiltro === 'todos' || statusFiltro === 'pendente'

  const handleVerDetalhes = (eventoId) => navigate(`/eventos/${eventoId}`)

  return (
    <>
      <Header />
      <main className={styles['mi-page']}>
        <div className={styles['mi-body']}>

          <h1 className={styles['mi-title']}>Meus ingressos:</h1>

          <div className={styles['mi-toolbar']}>
            <div className={styles['mi-search']}>
              <Search />
              <input
                type="text"
                placeholder="Buscar por evento ou data..."
                value={busca}
                onChange={(e) => setBusca(e.target.value)}
              />
            </div>

            <select
              className={styles['mi-select']}
              value={tipoFiltro}
              onChange={(e) => setTipoFiltro(e.target.value)}
            >
              {TIPOS_EVENTO.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>

            <div className={styles['mi-filters']}>
              <button
                type="button"
                className={cn(
                  styles['mi-filter-btn'],
                  statusFiltro === 'todos' && styles.active,
                )}
                onClick={() => setStatusFiltro('todos')}
              >
                Todos
              </button>
              <button
                type="button"
                className={cn(
                  styles['mi-filter-btn'],
                  statusFiltro === 'pendente' && styles.active,
                )}
                onClick={() => setStatusFiltro('pendente')}
              >
                Reservados
              </button>
              <button
                type="button"
                className={cn(
                  styles['mi-filter-btn'],
                  statusFiltro === 'confirmado' && styles.active,
                )}
                onClick={() => setStatusFiltro('confirmado')}
              >
                Pagos
              </button>
            </div>
          </div>

          {isLoading && <div className={styles['mi-loading']}>Carregando seus ingressos...</div>}

          {!isLoading && erro && <div className={styles['mi-empty']}>{erro}</div>}

          {!isLoading && !erro && (
            <>
              {mostrarComprados && (
                <section className={styles['mi-section']}>
                  <h2 className={styles['mi-section-title']}>Comprado(s)</h2>
                  {comprados.length > 0 ? (
                    <div className={styles['mi-cards']}>
                      {comprados.map((r) => (
                        <IngressoCard key={r.id} reserva={r} onVerDetalhes={handleVerDetalhes} />
                      ))}
                    </div>
                  ) : (
                    <div className={styles['mi-empty']}>Nenhum ingresso pago ainda.</div>
                  )}
                </section>
              )}

              {mostrarReservados && (
                <section className={styles['mi-section']}>
                  <h2 className={styles['mi-section-title']}>Reservado(s)</h2>
                  {reservados.length > 0 ? (
                    <div className={styles['mi-cards']}>
                      {reservados.map((r) => (
                        <IngressoCard key={r.id} reserva={r} onVerDetalhes={handleVerDetalhes} />
                      ))}
                    </div>
                  ) : (
                    <div className={styles['mi-empty']}>Nenhuma reserva pendente.</div>
                  )}
                </section>
              )}
            </>
          )}
        </div>
      </main>
      <Footer />
    </>
  )
}
