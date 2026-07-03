import React, { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { MapPin, Calendar } from 'lucide-react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadEvents } from '../../utils/events'
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
        <span className={styles['listing-card-label']}>{event.style}</span>
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
  const [events, setEvents] = useState([])
  const [displayed, setDisplayed] = useState([])
  const [query, setQuery] = useState('')
  const [dateFilter, setDateFilter] = useState('')
  const [timeFilter, setTimeFilter] = useState('')
  const [sortBy, setSortBy] = useState('recent')

  useEffect(() => {
    loadEvents().then((data) => {
      setEvents(data)
      setDisplayed(data)
    })
  }, [])

  useEffect(() => {
    let filtered = events.slice()

    const lower = query.trim().toLowerCase()
    if (lower) {
      filtered = filtered.filter((e) => e.title.toLowerCase().includes(lower))
    }

    if (dateFilter) {
      filtered = filtered.filter((e) => {
        const eventDate = new Date(e.date).toISOString().split('T')[0]
        return eventDate === dateFilter
      })
    }

    if (timeFilter) {
      filtered = filtered.filter((e) => (e.time || '00:00').startsWith(timeFilter))
    }

    if (sortBy === 'recent') {
      filtered.sort((a, b) => new Date(b.date) - new Date(a.date))
    } else if (sortBy === 'oldest') {
      filtered.sort((a, b) => new Date(a.date) - new Date(b.date))
    }

    setDisplayed(filtered)
  }, [query, dateFilter, timeFilter, sortBy, events])

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
                  <input
                    type="date"
                    value={dateFilter}
                    onChange={(e) => setDateFilter(e.target.value)}
                    className={styles['listing-select']}
                  />

                  <input
                    type="time"
                    value={timeFilter}
                    onChange={(e) => setTimeFilter(e.target.value)}
                    className={styles['listing-select']}
                  />

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
