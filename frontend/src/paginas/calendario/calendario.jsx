import { useState, useEffect } from 'react'
import { cn } from '../../utils/cn';
import { Link } from 'react-router-dom'
import { ChevronLeft, ChevronRight, Plus, CalendarDays, MapPin } from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'
import HeaderCal from '../../components/header/HeaderCal'
import FooterCal from '../../components/footer/FooterCal'
import styles from './calendario.module.css';

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
    <div className={styles['cal-shell']}>
      <HeaderCal />

      <main className={styles['cal-main']}>
        <div className={styles['cal-layout']}>
          <section className={styles['cal-card']} aria-label="Calendário">
            <div className={styles['cal-nav']}>
              <h1 className={styles['cal-month-title']} key={monthTitle}>
                {monthTitle}
              </h1>
              <div className={styles['cal-nav-btns']}>
                <button type="button" className={styles['cal-nav-btn']} onClick={() => goToMonth(-1)} aria-label="Mês anterior">
                  <ChevronLeft size={16} strokeWidth={2.5} />
                </button>
                <button type="button" className={styles['cal-nav-btn']} onClick={() => goToMonth(1)} aria-label="Próximo mês">
                  <ChevronRight size={16} strokeWidth={2.5} />
                </button>
              </div>
            </div>

            <div className={styles['cal-grid']} key={`${viewYear}-${viewMonth}`}>
              {WEEKDAYS.map((w) => (
                <div key={w} className={styles['cal-weekday']}>{w}</div>
              ))}
              {cells.map((day, i) =>
                day === null ? (
                  <div key={`e${i}`} className={styles['cal-cell-empty']} />
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
                    {eventDates.has(day) && <span className={styles['cal-dot']} aria-hidden />}
                  </button>
                ),
              )}
            </div>
          </section>

          <aside className={styles['cal-aside']} aria-label="Eventos do dia">
            <div className={styles['cal-aside-head']}>
              <div>
                <p className={styles['cal-aside-eyebrow']}>Agenda</p>
                <h2 className={styles['cal-aside-date']}>{dateLabel}</h2>
              </div>
              {podeCriarEvento && (
                <Link to="/criar-evento" className={styles['cal-btn-add']}>
                  <Plus size={15} strokeWidth={2.5} />
                  Criar evento
                </Link>
              )}
            </div>

            {events.length === 0 ? (
              <div className={styles['cal-empty']}>
                <CalendarDays size={38} strokeWidth={1.3} aria-hidden />
                <p>Nenhum evento nesta data</p>
                <span>Selecione outro dia no calendário</span>
              </div>
            ) : (
              <ul className={styles['cal-event-list']}>
                {events.map((ev) => (
                  <li key={ev.id}>
                    <Link to={`/eventos/${ev.id}`} className={styles['cal-event-card']}>
                      <div className={styles['cal-event-img-wrap']}>
                        <img src={ev.image} alt="" className={styles['cal-event-img']} loading="lazy" />
                      </div>
                      <div className={styles['cal-event-body']}>
                        <span className={styles['cal-event-style']}>{ev.style}</span>
                        <h3 className={styles['cal-event-title']}>{ev.title}</h3>
                        <div className={styles['cal-event-meta']}>
                          <span className={styles['cal-event-city']}>
                            <MapPin size={12} strokeWidth={2} aria-hidden />
                            {ev.city}
                          </span>
                          <span className={styles['cal-event-price']}>{ev.price}</span>
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

      <FooterCal />
    </div>
  )
}
