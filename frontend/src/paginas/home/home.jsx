import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import {
  Search, MapPin, ArrowRight, Music,
  Calendar, Menu, X, User, Plus, ListMusic, Ticket,
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import './home.css';

function getNavConfig(tipo) {
  const base = [
    { to: '/',        label: 'Início',  icon: Music },
    { to: '/eventos', label: 'Eventos', icon: Calendar },
    { to: '/mapa',    label: 'Mapa',    icon: MapPin },
  ];

  if (tipo === 'pessoal') {
    base.push({ to: '/meus-ingressos', label: 'Meus Ingressos', icon: Ticket });
  } else {
    base.push({ to: '/meus-eventos', label: 'Meus Eventos', icon: ListMusic });
  }

  return {
    links: base,
    podeCriarEvento: !tipo || tipo === 'comunidade',
  };
}

const MOCK_EVENTS = [
  {
    id: 1,
    title: 'Baile do Rancho',
    date: '2025-06-14',
    city: 'Concórdia',
    style: 'sertanejo',
    image: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80',
    price: 'R$ 30',
  },
  {
    id: 2,
    title: 'Forró na Praça',
    date: '2025-06-21',
    city: 'Seara',
    style: 'forro',
    image: 'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=600&q=80',
    price: 'Grátis',
  },
  {
    id: 3,
    title: 'Noite Gaúcha',
    date: '2025-06-28',
    city: 'Peritiba',
    style: 'gaucha',
    image: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=600&q=80',
    price: 'R$ 20',
  },
];

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

function Navbar() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [scrolled, setScrolled]     = useState(false);
  const location = useLocation();
  const { usuario, isAuthenticated } = useAuth();
  const { links, podeCriarEvento } = getNavConfig(usuario?.tipo);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 10);
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const isActive = (path) => location.pathname === path;
  const contaLink = isAuthenticated ? '/perfil' : '/login';
  const contaLabel = isAuthenticated ? 'Minha conta' : 'Entrar';

  return (
    <nav className={`navbar ${scrolled ? 'navbar--scrolled' : ''}`}>
      <div className="navbar-shell">
        <div className="navbar-zone navbar-zone--logo">
          <Link to="/" className="navbar-logo" aria-label="BaileSul">
            <img
              src="/imagens/BaileSul.png"
              alt="BaileSul"
              className="navbar-logo-img"
              decoding="async"
            />
          </Link>
        </div>

        <div className="navbar-zone navbar-zone--nav">
          {links.map(({ to, label, icon: NavIcon }) => (
            <Link
              key={to}
              to={to}
              className={`navbar-link ${isActive(to) ? 'navbar-link--active' : ''}`}
            >
              <NavIcon size={17} strokeWidth={2} aria-hidden />
              <span className="navbar-link-text">{label}</span>
            </Link>
          ))}
        </div>

        <div className="navbar-zone navbar-zone--actions">
          <div className="navbar-actions-desktop">
            {podeCriarEvento && (
              <Link to="/criar-evento" className="btn-nav-create">
                <Plus size={15} strokeWidth={2} aria-hidden />
                <span>Criar Evento</span>
              </Link>
            )}
            <Link to={contaLink} className="navbar-icon-btn navbar-login-btn" aria-label={contaLabel}>
              <User size={20} strokeWidth={2} />
            </Link>
          </div>
          <button
            type="button"
            className="navbar-hamburger"
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label="Menu"
          >
            {mobileOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>
      </div>

      <div className={`navbar-mobile ${mobileOpen ? 'navbar-mobile--open' : ''}`}>
        {links.map(({ to, label, icon: NavIcon }) => (
          <Link
            key={to}
            to={to}
            className={`navbar-mobile-link ${isActive(to) ? 'navbar-mobile-link--active' : ''}`}
            onClick={() => setMobileOpen(false)}
          >
            <NavIcon size={18} strokeWidth={2} aria-hidden />
            <span className="navbar-link-text">{label}</span>
          </Link>
        ))}
        <div className="navbar-mobile-divider" />
        {podeCriarEvento && (
          <Link to="/criar-evento" className="btn-nav-create btn-nav-create--mobile" onClick={() => setMobileOpen(false)}>
            <Plus size={15} strokeWidth={2} aria-hidden />
            <span>Criar Evento</span>
          </Link>
        )}
        <Link to={contaLink} className="navbar-mobile-link" onClick={() => setMobileOpen(false)}>
          <User size={18} strokeWidth={2} aria-hidden />
          <span>{contaLabel}</span>
        </Link>
      </div>
    </nav>
  );
}

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
  const date  = new Date(event.date);
  const day   = date.toLocaleDateString('pt-BR', { day: '2-digit' });
  const month = date.toLocaleDateString('pt-BR', { month: 'short' }).replace('.', '');

  return (
    <Link
      to={`/eventos/${event.id}`}
      className="event-card"
      style={{ animationDelay: `${index * 80}ms` }}
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
    </Link>
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

function FooterSection() {
  const { usuario } = useAuth();
  const { links, podeCriarEvento } = getNavConfig(usuario?.tipo);
  const contaLink = usuario ? '/perfil' : '/login';

  return (
    <footer className="footer">
      <div className="container footer-grid">
        <div className="footer-brand">
          <Link to="/" className="footer-logo-link" aria-label="BaileSul">
            <img
              src="/imagens/BaileSul.png"
              alt="BaileSul"
              className="footer-logo-img"
              decoding="async"
            />
          </Link>
          <p className="footer-tagline">
            A plataforma de eventos da região AMAUC. Conectando bandas, comunidades e público.
          </p>
        </div>

        <div>
          <h4 className="footer-heading">Navegação</h4>
          <nav className="footer-nav">
            <Link to="/eventos">Eventos</Link>
            <Link to="/calendario">Calendário</Link>
            <Link to="/mapa">Mapa</Link>
            {links
              .filter((l) => l.to.startsWith('/meus-'))
              .map((l) => (
                <Link key={l.to} to={l.to}>{l.label}</Link>
              ))}
            {podeCriarEvento && <Link to="/criar-evento">Criar Evento</Link>}
            <Link to={contaLink}>Perfil</Link>
          </nav>
        </div>

        <div>
          <h4 className="footer-heading">Região AMAUC</h4>
          <p className="footer-region">
            <MapPin size={13} />
            13 municípios · Santa Catarina
          </p>
        </div>
      </div>

      <div className="footer-bottom">
        <span>© BaileSul – Todos os direitos reservados.</span>
      </div>
    </footer>
  );
}

export default function Home() {
  const [events]    = useState(MOCK_EVENTS);
  const [isLoading] = useState(false);

  return (
    <>
      <Navbar />
      <div className="page-home">
        <HeroSection />
        <FeaturedEvents events={events} isLoading={isLoading} />
        <StylesSection />
        <FooterSection />
      </div>
    </>
  );
}
