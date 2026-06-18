import React, { useEffect, useState } from 'react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadEvents } from '../../utils/events'
import { useNavigate } from 'react-router-dom'
import { MapPin, Calendar } from 'lucide-react'
import './bandas.css'

function BandCard({ item }) {
  const navigate = useNavigate()

  return (
    <div className="band-card" onClick={() => navigate(`/eventos/${item.id}`)} style={{ cursor: 'pointer' }}>
      <img src={item.image} alt={item.title} className="band-card-img" />
      <div className="band-card-body">
        <h3 className="band-card-title">{item.title.toUpperCase()}</h3>
        <div className="band-card-sub">Banda/Artista</div>
        <div className="band-card-meta">
          <Calendar size={14} /> <span>{item.date}</span>
        </div>
        <div className="band-card-meta">
          <span>00:00</span>
        </div>
        <div className="band-card-meta">
          <MapPin size={14} /> <span>{item.city}, SC</span>
        </div>
      </div>
    </div>
  )
}

export default function Bandas() {
  const [items, setItems] = useState([])
  const [displayed, setDisplayed] = useState([])
  const [query, setQuery] = useState('')
  const [suggestions, setSuggestions] = useState([])
  const [styles, setStyles] = useState([])
  const [cities, setCities] = useState([])
  const [selectedStyle, setSelectedStyle] = useState('')
  const [selectedCity, setSelectedCity] = useState('')

  useEffect(() => {
    const all = loadEvents()
    setItems(all)
    setDisplayed(all)

    const uniqueStyles = Array.from(new Set(all.map((e) => e.style).filter(Boolean)))
    const uniqueCities = Array.from(new Set(all.map((e) => e.city).filter(Boolean)))
    setStyles(uniqueStyles)
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
      <main className="bands-page">
        <div className="bands-hero">
          <div className="container">
            <h1>Bandas</h1>
          </div>
        </div>

        <section className="section container">
          <div className="bands-filters">
            <div style={{ position: 'relative', flex: 1 }}>
              <input value={query} onChange={onQueryChange} className="bands-search" placeholder="Buscar banda" />
              {suggestions.length > 0 && (
                <ul className="suggestions-list">
                  {suggestions.map((s) => (
                    <li key={s} className="suggestion-item" onClick={() => onSelectSuggestion(s)}>{s}</li>
                  ))}
                </ul>
              )}
            </div>

            <div className="bands-filters-right">
              <select value={selectedStyle} onChange={onStyleChange}>
                <option value="">Estilo musical</option>
                {styles.map((s) => <option key={s} value={s}>{s}</option>)}
              </select>
              <select value={selectedCity} onChange={onCityChange}>
                <option value="">Todas as cidades</option>
                {cities.map((c) => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>
          </div>

          <div className="bands-grid">
            {displayed.map((it) => (
              <BandCard key={it.id} item={it} />
            ))}
          </div>
        </section>
      </main>
      <Footer />
    </>
  )
}
