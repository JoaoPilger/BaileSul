import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { User, ChevronLeft, ChevronRight, Plus, CalendarDays, MapPin } from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'
import './calendario.css'

const WEEKDAYS = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB']
const MONTHS = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
]

function getDaysInMonth(year, month) {
  return new Date(year, month + 1, 0).getDate()
}

function getFirstWeekday(year, month) {
  return new Date(year, month, 1).getDay()
}

function pad(n) {
  return String(n).padStart(2, '0')
}

const MOCK_EVENTS = {
  '14/05/2026': [{
    id: 1,
    title: 'Baile do Rancho',
    city: 'Concórdia',
    style: 'Sertanejo',
    price: 'R$ 30',
    image: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&q=80',
  }],
  '21/05/2026': [
    {
      id: 2,
      title: 'Forró na Praça',
      city: 'Seara',
      style: 'Forró',
      price: 'Grátis',
      image: 'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=400&q=80',
    },
    {
      id: 3,
      title: 'Noite Gaúcha',
      city: 'Peritiba',
      style: 'Gaúcha',
      price: 'R$ 20',
      image: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400&q=80',
    },
  ],
  '07/06/2026': [{
    id: 4,
    title: 'Bailão do Sul',
    city: 'Concórdia',
    style: 'Bailão',
    price: 'R$ 25',
    image: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&q=80',
  }],
}


function formatKey(day, month, year) {
  return `${pad(day)}/${pad(month + 1)}/${year}`
}

