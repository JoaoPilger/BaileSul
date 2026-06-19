import React, { useEffect, useState } from 'react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadEvents } from '../../utils/events'
import { useNavigate } from 'react-router-dom'
import { MapPin, Calendar } from 'lucide-react'
import { cn } from '../../utils/cn'
import shared from '../../styles/shared.module.css'
import styles from './comunidades.module.css'

function CommunityCard({ item }) {
  const navigate = useNavigate()

  return (
    <div className={styles['community-card']} onClick={() => navigate(`/eventos/${item.id}`)} style={{ cursor: 'pointer' }}>
      <img src={item.image} alt={item.title} className={styles['community-card-img']} />
      <div className={styles['community-card-body']}>
        <h3 className={styles['community-card-title']}>{item.title.toUpperCase()}</h3>
        <div className={styles['community-card-sub']}>Banda/Artista</div>
        <div className={styles['community-card-meta']}>
          <Calendar size={14} /> <span>{item.date}</span>
        </div>
        <div className={styles['community-card-meta']}>
          <span>00:00</span>
        </div>
        <div className={styles['community-card-meta']}>
          <MapPin size={14} /> <span>{item.city}, SC</span>
        </div>
      </div>
    </div>
  )
}

export default function Comunidades() {
  const [items, setItems] = useState([])
  const [displayed, setDisplayed] = useState([])
  const [query, setQuery] = useState('')
  const [suggestions, setSuggestions] = useState([])
  const [cities, setCities] = useState([])
  const [selectedCity, setSelectedCity] = useState('')

  useEffect(() => {
    const all = loadEvents()
    setItems(all)
    setDisplayed(all)

    const uniqueCities = Array.from(new Set(all.map((e) => e.city).filter(Boolean)))
    setCities(uniqueCities)
  }, [])

  function applyFilters({ q = query, city = selectedCity } = {}) {
    const lower = q.trim().toLowerCase()
    let out = items.slice()
    if (lower) out = out.filter((it) => it.title.toLowerCase().includes(lower))
    if (city) out = out.filter((it) => it.city === city)
    setDisplayed(out)
  }

  function onQueryChange(e) {
    const v = e.target.value
    setQuery(v)
    if (!v) {
      setSuggestions([])
      applyFilters({ q: '' })
      return
    }

    const lower = v.toLowerCase()
    const matches = items
      .filter((it) => it.title.toLowerCase().includes(lower))
      .slice(0, 8)
      .map((it) => it.title)
    setSuggestions(matches)
    applyFilters({ q: v })
  }

  function onSelectSuggestion(text) {
    setQuery(text)
    setSuggestions([])
    applyFilters({ q: text })
  }

  function onCityChange(e) {
    setSelectedCity(e.target.value)
    applyFilters({ city: e.target.value })
  }

  return (
    <>
      <Header />
      <main className={styles['communities-page']}>
        <div className={styles['communities-hero']}>
          <div className={shared.container}>
            <h1>Comunidades</h1>
          </div>
        </div>

        <section className={cn(shared.section, shared.container, styles.sectionArea)}>
          <div className={styles['communities-filters']}>
            <div style={{ position: 'relative', flex: 1 }}>
              <input value={query} onChange={onQueryChange} className={styles['communities-search']} placeholder="Buscar comunidade" />
              {suggestions.length > 0 && (
                <ul className={styles['suggestions-list']}>
                  {suggestions.map((s) => (
                    <li key={s} className={styles['suggestion-item']} onClick={() => onSelectSuggestion(s)}>{s}</li>
                  ))}
                </ul>
              )}
            </div>
            <div className={styles['communities-filters-right']}>
              <select value={selectedCity} onChange={onCityChange}>
                <option value="">Cidade</option>
                {cities.map((c) => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>
          </div>

          <div className={styles['communities-grid']}>
            {displayed.map((it) => (
              <CommunityCard key={it.id} item={it} />
            ))}
          </div>
        </section>
      </main>
      <Footer />
    </>
  )
}
