import { useEffect, useState } from 'react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadBands } from '../../utils/bands'
import { useNavigate } from 'react-router-dom'
import { Music, Users } from 'lucide-react'
import shared from '../../styles/shared.module.css'
import styles from '../../styles/listings.module.css'

function BandCard({ item }) {
  const navigate = useNavigate()

  return (
    <div className={styles['listing-card']} onClick={() => navigate(`/bandas/${item.id}`)}>
      <div className={styles['listing-card-img-wrap']}>
        <div className={styles['listing-card-placeholder-band']}>
          <Music size={40} className={styles['listing-card-placeholder-icon']} />
        </div>
        {item.style && <div className={styles['listing-card-price']}>{item.style}</div>}
      </div>

      <div className={styles['listing-card-body']}>
        <span className={styles['listing-card-label']}>Banda</span>
        <h3 className={styles['listing-card-title']}>{item.title}</h3>
        {item.description && (
          <div className={styles['listing-card-meta']}>
            {item.description.length > 80
              ? item.description.slice(0, 80) + '…'
              : item.description}
          </div>
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
  const [selectedStyle, setSelectedStyle] = useState('')
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    loadBands().then((all) => {
      setItems(all)
      setDisplayed(all)
      setIsLoading(false)

      const uniqueStyles = Array.from(new Set(all.map((e) => e.style).filter(Boolean)))
      setMusicStyles(uniqueStyles)
    }).catch(() => setIsLoading(false))
  }, [])

  function applyFilters({ q = query, style = selectedStyle } = {}) {
    const lower = q.trim().toLowerCase()
    let out = items.slice()
    if (lower) out = out.filter((it) => it.title.toLowerCase().includes(lower))
    if (style) out = out.filter((it) => it.style === style)
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
                  <BandCard key={item.id} item={item} />
                ))}
              </div>
            ) : (
              <div className={styles['listing-empty']}>
                <Users size={48} />
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
