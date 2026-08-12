import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Search, MapPin, ArrowRight, Calendar } from 'lucide-react';
import Header from '../../components/header/Header';
import Footer from '../../components/footer/Footer';
import { loadEvents } from '../../utils/events';
import { cn } from '../../utils/cn';
import shared from '../../styles/shared.module.css';
import styles from './home.module.css';

const STYLES = [
  { value: 'gaucha', label: 'Gaúcha', desc: 'Chamamé e ginga', emoji: '🪗' },
  { value: 'vanera',  label: 'Vanera', desc: 'Ritmo do sul',    emoji: '💃' },
];

function HeroSection() {
  const [visible, setVisible] = useState(false);
  useEffect(() => { setTimeout(() => setVisible(true), 80); }, []);

  return (
    <section className={styles.hero}>
      <div className={styles.heroBg}>
        <img
          src="https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=1400&q=80"
          alt="Baile dançando"
          className={styles.heroImg}
        />
        <div className={styles.heroOverlay} />
      </div>
      <div className={cn(styles.orb, styles.orb1)} />
      <div className={cn(styles.orb, styles.orb2)} />

      <div className={styles.heroInner}>
        <div className={cn(styles.heroContent, visible && styles.heroContentVisible)}>
          <h1 className={styles.heroTitle}>
            Descubra os<br />
            <span className={styles.heroTitleAccent}>Melhores Bailes</span><br />
            da Região
          </h1>

          <p className={styles.heroSub}>
            Encontre eventos, bandas e comunidades. Seu hub completo para a vida noturna da AMAUC.
          </p>

          <div className={styles.heroActions}>
            <Link to="/eventos" className={cn(shared.btn, shared.btnPrimary)}>
              <Search size={16} />
              Explorar Eventos
            </Link>
          </div>

          <div className={styles.heroStats}>
            {[
              { value: '50+', label: 'Eventos'  },
              { value: '30+', label: 'Bandas'   },
              { value: '13',  label: 'Cidades'  },
            ].map((s) => (
              <div key={s.label} className={styles.heroStat}>
                <span className={styles.heroStatValue}>{s.value}</span>
                <span className={styles.heroStatLabel}>{s.label}</span>
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
      className={shared.eventCard}
      style={{ animationDelay: `${index * 80}ms` }}
      onClick={() => navigate(`/eventos/${event.id}`)}
    >
      <div className={shared.eventCardImgWrap}>
        <img src={event.image} alt={event.title} className={shared.eventCardImg} />
        <div className={shared.eventCardDateBadge}>
          <span className={shared.eventCardDay}>{day}</span>
          <span className={shared.eventCardMonth}>{month}</span>
        </div>
        <div className={shared.eventCardPrice}>{event.price}</div>
      </div>
      <div className={shared.eventCardBody}>
        <span className={shared.eventCardStyle}>{event.style}</span>
        <h3 className={shared.eventCardTitle}>{event.title}</h3>
        <div className={shared.eventCardLocation}>
          <MapPin size={12} />
          {event.city}
        </div>
      </div>
    </div>
  );
}

function FeaturedEvents({ events, isLoading }) {
  return (
    <section className={cn(shared.section, shared.sectionLight)}>
      <div className={shared.container}>
        <div className={shared.sectionHeader}>
          <div>
            <h2 className={shared.sectionTitle}>Próximos Eventos</h2>
            <p className={shared.sectionSub}>Os melhores bailes chegando na região</p>
          </div>
          <Link to="/eventos" className={shared.linkAll}>
            Ver todos <ArrowRight size={14} />
          </Link>
        </div>

        {isLoading ? (
          <div className={shared.eventsGrid}>
            {[1, 2, 3].map((i) => (
              <div key={i} className={shared.skeletonCard}>
                <div className={shared.skeletonImg} />
                <div className={shared.skeletonBody}>
                  <div className={shared.skeletonLine} style={{ width: '70%' }} />
                  <div className={shared.skeletonLine} style={{ width: '50%' }} />
                  <div className={shared.skeletonLine} style={{ width: '90%' }} />
                </div>
              </div>
            ))}
          </div>
        ) : events.length > 0 ? (
          <div className={shared.eventsGrid}>
            {events.slice(0, 6).map((e, i) => (
              <EventCard key={e.id} event={e} index={i} />
            ))}
          </div>
        ) : (
          <div className={shared.emptyState}>
            <Calendar size={36} />
            <p>Nenhum evento encontrado</p>
            <span>Seja o primeiro a criar um evento!</span>
          </div>
        )}

        <div className={shared.mobileSeeAll}>
          <Link to="/eventos" className={cn(shared.btn, shared.btnOutline)}>
            Ver todos os eventos <ArrowRight size={14} />
          </Link>
        </div>
      </div>
    </section>
  );
}

function StylesSection() {
  return (
    <section className={styles.stylesSection}>
      <div className={styles.stylesDecoLine} />

      <div className={shared.container}>
        <div className={styles.stylesHeader}>
          <div className={styles.stylesHeaderLeft}>
            <span className={styles.stylesEyebrow}>Filtre pelo seu ritmo</span>
            <h2 className={styles.stylesTitle}>Busque por Estilo</h2>
          </div>
          <p className={styles.stylesSubtitle}>
            Cada ritmo tem sua alma.<br />Encontre o evento que faz seu corpo mexer.
          </p>
        </div>

        <div className={styles.stylesRow}>
          {STYLES.map((style, i) => (
            <Link
              key={style.value}
              to={`/eventos?style=${style.value}`}
              className={styles.stylePill}
              style={{ animationDelay: `${i * 45}ms` }}
            >
              <span className={styles.stylePillEmoji}>{style.emoji}</span>
              <div className={styles.stylePillText}>
                <span className={styles.stylePillLabel}>{style.label}</span>
                <span className={styles.stylePillDesc}>{style.desc}</span>
              </div>
              <ArrowRight size={14} className={styles.stylePillArrow} />
            </Link>
          ))}
        </div>
      </div>

      <div className={styles.stylesDecoLine} />
    </section>
  );
}

export default function Home() {
  const [events, setEvents] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadEvents()
      .then((data) => {
        setEvents(data);
        setIsLoading(false);
      })
      .catch(() => {
        setIsLoading(false);
      });
  }, []);

  return (
    <>
      <Header />
      <div className={styles.pageHome}>
        <HeroSection />
        <FeaturedEvents events={events} isLoading={isLoading} />
        <StylesSection />
        <Footer />
      </div>
    </>
  );
}