export default function Calendario() {
  const today = new Date()
  const { usuario, isAuthenticated } = useAuth()
  const podeCriarEvento = !usuario?.tipo || usuario.tipo === 'comunidade' || usuario.tipo === 'banda'
  const contaLink = isAuthenticated ? '/perfil' : '/login'

  const footerLinks = [
    { to: '/eventos', label: 'Eventos' },
    { to: '/calendario', label: 'Calendário' },
    { to: '/mapa', label: 'Mapa' },
    { to: '/meus-eventos', label: 'Meus Eventos' },
    { to: '/criar-evento', label: 'Criar Evento' },
    { to: contaLink, label: 'Perfil' },
  ]

  const [view, setView] = useState({
    year: today.getFullYear(),
    month: today.getMonth(),
  })
  const [selected, setSelected] = useState({
    day: today.getDate(),
    month: today.getMonth(),
    year: today.getFullYear(),
  })

  const [eventsMap, setEventsMap] = useState(MOCK_EVENTS)

  useEffect(() => {
    try {
      const raw = localStorage.getItem('bailesul_events')
      if (!raw) return
      const parsed = JSON.parse(raw)
      // start with MOCK_EVENTS then merge saved events (saved events appear first)
      const map = { ...MOCK_EVENTS }
      parsed.forEach((ev) => {
        if (!ev.date) return
        const d = new Date(ev.date)
        const key = formatKey(d.getDate(), d.getMonth(), d.getFullYear())
        if (!map[key]) map[key] = []
        map[key].unshift(ev)
      })
      setEventsMap(map)
    } catch (e) {
      // ignore parse errors
    }
  }, [])

  const { year: viewYear, month: viewMonth } = view
  const daysInMonth = getDaysInMonth(viewYear, viewMonth)
  const firstWeekday = getFirstWeekday(viewYear, viewMonth)
  const monthTitle = `${MONTHS[viewMonth]} de ${viewYear}`

  function goToMonth(delta) {
    setView((current) => {
      let nextMonth = current.month + delta
      let nextYear = current.year
      if (nextMonth < 0) {
        nextMonth = 11
        nextYear -= 1
      } else if (nextMonth > 11) {
        nextMonth = 0
        nextYear += 1
      }
      return { year: nextYear, month: nextMonth }
    })
  }

  const selectedKey = formatKey(selected.day, selected.month, selected.year)
  const events = eventsMap[selectedKey] || []

  const eventDates = new Set(
    Object.keys(eventsMap)
      .filter((k) => {
        const [, m, y] = k.split('/').map(Number)
        return m - 1 === viewMonth && y === viewYear
      })
      .map((k) => parseInt(k.split('/')[0], 10)),
  )

  const isToday = (d) =>
    d === today.getDate()
    && viewMonth === today.getMonth()
    && viewYear === today.getFullYear()

  const isSelected = (d) =>
    d === selected.day
    && viewMonth === selected.month
    && viewYear === selected.year

  const cells = []
  for (let i = 0; i < firstWeekday; i++) cells.push(null)
  for (let d = 1; d <= daysInMonth; d++) cells.push(d)

  const selectedDate = new Date(selected.year, selected.month, selected.day)
  const dateLabel = selectedDate.toLocaleDateString('pt-BR', {
    weekday: 'long',
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  })

  return (
    <div className="cal-shell">
      <header className="cal-header">
        <div className="cal-header-inner">
          <Link to="/" className="cal-logo-link" aria-label="BaileSul">
            <img src="/imagens/BaileSul.png" alt="BaileSul" className="cal-logo-img" />
          </Link>
          <Link to={contaLink} className="cal-user-btn" aria-label={isAuthenticated ? 'Minha conta' : 'Entrar'}>
            <User size={20} strokeWidth={1.8} />
          </Link>
        </div>
      </header>

      <main className="cal-main">
        <div className="cal-layout">
          <section className="cal-card" aria-label="Calendário">
            <div className="cal-nav">
              <h1 className="cal-month-title" key={monthTitle}>
                {monthTitle}
              </h1>
              <div className="cal-nav-btns">
                <button type="button" className="cal-nav-btn" onClick={() => goToMonth(-1)} aria-label="Mês anterior">
                  <ChevronLeft size={16} strokeWidth={2.5} />
                </button>
                <button type="button" className="cal-nav-btn" onClick={() => goToMonth(1)} aria-label="Próximo mês">
                  <ChevronRight size={16} strokeWidth={2.5} />
                </button>
              </div>
            </div>

            <div className="cal-grid" key={`${viewYear}-${viewMonth}`}>
              {WEEKDAYS.map((w) => (
                <div key={w} className="cal-weekday">{w}</div>
              ))}
              {cells.map((day, i) =>
                day === null ? (
                  <div key={`e${i}`} className="cal-cell-empty" />
                ) : (
                  <button
                    key={`${viewYear}-${viewMonth}-${day}`}
                    type="button"
                    className={[
                      'cal-cell',
                      isSelected(day) ? 'is-selected' : '',
                      isToday(day) && !isSelected(day) ? 'is-today' : '',
                      eventDates.has(day) ? 'has-event' : '',
                    ].filter(Boolean).join(' ')}
                    onClick={() => setSelected({ day, month: viewMonth, year: viewYear })}
                    aria-label={`${day} de ${MONTHS[viewMonth]}`}
                    aria-pressed={isSelected(day)}
                  >
                    {day}
                    {eventDates.has(day) && <span className="cal-dot" aria-hidden />}
                  </button>
                ),
              )}
            </div>
          </section>

          <aside className="cal-aside" aria-label="Eventos do dia">
            <div className="cal-aside-head">
              <div>
                <p className="cal-aside-eyebrow">Agenda</p>
                <h2 className="cal-aside-date">{dateLabel}</h2>
              </div>
              {podeCriarEvento && (
                <Link to="/criar-evento" className="cal-btn-add">
                  <Plus size={15} strokeWidth={2.5} />
                  Criar evento
                </Link>
              )}
            </div>

            {events.length === 0 ? (
              <div className="cal-empty">
                <CalendarDays size={38} strokeWidth={1.3} aria-hidden />
                <p>Nenhum evento nesta data</p>
                <span>Selecione outro dia no calendário</span>
              </div>
            ) : (
              <ul className="cal-event-list">
                {events.map((ev) => (
                  <li key={ev.id}>
                    <Link to={`/eventos/${ev.id}`} className="cal-event-card">
                      <div className="cal-event-img-wrap">
                        <img src={ev.image} alt="" className="cal-event-img" loading="lazy" />
                      </div>
                      <div className="cal-event-body">
                        <span className="cal-event-style">{ev.style}</span>
                        <h3 className="cal-event-title">{ev.title}</h3>
                        <div className="cal-event-meta">
                          <span className="cal-event-city">
                            <MapPin size={12} strokeWidth={2} aria-hidden />
                            {ev.city}
                          </span>
                          <span className="cal-event-price">{ev.price}</span>
                        </div>
                      </div>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </aside>
        </div>
      </main>

      <footer className="cal-footer">
        <div className="cal-footer-inner">
          <div className="cal-footer-brand">
            <Link to="/" aria-label="BaileSul">
              <img src="/imagens/BaileSul.png" alt="BaileSul" className="cal-footer-logo" />
            </Link>
          </div>

          <div className="cal-footer-copy-block">
            <p className="cal-footer-copy">© BaileSul – Todos os direitos reservados.</p>
          </div>

          <nav className="cal-footer-nav-block" aria-label="Navegação do rodapé">
            <h4 className="cal-footer-heading">Navegação</h4>
            <div className="cal-footer-nav">
              <div className="cal-footer-nav-col">
                {footerLinks.slice(0, 3).map((item) => (
                  <Link key={item.to} to={item.to}>{item.label}</Link>
                ))}
              </div>
              <div className="cal-footer-nav-col">
                {footerLinks.slice(3).map((item) => (
                  <Link key={item.to} to={item.to}>{item.label}</Link>
                ))}
              </div>
            </div>
          </nav>
        </div>
      </footer>
    </div>
  )
}
