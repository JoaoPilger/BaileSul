import React, { useEffect, useState } from 'react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadCommunities } from '../../utils/communities'
import { useNavigate } from 'react-router-dom'
import { MapPin, Users } from 'lucide-react'
import shared from '../../styles/shared.module.css'
import styles from '../../styles/listings.module.css'

function CommunityCard({ item }) {
  const navigate = useNavigate()

  return (
    <div className={styles['listing-card']} onClick={() => navigate(`/comunidades/${item.id}`)}>
      <div className={styles['listing-card-img-wrap']}>
        <div
          className={styles['listing-card-img']}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
            minHeight: '160px',
          }}
        >
          <Users size={48} color="rgba(255,255,255,0.5)" />
        </div>
      </div>

      <div className={styles['listing-card-body']}>
        <span className={styles['listing-card-label']}>Comunidade</span>
        <h3 className={styles['listing-card-title']}>{item.title}</h3>
        {item.city && (
          <div className={styles['listing-card-meta']}>
            <MapPin size={14} />
            {item.city}{item.state ? ` - ${item.state}` : ''}
          </div>
        )}
        {item.description && (
          <div className={styles['listing-card-meta']} style={{ marginTop: '4px', opacity: 0.7 }}>
            {item.description.length > 80
              ? item.description.slice(0, 80) + '…'
              : item.description}
          </div>
        )}
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
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    setIsLoading(true)
    loadCommunities().then((all) => {
      setItems(all)
      setDisplayed(all)
      setIsLoading(false)

      const uniqueCities = Array.from(new Set(all.map((e) => e.city).filter(Boolean)))
      setCities(uniqueCities)
    }).catch(() => setIsLoading(false))
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
      <main className={styles['listing-page']}>
        <section className={styles['listing-hero']}>
          <div className={styles['listing-hero-content']}>
            <h1>Explore comunidades locais</h1>
            <p>Descubra as melhores comunidades de dança da sua região.</p>
          </div>
        </section>

        <section className={shared.section}>
          <div className={shared.container}>
            <div className={shared.sectionHeader}>
              <div>
                <h2 className={shared.sectionTitle}>Comunidades Disponíveis</h2>
                <p className={shared.sectionSub}>Encontre a comunidade perfeita para você.</p>
              </div>
              <span className={styles['listing-count']}>{displayed.length} comunidades</span>
            </div>

            <div style={{ position: 'relative' }}>
              <div className={styles['listing-filters']}>
                <div style={{ position: 'relative', flex: 1 }}>
                  <input
                    value={query}
                    onChange={onQueryChange}
                    className={styles['listing-search']}
                    placeholder="Buscar comunidade..."
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

            {isLoading ? (
              <div className={styles['listing-grid']}>
                {[1, 2, 3].map((i) => (
                  <div key={i} className={shared.skeletonCard}>
                    <div className={shared.skeletonImg} />
                    <div className={shared.skeletonBody}>
                      <div className={shared.skeletonLine} style={{ width: '70%' }} />
                      <div className={shared.skeletonLine} style={{ width: '50%' }} />
                    </div>
                  </div>
                ))}
              </div>
            ) : displayed.length ? (
              <div className={styles['listing-grid']}>
                {displayed.map((item) => (
                  <CommunityCard key={item.id} item={item} />
                ))}
              </div>
            ) : (
              <div className={styles['listing-empty']}>
                <Users size={48} />
                <p>Nenhuma comunidade encontrada</p>
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
