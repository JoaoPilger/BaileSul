import { useEffect, useMemo, useState } from 'react'
import { cn } from '../../utils/cn';
import { useParams, useNavigate } from 'react-router-dom'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadEventById } from '../../utils/events'
import styles from './evento.module.css';

const DEFAULT_IMAGE =
  'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1200&q=80'

const AMAUC_MAP =
  'https://www.openstreetmap.org/export/embed.html?bbox=-53.0,-29.5,-48.0,-26.0&layer=mapnik'

const STYLE_LABELS = {
  sertanejo: 'Sertanejo',
  forro: 'Forró',
  pagode: 'Pagode',
  rock: 'Rock',
  gaucha: 'Gaúcha',
  axe: 'Axé',
  mpb: 'MPB',
  outro: 'Outro',
}

function formatDate(dateStr) {
  if (!dateStr) return ''
  const [y, m, d] = dateStr.split('-')
  const date = new Date(Number(y), Number(m) - 1, Number(d))
  if (Number.isNaN(date.getTime())) {
    return new Date(dateStr).toLocaleDateString('pt-BR', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    })
  }
  return date.toLocaleDateString('pt-BR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
}

function formatStyle(style) {
  if (!style) return ''
  const key = String(style).toLowerCase()
  return STYLE_LABELS[key] || style.charAt(0).toUpperCase() + style.slice(1)
}

function formatPrice(price) {
  if (!price) return 'Grátis'
  const raw = String(price).trim()
  if (/^(grátis|gratis)$/i.test(raw)) return 'Grátis'
  const amount = raw.replace(/^R\$\s*/i, '').trim()
  if (!amount) return 'Grátis'
  return `R$ ${amount}`
}

function buildAddress(evento) {
  const parts = [evento.rua, evento.bairro, evento.city, evento.cep]
    .map((p) => (p ? String(p).trim() : ''))
    .filter(Boolean)
  if (parts.length) return `${parts.join(', ')}, Brasil`
  if (evento.local) return `${evento.local}, Brasil`
  if (evento.city) return `${evento.city}, Santa Catarina, Brasil`
  return ''
}

function buildMapUrl(lat, lon) {
  const pad = 0.012
  const bbox = [lon - pad, lat - pad, lon + pad, lat + pad].join(',')
  return `https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat}%2C${lon}`
}

function getDescription(evento) {
  if (evento.description?.trim()) return evento.description.trim()
  const city = evento.city || 'cidade não informada'
  const style = formatStyle(evento.style) || 'evento'
  let text = `Esse evento está localizado em ${city} e foi cadastrado como um baile de ${style}.`
  if (evento.referencia) text += ` Referência: ${evento.referencia}.`
  return text
}

