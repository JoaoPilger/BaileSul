import React, { useEffect, useState } from 'react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadEvents } from '../../utils/events'
import { useNavigate } from 'react-router-dom'
import { MapPin, Calendar } from 'lucide-react'
import shared from '../../styles/shared.module.css'
import styles from '../../styles/listings.module.css'

function ListingCard({ item, onDelete }) {
  const navigate = useNavigate()
  const date = new Date(item.date)
  const day = date.toLocaleDateString('pt-BR', { day: '2-digit' })
  const month = date.toLocaleDateString('pt-BR', { month: 'short' }).replace('.', '')

  return (
    <div className={styles['listing-card']} onClick={() => navigate(`/eventos/${item.id}`)}>
      <div className={styles['listing-card-img-wrap']}>
        <img src={item.image} alt={item.title} className={styles['listing-card-img']} />
        <div className={styles['listing-card-badge']}>
          <span>{day}</span>
          <span>{month}</span>
        </div>
        {item.price && <div className={styles['listing-card-price']}>{item.price}</div>}
      </div>

      <div className={styles['listing-card-body']}>
        <span className={styles['listing-card-label']}>{item.style || 'Banda'}</span>
        <h3 className={styles['listing-card-title']}>{item.title}</h3>
        <div className={styles['listing-card-meta']}>
          <MapPin size={14} />
          {item.city}
        </div>
        {onDelete && (
          <button
            className={styles['listing-card-action']}
            type="button"
            onClick={(e) => {
              e.stopPropagation()
              onDelete(item.id)
            }}
          >
            🗑️ Apagar
          </button>
        )}
      </div>
    </div>
  )
}

export default function Bandas() {
  const [items, setItems] = useState([])
  const [displayed, setDisplayed] = useState([])
  const [query, setQuery] = useState('')
  const [suggestions, setSuggestions] = useState([])
  const [musicStyles, setMusicStyles] = useState([])
  const [cities, setCities] = useState([])
  const [selectedStyle, setSelectedStyle] = useState('')
  const [selectedCity, setSelectedCity] = useState('')

  useEffect(() => {
    const all = loadEvents()
    setItems(all)
    setDisplayed(all)

    const uniqueStyles = Array.from(new Set(all.map((e) => e.style).filter(Boolean)))
    const uniqueCities = Array.from(new Set(all.map((e) => e.city).filter(Boolean)))
    setMusicStyles(uniqueStyles)
    setCities(uniqueCities)
  }, [])

  function applyFilters({ q = query, style = selectedStyle, city = selectedCity } = {}) {
    const lower = q.trim().toLowerCase()
    let out = items.slice()
    if (lower) out = out.filter((it) => it.title.toLowerCase().includes(lower))
    if (style) out = out.filter((it) => it.style === style)
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

  function onStyleChange(e) {
    setSelectedStyle(e.target.value)
    applyFilters({ style: e.target.value })
  }

  function onCityChange(e) {
    setSelectedCity(e.target.value)
    applyFilters({ city: e.target.value })
  }

  return (
    <>
      <Header />
      <main className={styles['listing-page']}>
        <section className={styles['listing-hero']}>
          <div className={styles['listing-hero-content']}>
            <h1>Descubra grandes artistas</h1>
            <p>Encontre as melhores bandas e artistas para sua próxima festa.</p>
          </div>
        </section>

        <section className={shared.section}>
          <div className={shared.container}>
            <div className={shared.sectionHeader}>
              <div>
                <h2 className={shared.sectionTitle}>Bandas Disponíveis</h2>
                <p className={shared.sectionSub}>Descubra os melhores artistas e bandas.</p>
              </div>
              <span className={styles['listing-count']}>{displayed.length} bandas</span>
            </div>

            <div style={{ position: 'relative' }}>
              <div className={styles['listing-filters']}>
                <div style={{ position: 'relative', flex: 1 }}>
                  <input
                    value={query}
                    onChange={onQueryChange}
                    className={styles['listing-search']}
                    placeholder="Buscar banda..."
                  />
                  {suggestions.length > 0 && (
                    <ul className={styles['suggestions-list']}>
                      {suggestions.map((s) => (
                        <li key={s} className={styles['suggestion-item']} onClick={() => onSelectSuggestion(s)}>
                          {s}
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
                <div className={styles['listing-filters-group']}>
                  <select value={selectedStyle} onChange={onStyleChange} className={styles['listing-select']}>
                    <option value="">Todos os estilos</option>
                    {musicStyles.map((s) => (
                      <option key={s} value={s}>
                        {s}
                      </option>
                    ))}
                  </select>
                  <select value={selectedCity} onChange={onCityChange} className={styles['listing-select']}>
                    <option value="">Todas as cidades</option>
                    {cities.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            {displayed.length ? (
              <div className={styles['listing-grid']}>
                {displayed.map((item) => (
                  <ListingCard key={item.id} item={item} />
                ))}
              </div>
            ) : (
              <div className={styles['listing-empty']}>
                <Calendar size={48} />
                <p>Nenhuma banda encontrada</p>
                <span>Tente ajustar seus filtros ou busque por outro termo</span>
              </div>
            )}
          </div>
        </section>
      </main>
      <Footer />
    </>
  )
}
