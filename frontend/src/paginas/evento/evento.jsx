import { useEffect, useMemo, useState } from 'react'
import { cn } from '../../utils/cn';
import { useParams, useNavigate } from 'react-router-dom'
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadEventById } from '../../utils/events'
import { useAuth } from '../../contexts/AuthContext'
import styles from './evento.module.css';

// Corrige o caminho dos ícones padrão do Leaflet, que quebram com bundlers
// (Vite/Webpack) porque resolvem os assets de forma diferente do CDN.
delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
})

const DEFAULT_IMAGE =
  'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1200&q=80'

const DEFAULT_CENTER = [-27.5, -50.5] // Centro aproximado da região Sul do Brasil
const DEFAULT_ZOOM = 6
const EVENT_ZOOM = 15

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

/**
 * loadEventById (utils/events.js) já normaliza o evento vindo da API,
 * devolvendo campos separados: rua, bairro, referencia, city, cep, local.
 * Não é preciso parsear nada aqui — só montar o texto de endereço.
 */
function buildAddressQuery(evento) {
  if (!evento) return ''
  const parts = [evento.rua, evento.bairro, evento.city]
    .map((p) => (p ? String(p).trim() : ''))
    .filter(Boolean)
  if (parts.length) return `${parts.join(', ')}, Brasil`
  if (evento.local) return `${evento.local}, Brasil`
  if (evento.city) return `${evento.city}, Santa Catarina, Brasil`
  return ''
}

