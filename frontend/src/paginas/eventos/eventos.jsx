import React, { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { MapPin, ArrowRight, Calendar, Trash2 } from 'lucide-react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadEvents, deleteEventById } from '../../utils/events'
import './eventos.css'

function EventCard({ event, onDelete }) {
  const navigate = useNavigate()
  const date = new Date(event.date)
  const day = date.toLocaleDateString('pt-BR', { day: '2-digit' })
  const month = date.toLocaleDateString('pt-BR', { month: 'short' }).replace('.', '')

  return (
    <div className="event-card" onClick={() => navigate(`/eventos/${event.id}`)}>
      <div className="event-card-img-wrap">
        <img src={event.image} alt={event.title} className="event-card-img" />
        <div className="event-card-date-badge">
          <span className="event-card-day">{day}</span>
          <span className="event-card-month">{month}</span>
        </div>
        <div className="event-card-price">{event.price}</div>
      </div>

      <div className="event-card-body">
        <span className="event-card-style">{event.style}</span>
        <h3 className="event-card-title">{event.title}</h3>
        <div className="event-card-location">
          <MapPin size={12} />
          {event.city}
        </div>
        <button
          className="event-card-delete"
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
      <main className="events-page">
        <section className="events-hero">
          <div className="events-hero-content">
            <span className="events-eyebrow">Eventos</span>
            <h1>Todos os eventos disponíveis</h1>
            <p>Veja os eventos que estão cadastrados e clique para ver todos os detalhes.</p>
          </div>
        </section>

        <section className="section section--light">
          <div className="container">
            <div className="section-header">
              <div>
                <h2 className="section-title">Eventos Cadastrados</h2>
                <p className="section-sub">Toque no card para abrir a página de detalhes.</p>
              </div>
              <span className="events-count">{events.length} eventos</span>
            </div>

            {events.length ? (
              <div className="events-grid">
                {events.map((event) => (
                  <EventCard key={event.id} event={event} onDelete={handleDelete} />
                ))}
              </div>
            ) : (
              <div className="empty-state">
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
