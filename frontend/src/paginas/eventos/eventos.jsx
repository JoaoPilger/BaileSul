import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { MapPin, Calendar } from 'lucide-react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadEvents, formatTipoEvento } from '../../utils/events'
import shared from '../../styles/shared.module.css'
import styles from '../../styles/listings.module.css'

function ListingCard({ event }) {
  const navigate = useNavigate()
  const date = new Date(event.date)
  const day = date.toLocaleDateString('pt-BR', { day: '2-digit' })
  const month = date.toLocaleDateString('pt-BR', { month: 'short' }).replace('.', '')

  return (
    <div className={styles['listing-card']} onClick={() => navigate(`/eventos/${event.id}`)}>
      <div className={styles['listing-card-img-wrap']}>
        <img src={event.image} alt={event.title} className={styles['listing-card-img']} />
        <div className={styles['listing-card-badge']}>
          <span>{day}</span>
          <span>{month}</span>
        </div>
        <div className={styles['listing-card-price']}>{event.price}</div>
      </div>

      <div className={styles['listing-card-body']}>
        <span className={styles['listing-card-label']}>{formatTipoEvento(event.style)}</span>
        <h3 className={styles['listing-card-title']}>{event.title}</h3>
        <div className={styles['listing-card-meta']}>
          <MapPin size={14} />
          {event.city}
        </div>
      </div>
    </div>
  )
}

export default function Eventos() {
  const [searchParams] = useSearchParams()
  const [events, setEvents] = useState([])
  const [query, setQuery] = useState('')
  const [cidadeFiltro, setCidadeFiltro] = useState('')
  const [estiloFiltro, setEstiloFiltro] = useState(searchParams.get('style') || '')
  const [sortBy, setSortBy] = useState('recent')

  useEffect(() => {
    loadEvents().then((data) => {
      setEvents(data)
    })
  }, [])

  // Mantém o filtro em sincronia se o usuário navegar internamente para uma
  // URL com ?style= diferente enquanto o componente já está montado nesta
  // rota (ex.: link "Busque por Estilo" clicado a partir de /eventos).
  useEffect(() => {
    const styleParam = searchParams.get('style')
    // eslint-disable-next-line react-hooks/set-state-in-effect -- deriva o filtro da URL, não é estado local independente
    if (styleParam) setEstiloFiltro(styleParam)
  }, [searchParams])

  const cidades = useMemo(
    () => Array.from(new Set(events.map((e) => e.city).filter(Boolean))).sort(),
    [events],
  )

  const estilos = useMemo(
    () => Array.from(new Set(events.map((e) => e.style).filter(Boolean))).sort(),
    [events],
  )

  const displayed = useMemo(() => {
    let filtered = events.slice()

    const lower = query.trim().toLowerCase()
    if (lower) {
      filtered = filtered.filter((e) => e.title.toLowerCase().includes(lower))
    }

    if (cidadeFiltro) {
      filtered = filtered.filter((e) => e.city === cidadeFiltro)
    }

    if (estiloFiltro) {
      filtered = filtered.filter((e) => e.style === estiloFiltro)
    }

    if (sortBy === 'recent') {
      filtered.sort((a, b) => new Date(b.date) - new Date(a.date))
    } else if (sortBy === 'oldest') {
      filtered.sort((a, b) => new Date(a.date) - new Date(b.date))
    }

    return filtered
  }, [query, cidadeFiltro, estiloFiltro, sortBy, events])

  return (
    <>
      <Header />
      <main className={styles['listing-page']}>
        <section className={styles['listing-hero']}>
          <div className={styles['listing-hero-content']}>
            <h1>Todos os eventos disponíveis</h1>
            <p>Veja os eventos cadastrados e encontre os melhores da sua região.</p>
          </div>
        </section>

        <section className={shared.section}>
          <div className={shared.container}>
            <div className={shared.sectionHeader}>
              <div>
                <h2 className={shared.sectionTitle}>Eventos Cadastrados</h2>
              </div>
              <span className={styles['listing-count']}>{displayed.length} eventos</span>
            </div>

            <div style={{ position: 'relative' }}>
              <div className={styles['listing-filters']}>
                <input
                  type="text"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  className={styles['listing-search']}
                  placeholder="Buscar evento..."
                />

                <div className={styles['listing-filters-group']}>
                  <select value={cidadeFiltro} onChange={(e) => setCidadeFiltro(e.target.value)} className={styles['listing-select']}>
                    <option value="">Todas as cidades</option>
                    {cidades.map((c) => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>

                  <select value={estiloFiltro} onChange={(e) => setEstiloFiltro(e.target.value)} className={styles['listing-select']}>
                    <option value="">Todos os tipos</option>
                    {estilos.map((s) => (
                      <option key={s} value={s}>{formatTipoEvento(s)}</option>
                    ))}
                  </select>

                  <select value={sortBy} onChange={(e) => setSortBy(e.target.value)} className={styles['listing-select']}>
                    <option value="recent">Mais recente</option>
                    <option value="oldest">Mais antigo</option>
                  </select>
                </div>
              </div>
            </div>

            {displayed.length ? (
              <div className={styles['listing-grid']}>
                {displayed.map((event) => (
                  <ListingCard key={event.id} event={event} />
                ))}
              </div>
            ) : (
              <div className={styles['listing-empty']}>
                <Calendar size={48} />
                <p>Nenhum evento encontrado</p>
                <span>Tente ajustar seus filtros</span>
              </div>
            )}
          </div>
        </section>
      </main>
      <Footer />
    </>
  )
}
