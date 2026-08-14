import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { ChevronLeft, ChevronRight, Plus, CalendarDays, MapPin } from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'
import { loadEvents, formatTipoEvento } from '../../utils/events'
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

function formatKey(day, month, year) {
  return `${pad(day)}/${pad(month + 1)}/${year}`
}

export default function Calendario() {
  const today = new Date()
  const { usuario } = useAuth()
  const podeCriarEvento = !usuario?.tipo || usuario.tipo === 'comunidade' || usuario.tipo === 'banda'

  const [view, setView] = useState({
    year: today.getFullYear(),
    month: today.getMonth(),
  })
  const [selected, setSelected] = useState({
    day: today.getDate(),
    month: today.getMonth(),
    year: today.getFullYear(),
  })

  const [eventsMap, setEventsMap] = useState({})

  useEffect(() => {
    loadEvents().then((all) => {
      const map = {}
      all.forEach((ev) => {
        if (!ev.date) return
        const [y, m, d] = ev.date.split('-')
        const key = `${d}/${m}/${y}`
        if (!map[key]) map[key] = []
        map[key].push(ev)
      })
      setEventsMap(map)
    })
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
                        <span className={styles['cal-event-style']}>{formatTipoEvento(ev.style)}</span>
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
