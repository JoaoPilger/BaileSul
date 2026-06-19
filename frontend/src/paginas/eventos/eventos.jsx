import React, { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { MapPin, Calendar, Trash2 } from 'lucide-react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadEvents, deleteEventById } from '../../utils/events'
import { cn } from '../../utils/cn'
import shared from '../../styles/shared.module.css'
import styles from './eventos.module.css'

function EventCard({ event, onDelete }) {
  const navigate = useNavigate()
  const date = new Date(event.date)
  const day = date.toLocaleDateString('pt-BR', { day: '2-digit' })
  const month = date.toLocaleDateString('pt-BR', { month: 'short' }).replace('.', '')

  return (
    <div className={styles['event-card']} onClick={() => navigate(`/eventos/${event.id}`)}>
      <div className={styles['event-card-img-wrap']}>
        <img src={event.image} alt={event.title} className={styles['event-card-img']} />
        <div className={styles['event-card-date-badge']}>
          <span className={styles['event-card-day']}>{day}</span>
          <span className={styles['event-card-month']}>{month}</span>
        </div>
        <div className={styles['event-card-price']}>{event.price}</div>
      </div>

      <div className={styles['event-card-body']}>
        <span className={styles['event-card-style']}>{event.style}</span>
        <h3 className={styles['event-card-title']}>{event.title}</h3>
        <div className={styles['event-card-location']}>
          <MapPin size={12} />
          {event.city}
        </div>
        <button
          className={styles['event-card-delete']}
          type="button"
          onClick={(e) => {
            e.stopPropagation()
            onDelete(event.id)
          }}
        >
          <Trash2 size={14} /> Apagar
        </button>
      </div>
    </div>
  )
}

export default function Eventos() {
  const [events, setEvents] = useState([])

  useEffect(() => {
    setEvents(loadEvents())
  }, [])

  function handleDelete(id) {
    deleteEventById(id)
    setEvents(loadEvents())
  }

  return (
    <>
      <Header />
      <main className={styles['events-page']}>
        <section className={styles['events-hero']}>
          <div className={styles['events-hero-content']}>
            <span className={styles['events-eyebrow']}>Eventos</span>
            <h1>Todos os eventos disponíveis</h1>
            <p>Veja os eventos que estão cadastrados e clique para ver todos os detalhes.</p>
          </div>
        </section>

        <section className={cn(shared.section, shared.sectionLight)}>
          <div className={shared.container}>
            <div className={shared.sectionHeader}>
              <div>
                <h2 className={shared.sectionTitle}>Eventos Cadastrados</h2>
                <p className={shared.sectionSub}>Toque no card para abrir a página de detalhes.</p>
              </div>
              <span className={styles['events-count']}>{events.length} eventos</span>
            </div>

            {events.length ? (
              <div className={shared.eventsGrid}>
                {events.map((event) => (
                  <EventCard key={event.id} event={event} onDelete={handleDelete} />
                ))}
              </div>
            ) : (
              <div className={shared.emptyState}>
                <Calendar size={36} />
                <p>Nenhum evento disponível</p>
                <span>Crie um evento para começar a usar</span>
              </div>
            )}
          </div>
        </section>
      </main>
      <Footer />
    </>
  )
}