export default function EventoPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const evento = useMemo(() => loadEventById(id), [id])
  const [mapSrc, setMapSrc] = useState(AMAUC_MAP)

  const addressQuery = useMemo(
    () => (evento ? buildAddress(evento) : ''),
    [evento],
  )

  useEffect(() => {
    if (!addressQuery) {
      setMapSrc(AMAUC_MAP)
      return
    }

    let cancelled = false
    const controller = new AbortController()

    ;(async () => {
      try {
        const res = await fetch(
          `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(addressQuery)}`,
          {
            signal: controller.signal,
            headers: { 'Accept-Language': 'pt-BR' },
          },
        )
        const data = await res.json()
        if (cancelled || !data?.[0]) return
        const lat = parseFloat(data[0].lat)
        const lon = parseFloat(data[0].lon)
        if (!Number.isNaN(lat) && !Number.isNaN(lon)) {
          setMapSrc(buildMapUrl(lat, lon))
        }
      } catch {
        if (!cancelled) setMapSrc(AMAUC_MAP)
      }
    })()

    return () => {
      cancelled = true
      controller.abort()
    }
  }, [addressQuery])

  if (!evento) {
    return (
      <>
        <Header />
        <main className={styles['ev-page']}>
          <div className={cn(styles['ev-body'], styles['ev-body--empty'])}>
            <h2>Evento não encontrado</h2>
            <p>Esse evento pode ter sido removido ou não existe mais.</p>
            <button type="button" className={styles['ev-btn-reservar']} onClick={() => navigate('/eventos')}>
              Voltar para eventos
            </button>
          </div>
        </main>
        <Footer />
      </>
    )
  }

  const imageSrc = evento.image || DEFAULT_IMAGE
  const priceDisplay = formatPrice(evento.price)
  const isFree = priceDisplay === 'Grátis'
  const styleLabel = formatStyle(evento.style)
  const localDisplay =
    evento.local ||
    [evento.rua, evento.bairro, evento.city].filter(Boolean).join(', ') ||
    evento.city ||
    ''

  const handleShare = () => {
    if (navigator.share) {
      navigator.share({ title: evento.title, url: window.location.href })
    } else {
      navigator.clipboard?.writeText(window.location.href)
    }
  }

  return (
    <>
      <Header />
      <main className={styles['ev-page']}>
        <div className={styles['ev-hero']}>
          <img src={imageSrc} alt={evento.title} className={styles['ev-hero-img']} />
        </div>

        <div className={styles['ev-body']}>
          <button type="button" className={styles['ev-back-btn']} onClick={() => navigate(-1)}>
            <svg viewBox="0 0 24 24" aria-hidden>
              <line x1="19" y1="12" x2="5" y2="12" />
              <polyline points="12 19 5 12 12 5" />
            </svg>
            Voltar
          </button>

          <div className={styles['ev-content']}>
            <div className={styles['ev-left']}>
              {styleLabel && (
                <div className={styles['ev-tag']}>
                  <svg viewBox="0 0 24 24" aria-hidden>
                    <path d="M9 18V5l12-2v13" />
                    <circle cx="6" cy="18" r="3" />
                    <circle cx="18" cy="16" r="3" />
                  </svg>
                  {styleLabel}
                </div>
              )}

              <h1 className={styles['ev-title']}>{evento.title}</h1>

              <div className={styles['ev-organizer-row']}>
                <span className={styles['ev-organizer']}>{evento.band || evento.organizer || 'Evento'}</span>
                <button type="button" className={styles['ev-share-btn']} onClick={handleShare}>
                  <svg viewBox="0 0 24 24" aria-hidden>
                    <circle cx="18" cy="5" r="3" />
                    <circle cx="6" cy="12" r="3" />
                    <circle cx="18" cy="19" r="3" />
                    <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
                    <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
                  </svg>
                  Compartilhar evento
                </button>
              </div>

              <div className={styles['ev-about']}>
                <div className={styles['ev-about-title']}>Sobre o Evento</div>
                <p className={styles['ev-about-text']}>{getDescription(evento)}</p>
              </div>

              {evento.vendors?.length > 0 && (
                <div className={styles['ev-vendors']}>
                  <div className={styles['ev-about-title']}>Vendedores</div>
                  <ul>
                    {evento.vendors.map((vendor) => (
                      <li key={vendor.id}>{vendor.name}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>

            <aside className={styles['ev-right']}>
              <section className={styles['ev-info-card']} aria-label="Informações do evento">
                <div className={styles['ev-info-list']}>
                  {evento.date && (
                    <div className={styles['ev-info-item']}>
                      <div className={styles['ev-info-icon']} aria-hidden>
                        <svg viewBox="0 0 24 24">
                          <rect x="3" y="4" width="18" height="18" rx="2" />
                          <line x1="16" y1="2" x2="16" y2="6" />
                          <line x1="8" y1="2" x2="8" y2="6" />
                          <line x1="3" y1="10" x2="21" y2="10" />
                        </svg>
                      </div>
                      <div className={styles['ev-info-text']}>
                        <span className={styles['ev-info-label']}>Data</span>
                        <span className={styles['ev-info-value']}>{formatDate(evento.date)}</span>
                      </div>
                    </div>
                  )}

                  {(evento.time_start || evento.timeStart) && (
                    <div className={styles['ev-info-item']}>
                      <div className={styles['ev-info-icon']} aria-hidden>
                        <svg viewBox="0 0 24 24">
                          <circle cx="12" cy="12" r="10" />
                          <polyline points="12 6 12 12 16 14" />
                        </svg>
                      </div>
                      <div className={styles['ev-info-text']}>
                        <span className={styles['ev-info-label']}>Horário</span>
                        <span className={styles['ev-info-value']}>
                          {evento.time_start || evento.timeStart}
                          {(evento.time_end || evento.timeEnd) &&
                            ` – ${evento.time_end || evento.timeEnd}`}
                        </span>
                      </div>
                    </div>
                  )}

                  {localDisplay && (
                    <div className={styles['ev-info-item']}>
                      <div className={styles['ev-info-icon']} aria-hidden>
                        <svg viewBox="0 0 24 24">
                          <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                          <circle cx="12" cy="10" r="3" />
                        </svg>
                      </div>
                      <div className={styles['ev-info-text']}>
                        <span className={styles['ev-info-label']}>Local</span>
                        <span className={styles['ev-info-value']}>{localDisplay}</span>
                      </div>
                    </div>
                  )}

                  {evento.capacity && (
                    <div className={styles['ev-info-item']}>
                      <div className={styles['ev-info-icon']} aria-hidden>
                        <svg viewBox="0 0 24 24">
                          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                          <circle cx="9" cy="7" r="4" />
                          <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                          <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                        </svg>
                      </div>
                      <div className={styles['ev-info-text']}>
                        <span className={styles['ev-info-label']}>Capacidade</span>
                        <span className={styles['ev-info-value']}>{evento.capacity}</span>
                      </div>
                    </div>
                  )}

                  {(evento.band || evento.organizer) && (
                    <div className={styles['ev-info-item']}>
                      <div className={styles['ev-info-icon']} aria-hidden>
                        <svg viewBox="0 0 24 24">
                          <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                          <polyline points="9 22 9 12 15 12 15 22" />
                        </svg>
                      </div>
                      <div className={styles['ev-info-text']}>
                        <span className={styles['ev-info-label']}>Organização</span>
                        <span className={styles['ev-info-value']}>{evento.band || evento.organizer}</span>
                      </div>
                    </div>
                  )}
                </div>

                <div className={styles['ev-ticket-area']}>
                  <span className={styles['ev-ticket-label']}>Valor do Ingresso</span>
                  <div className={styles['ev-ticket-row']}>
                    <span className={cn(styles['ev-price'], isFree && styles['ev-price--free'])}>
                      {priceDisplay}
                    </span>
                    <button type="button" className={styles['ev-btn-reservar']}>
                      Reservar
                    </button>
                  </div>
                </div>
              </section>
            </aside>
          </div>

          <section className={styles['ev-location']} aria-label="Localização do evento">
            <div className={styles['ev-location-title']}>Localização</div>
            {addressQuery && <p className={styles['ev-location-address']}>{addressQuery.replace(', Brasil', '')}</p>}
            <div className={styles['ev-mapa-container']}>
              <iframe
                title={`Mapa — ${evento.title}`}
                src={mapSrc}
                className={styles['ev-mapa-iframe']}
                loading="lazy"
              />
            </div>
          </section>
        </div>
      </main>
      <Footer />
    </>
  )
}