/** Texto de endereço mostrado na seção "Localização" (sem ", Brasil" no final). */
function buildAddressDisplay(evento) {
  const q = buildAddressQuery(evento)
  return q.replace(/,\s*Brasil$/i, '')
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
  const { token } = useAuth()
  const [evento, setEvento] = useState(null)
  const [mapCenter, setMapCenter] = useState(DEFAULT_CENTER)
  const [mapZoom, setMapZoom] = useState(DEFAULT_ZOOM)
  const [modalOpen, setModalOpen] = useState(false)
  const [quantidade, setQuantidade] = useState('1')
  const [pagamento, setPagamento] = useState('presencial')
  const [nomeRetirada, setNomeRetirada] = useState('')
  const [reservaLoading, setReservaLoading] = useState(false)
  const [reservaErro, setReservaErro] = useState('')

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [id])

  useEffect(() => {
    loadEventById(id).then(setEvento)
  }, [id])

  const addressQuery = useMemo(
    () => (evento ? buildAddressQuery(evento) : ''),
    [evento],
  )

  const addressDisplay = useMemo(
    () => (evento ? buildAddressDisplay(evento) : ''),
    [evento],
  )

  useEffect(() => {
    if (!evento) return

    // 1. Caso ideal: o backend já geocodificou e salvou lat/lon na criação
    //    do evento. Usa direto, sem nova chamada de rede.
    const lat = parseFloat(evento.latitude)
    const lon = parseFloat(evento.longitude)
    if (!Number.isNaN(lat) && !Number.isNaN(lon) && lat !== 0 && lon !== 0) {
      setMapCenter([lat, lon])
      setMapZoom(EVENT_ZOOM)
      return
    }

    // 2. Sem coordenadas salvas: tenta geocodificar no cliente como fallback.
    const rua = evento.rua || ''
    const cidadeFinal = evento.city || ''

    if (!cidadeFinal.trim()) {
      setMapCenter(DEFAULT_CENTER)
      setMapZoom(DEFAULT_ZOOM)
      return
    }

    let cancelled = false
    const controller = new AbortController()

    ;(async () => {
      try {
        let data = []

        // Tentativa 1: busca estruturada (city + street) — mais precisa
        if (rua.trim()) {
          const params = new URLSearchParams({
            format: 'json',
            limit: '1',
            country: 'Brasil',
            city: cidadeFinal.trim(),
            street: rua.trim(),
          })
          const res = await fetch(
            `https://nominatim.openstreetmap.org/search?${params.toString()}`,
            { signal: controller.signal, headers: { 'Accept-Language': 'pt-BR' } },
          )
          data = await res.json()
        }

        // Tentativa 2: busca livre com o endereço completo
        if (!data?.[0] && addressQuery) {
          const res = await fetch(
            `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(addressQuery)}`,
            { signal: controller.signal, headers: { 'Accept-Language': 'pt-BR' } },
          )
          data = await res.json()
        }

        // Tentativa 3: só a cidade, como último recurso
        if (!data?.[0]) {
          const res = await fetch(
            `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(`${cidadeFinal.trim()}, Brasil`)}`,
            { signal: controller.signal, headers: { 'Accept-Language': 'pt-BR' } },
          )
          data = await res.json()
        }

        if (cancelled || !data?.[0]) return
        const foundLat = parseFloat(data[0].lat)
        const foundLon = parseFloat(data[0].lon)
        if (!Number.isNaN(foundLat) && !Number.isNaN(foundLon)) {
          setMapCenter([foundLat, foundLon])
          setMapZoom(EVENT_ZOOM)
        }
      } catch {
        if (!cancelled) {
          setMapCenter(DEFAULT_CENTER)
          setMapZoom(DEFAULT_ZOOM)
        }
      }
    })()

    return () => {
      cancelled = true
      controller.abort()
    }
  }, [evento, addressQuery])

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
    addressDisplay ||
    [evento.bairro, evento.city].filter(Boolean).join(', ') ||
    evento.city ||
    ''

  const handleReservar = async () => {
    if (!nomeRetirada.trim()) {
      setReservaErro('Informe o nome para retirada.')
      return
    }

    setReservaErro('')
    setReservaLoading(true)

    try {
      const res = await fetch(`/api/reservas/eventos/${id}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          quantidade: Number(quantidade),
          forma_pagamento: pagamento,
          nome_retirada: nomeRetirada.trim(),
        }),
      })

      const data = await res.json()

      if (!res.ok) {
        setReservaErro(data.error || 'Erro ao criar reserva.')
        return
      }

      // Sucesso: abre o WhatsApp do vendedor apenas se o pagamento for via WhatsApp
      if (pagamento === 'whatsapp' && data.vendedor?.whatsapp_link) {
        window.open(data.vendedor.whatsapp_link, '_blank', 'noopener,noreferrer')
      }

      closeModal()
    } catch {
      setReservaErro('Erro de conexão. Tente novamente.')
    } finally {
      setReservaLoading(false)
    }
  }

  const handleShare = () => {
    if (navigator.share) {
      navigator.share({ title: evento.title, url: window.location.href })
    } else {
      navigator.clipboard?.writeText(window.location.href)
    }
  }

  const openModal = () => setModalOpen(true)

  const closeModal = () => {
    setModalOpen(false)
    setReservaErro('')
    setReservaLoading(false)
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
                <span className={styles['ev-organizer']}>
                  {evento.band || evento.organizer || 'Evento'}
                </span>
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
                  {(evento.date) && (
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
                        <span className={styles['ev-info-value']}>
                          {formatDate(evento.date)}
                        </span>
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
                        <span className={styles['ev-info-value']}>
                          {evento.band || evento.organizer}
                        </span>
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
                    <button type="button" className={styles['ev-btn-reservar']} onClick={openModal}>
                      Reservar
                    </button>
                  </div>
                </div>
              </section>
            </aside>
          </div>

          <section className={styles['ev-location']} aria-label="Localização do evento">
            <div className={styles['ev-location-title']}>Localização</div>
            {addressDisplay && <p className={styles['ev-location-address']}>{addressDisplay}</p>}
            <div className={styles['ev-mapa-container']}>
              <MapContainer
                key={`${mapCenter[0]}-${mapCenter[1]}-${mapZoom}`}
                center={mapCenter}
                zoom={mapZoom}
                scrollWheelZoom={false}
                className={styles['ev-mapa-iframe']}
                style={{ width: '100%', height: '100%' }}
              >
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                {mapZoom === EVENT_ZOOM && (
                  <Marker position={mapCenter}>
                    <Popup>{evento.title}</Popup>
                  </Marker>
                )}
              </MapContainer>
            </div>
          </section>
        </div>
      </main>

      {modalOpen && (
        <div className={styles['ev-modal']} onClick={closeModal}>
          <div className={styles['ev-modal-card']} onClick={(e) => e.stopPropagation()}>
            <button type="button" className={styles['ev-modal-close']} onClick={closeModal} aria-label="Fechar">
              &times;
            </button>

            <h2 className={styles['ev-modal-title']}>Reserve seu Ingresso</h2>

            <div className={styles['ev-modal-field']}>
              <label className={styles['ev-modal-label']} htmlFor="ev-quantidade">Quantidade:</label>
              <select
                id="ev-quantidade"
                className={styles['ev-modal-select']}
                value={quantidade}
                onChange={(e) => setQuantidade(e.target.value)}
              >
                {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((n) => (
                  <option key={n} value={n}>{n}</option>
                ))}
              </select>
            </div>

            <div className={styles['ev-modal-field']}>
              <span className={styles['ev-modal-label']}>Forma de pagamento:</span>
              <div className={styles['ev-modal-radios']}>
                <label className={styles['ev-modal-radio']}>
                  <input
                    type="radio"
                    name="pagamento"
                    value="presencial"
                    checked={pagamento === 'presencial'}
                    onChange={(e) => setPagamento(e.target.value)}
                  />
                  Presencial
                </label>
                <label className={styles['ev-modal-radio']}>
                  <input
                    type="radio"
                    name="pagamento"
                    value="whatsapp"
                    checked={pagamento === 'whatsapp'}
                    onChange={(e) => setPagamento(e.target.value)}
                  />
                  Via WhatsApp
                </label>
              </div>
            </div>

            <div className={styles['ev-modal-field']}>
              <label className={styles['ev-modal-label']} htmlFor="ev-nome">Nome para retirada:</label>
              <input
                id="ev-nome"
                type="text"
                className={styles['ev-modal-input']}
                placeholder="Digite o nome Completo"
                value={nomeRetirada}
                onChange={(e) => setNomeRetirada(e.target.value)}
              />
            </div>

            {reservaErro && (
              <p className={styles['ev-modal-error']}>{reservaErro}</p>
            )}
            <button
              type="button"
              className={styles['ev-modal-submit']}
              onClick={handleReservar}
              disabled={reservaLoading}
            >
              {reservaLoading ? 'Aguarde...' : 'Prosseguir'}
            </button>
          </div>
        </div>
      )}

      <Footer />
    </>
  )
}
