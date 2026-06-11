import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Search, MapPin, ArrowRight, Calendar } from 'lucide-react';
import Header from '../../components/header/Header';
import Footer from '../../components/footer/Footer';
import { loadEvents } from '../../utils/events';
import './home.css';

const STYLES = [
  { value: 'sertanejo', label: 'Sertanejo' , desc: 'Duplas e modão' },
  { value: 'forro',     label: 'Forró' , desc: 'Duplas e modão' },
  { value: 'pagode',    label: 'Pagode' , desc: 'Samba de raiz' },
  { value: 'rock',      label: 'Bailão' , desc: 'Duplas e modão' },
  { value: 'eletronica',label: 'Bandinha' , desc: 'BPMs infinitos' },
  { value: 'gaucha',    label: 'Gaúcha' , desc: 'Chamamé e ginga' },
  { value: 'vanera',    label: 'Vanera' , desc: 'Ritmo do sul' },
  { value: 'funk',      label: 'Arrocha', desc: 'Duplas e modão' },
];

function HeroSection() {
  const [visible, setVisible] = useState(false);
  useEffect(() => { setTimeout(() => setVisible(true), 80); }, []);

  return (
    <section className="hero">
      <div className="hero-bg">
        <img
          src="https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=1400&q=80"
          alt="Baile dançando"
          className="hero-img"
        />
        <div className="hero-overlay" />
      </div>
      <div className="orb orb-1" />
      <div className="orb orb-2" />

      <div className="hero-inner">
        <div className={`hero-content ${visible ? 'hero-content--visible' : ''}`}>
          <h1 className="hero-title">
            Descubra os<br />
            <span className="hero-title-accent">Melhores Bailes</span><br />
            da Região
          </h1>

          <p className="hero-sub">
            Encontre eventos, bandas e comunidades. Seu hub completo para a vida noturna da AMAUC.
          </p>

          <div className="hero-actions">
            <Link to="/eventos" className="btn btn-primary">
              <Search size={16} />
              Explorar Eventos
            </Link>
            <Link to="/mapa" className="btn btn-outline-inv">
              <MapPin size={16} />
              Ver no Mapa
            </Link>
          </div>

          <div className="hero-stats">
            {[
              { value: '50+', label: 'Eventos'  },
              { value: '30+', label: 'Bandas'   },
              { value: '13',  label: 'Cidades'  },
            ].map((s) => (
              <div key={s.label} className="hero-stat">
                <span className="hero-stat-value">{s.value}</span>
                <span className="hero-stat-label">{s.label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

function EventCard({ event, index }) {
  const navigate = useNavigate();
  const date  = new Date(event.date);
  const day   = date.toLocaleDateString('pt-BR', { day: '2-digit' });
  const month = date.toLocaleDateString('pt-BR', { month: 'short' }).replace('.', '');

  return (
    <div
      className="event-card"
      style={{ animationDelay: `${index * 80}ms` }}
      onClick={() => navigate(`/eventos/${event.id}`)}
    >
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
      </div>
    </div>
  );
}

function FeaturedEvents({ events, isLoading }) {
  return (
    <section className="section section--light">
      <div className="container">
        <div className="section-header">
          <div>
            <h2 className="section-title">Próximos Eventos</h2>
            <p className="section-sub">Os melhores bailes chegando na região</p>
          </div>
          <Link to="/eventos" className="link-all">
            Ver todos <ArrowRight size={14} />
          </Link>
        </div>

        {isLoading ? (
          <div className="events-grid">
            {[1, 2, 3].map((i) => (
              <div key={i} className="skeleton-card">
                <div className="skeleton-img" />
                <div className="skeleton-body">
                  <div className="skeleton-line" style={{ width: '70%' }} />
                  <div className="skeleton-line" style={{ width: '50%' }} />
                  <div className="skeleton-line" style={{ width: '90%' }} />
                </div>
              </div>
            ))}
          </div>
        ) : events.length > 0 ? (
          <div className="events-grid">
            {events.slice(0, 6).map((e, i) => (
              <EventCard key={e.id} event={e} index={i} />
            ))}
          </div>
        ) : (
          <div className="empty-state">
            <Calendar size={36} />
            <p>Nenhum evento encontrado</p>
            <span>Seja o primeiro a criar um evento!</span>
          </div>
        )}

        <div className="mobile-see-all">
          <Link to="/eventos" className="btn btn-outline">
            Ver todos os eventos <ArrowRight size={14} />
          </Link>
        </div>
      </div>
    </section>
  );
}

function StylesSection() {
  return (
    <section className="styles-section">
      <div className="styles-deco-line" />

      <div className="container">
        <div className="styles-header">
          <div className="styles-header-left">
            <span className="styles-eyebrow">Filtre pelo seu ritmo</span>
            <h2 className="styles-title">Busque por Estilo</h2>
          </div>
          <p className="styles-subtitle">
            Cada ritmo tem sua alma.<br />Encontre o evento que faz seu corpo mexer.
          </p>
        </div>

        <div className="styles-row">
          {STYLES.map((style, i) => (
            <Link
              key={style.value}
              to={`/eventos?style=${style.value}`}
              className="style-pill"
              style={{ animationDelay: `${i * 45}ms` }}
            >
              <span className="style-pill-emoji">{style.emoji}</span>
              <div className="style-pill-text">
                <span className="style-pill-label">{style.label}</span>
                <span className="style-pill-desc">{style.desc}</span>
              </div>
              <ArrowRight size={14} className="style-pill-arrow" />
            </Link>
          ))}
        </div>
      </div>

      <div className="styles-deco-line" />
    </section>
  );
}

export default function Home() {
  const [events, setEvents] = useState([]);
  const [isLoading] = useState(false);

  useEffect(() => {
    setEvents(loadEvents())
  }, []);

  return (
    <>
      <Header />
      <div className="page-home">
        <HeroSection />
        <FeaturedEvents events={events} isLoading={isLoading} />
        <StylesSection />
        <Footer />
      </div>
    </>
  );
}
