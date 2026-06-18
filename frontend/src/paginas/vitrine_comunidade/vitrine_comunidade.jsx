import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import './vitrine_comunidade.css'

const COMUNIDADE_MOCK = {
  id: 1,
  nome: 'Comunidade Exemplo',
  avatar: '',
  cover: '',
  cidade: 'Florianópolis, SC',
  seguidores: 1250,
  sobre: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer in diam purus. Nullam blandit, lectus pretium porttitor dapibus, augue tellus finibus nibh, a imperdiet eros urna in mi. Sed metus ipsum, ornare a sapien vel, congue tempus nibh.',
  localizacao: 'Florianópolis, SC',
  site: 'bailesul.com.br',
  redes: ['instagram', 'facebook', 'youtube', 'tiktok'],
  stats: {
    eventosRealizados: 10,
    seguidores: 1250,
    avaliacao: 4.8,
    proximosEventos: 6,
    totalAvaliacoes: 150,
  },
  galeria: ['', '', '', '', '', ''],
  avaliacaoBars: { 5: 80, 4: 55, 3: 20, 2: 10, 1: 5 },
  eventos: [
    {
      id: 1,
      nome: 'FESTA TERCEIRÃO IFC',
      data: '01/01/2000',
      hora: '00:00',
      local: 'Concórdia, SC',
      confirmados: 850,
      capacidade: 1000,
      status: 'agendado',
      diasFaltando: 15,
      image: '',
    },
    {
      id: 2,
      nome: 'FESTA TERCEIRÃO IFC',
      data: '01/01/2000',
      hora: '00:00',
      local: 'Concórdia, SC',
      confirmados: 850,
      capacidade: 1000,
      status: 'andamento',
      image: '',
    },
    {
      id: 3,
      nome: 'FESTA TERCEIRÃO IFC',
      data: '01/01/2000',
      hora: '00:00',
      local: 'Concórdia, SC',
      confirmados: 850,
      capacidade: 1000,
      status: 'realizado',
      dataRealizacao: '02/02/2000',
      image: '',
    },
  ],
}

function StarsDisplay({ value }) {
  return (
    <div className="vc-stars">
      {[1, 2, 3, 4, 5].map((i) => (
        <svg key={i} className={`vc-star ${i > Math.round(value) ? 'vc-star--empty' : ''}`} viewBox="0 0 24 24">
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      ))}
    </div>
  )
}

function EventStatusBadge({ status }) {
  const map = {
    agendado:  { label: 'Agendado',    cls: 'vc-event-badge--agendado' },
    andamento: { label: 'Em andamento', cls: 'vc-event-badge--andamento' },
    realizado: { label: 'Realizado',   cls: 'vc-event-badge--realizado' },
  }
  const s = map[status] || map.agendado
  return <span className={`vc-event-badge ${s.cls}`}>{s.label}</span>
}

export default function VitrineComunidade() {
  const { id } = useParams()
  const [abaAtiva, setAbaAtiva] = useState('sobre')
  const [seguindo, setSeguindo] = useState(false)
  const [textoExpandido, setTextoExpandido] = useState(false)

  let comunidade = COMUNIDADE_MOCK
  try {
    const raw = localStorage.getItem('bailesul_comunidades')
    if (raw) {
      const list = JSON.parse(raw)
      const found = list.find((c) => String(c.id) === String(id))
      if (found) comunidade = found
    }
  } catch {}

  const { stats, eventos, galeria, avaliacaoBars } = comunidade
  const totalBars = Object.values(avaliacaoBars).reduce((a, b) => a + b, 0)

  return (
    <div className="vc-shell">
      <Header />

      <main className="vc-main">
        <div className="vc-layout">

          <div className="vc-col-left">

            <div className="vc-card vc-profile-card">
              <div className="vc-cover">
                {comunidade.cover ? (
                  <img src={comunidade.cover} alt="Capa" className="vc-cover-img" />
                ) : (
                  <div className="vc-cover-placeholder">
                    <svg viewBox="0 0 24 24">
                      <rect x="3" y="3" width="18" height="18" rx="2" />
                      <circle cx="8.5" cy="8.5" r="1.5" />
                      <polyline points="21 15 16 10 5 21" />
                    </svg>
                  </div>
                )}
              </div>

              <div className="vc-avatar-row">
                <div className="vc-avatar-wrap">
                  <div className="vc-avatar">
                    {comunidade.avatar ? (
                      <img src={comunidade.avatar} alt={comunidade.nome} />
                    ) : (
                      comunidade.nome.slice(0, 3)
                    )}
                  </div>
                  <div className="vc-avatar-edit">
                    <svg viewBox="0 0 24 24">
                      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4z" />
                    </svg>
                  </div>
                </div>
                <span className="vc-seguidores-badge">
                  {stats.seguidores.toLocaleString('pt-BR')} Seguidores
                </span>
              </div>

              <div className="vc-profile-info">
                <div className="vc-community-name">{comunidade.nome}</div>
                <div className="vc-location-row">
                  <svg viewBox="0 0 24 24">
                    <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                    <circle cx="12" cy="10" r="3" />
                  </svg>
                  {comunidade.cidade}
                </div>
                <div className="vc-profile-actions">
                  <button
                    className={`vc-btn-seguir ${seguindo ? 'vc-btn-seguir--seguindo' : ''}`}
                    onClick={() => setSeguindo(!seguindo)}
                  >
                    {seguindo ? '✓ Seguindo' : 'Seguir'}
                  </button>
                  <button className="vc-btn-contato">Contato</button>
                </div>
              </div>
            </div>

            <div className="vc-card vc-tabs-card">
              <div className="vc-tabs">
                {['sobre', 'eventos', 'galeria', 'avaliacoes'].map((aba) => (
                  <button
                    key={aba}
                    className={`vc-tab ${abaAtiva === aba ? 'active' : ''}`}
                    onClick={() => setAbaAtiva(aba)}
                  >
                    {aba === 'avaliacoes' ? 'Avaliações' : aba.charAt(0).toUpperCase() + aba.slice(1)}
                  </button>
                ))}
              </div>

              <div className="vc-tab-content">
                {abaAtiva === 'sobre' && (
                  <>
                    <div className="vc-section-title">Sobre a comunidade</div>
                    <p className="vc-about-text">
                      {textoExpandido
                        ? comunidade.sobre
                        : comunidade.sobre.slice(0, 160) + (comunidade.sobre.length > 160 ? '...' : '')}
                    </p>
                    {comunidade.sobre.length > 160 && (
                      <button className="vc-ver-mais" onClick={() => setTextoExpandido(!textoExpandido)}>
                        {textoExpandido ? 'Ver menos ▲' : 'Ver mais ▼'}
                      </button>
                    )}

                    <div className="vc-meta-list">
                      <div className="vc-meta-item">
                        <svg viewBox="0 0 24 24">
                          <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                          <circle cx="12" cy="10" r="3" />
                        </svg>
                        <span>Localização</span>
                      </div>
                      <div className="vc-meta-item" style={{ paddingLeft: '24px', marginTop: '-6px' }}>
                        {comunidade.localizacao}
                      </div>

                      <div className="vc-meta-item" style={{ marginTop: '4px' }}>
                        <svg viewBox="0 0 24 24">
                          <circle cx="12" cy="12" r="10" />
                          <line x1="2" y1="12" x2="22" y2="12" />
                          <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
                        </svg>
                        <span>Site/redes sociais</span>
                      </div>
                      <div className="vc-social-icons" style={{ paddingLeft: '24px' }}>
                        {[
                          { label: 'Instagram', path: 'M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z M17.5 6.5h.01 M7 2h10a5 5 0 0 1 5 5v10a5 5 0 0 1-5 5H7a5 5 0 0 1-5-5V7a5 5 0 0 1 5-5z' },
                          { label: 'Facebook', path: 'M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z' },
                          { label: 'YouTube', path: 'M22.54 6.42a2.78 2.78 0 0 0-1.95-1.96C18.88 4 12 4 12 4s-6.88 0-8.59.46a2.78 2.78 0 0 0-1.95 1.96A29 29 0 0 0 1 12a29 29 0 0 0 .46 5.58A2.78 2.78 0 0 0 3.41 19.6C5.12 20 12 20 12 20s6.88 0 8.59-.46a2.78 2.78 0 0 0 1.95-1.95A29 29 0 0 0 23 12a29 29 0 0 0-.46-5.58z M9.75 15.02V8.98L15.5 12l-5.75 3.02z' },
                          { label: 'TikTok', path: 'M9 12a4 4 0 1 0 4 4V4a5 5 0 0 0 5 5' },
                        ].map((rede) => (
                          <div key={rede.label} className="vc-social-icon" title={rede.label}>
                            <svg viewBox="0 0 24 24">
                              <path d={rede.path} />
                            </svg>
                          </div>
                        ))}
                      </div>
                    </div>
                  </>
                )}

                {abaAtiva === 'eventos' && (
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', textAlign: 'center', padding: '20px 0' }}>
                    Ver eventos na coluna ao lado
                  </div>
                )}

                {abaAtiva === 'galeria' && (
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', textAlign: 'center', padding: '20px 0' }}>
                    Ver galeria na coluna ao lado
                  </div>
                )}

                {abaAtiva === 'avaliacoes' && (
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', textAlign: 'center', padding: '20px 0' }}>
                    Ver avaliações abaixo
                  </div>
                )}
              </div>
            </div>

            <div className="vc-card vc-ratings-card">
              <div className="vc-ratings-header">
                <span className="vc-ratings-title">Avaliações da comunidade</span>
                <a href="#avaliacoes" className="vc-ver-todas">Ver todas</a>
              </div>

              <div className="vc-rating-big">
                <span className="vc-rating-score">{stats.avaliacao}</span>
                <div className="vc-rating-info">
                  <StarsDisplay value={stats.avaliacao} />
                  <span className="vc-rating-count">Baseado em {stats.totalAvaliacoes} avaliações</span>
                </div>
              </div>

              <div className="vc-rating-bars">
                {[5, 4, 3, 2, 1].map((n) => (
                  <div key={n} className="vc-rating-bar-row">
                    <span className="vc-bar-label">{n}</span>
                    <div className="vc-bar-track">
                      <div
                        className="vc-bar-fill"
                        style={{ width: `${((avaliacaoBars[n] || 0) / totalBars) * 100}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

          </div>

          <div className="vc-col-right">

            <div className="vc-card vc-stats-card">
              <div className="vc-stats-grid">
                {[
                  {
                    icon: <svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></svg>,
                    value: stats.eventosRealizados,
                    label: 'Eventos realizados',
                  },
                  {
                    icon: <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>,
                    value: stats.seguidores.toLocaleString('pt-BR'),
                    label: 'Seguidores',
                  },
                  {
                    icon: <svg viewBox="0 0 24 24"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>,
                    value: stats.avaliacao,
                    label: `${stats.totalAvaliacoes} avaliações`,
                  },
                  {
                    icon: <svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /><line x1="12" y1="14" x2="12" y2="18" /><line x1="10" y1="16" x2="14" y2="16" /></svg>,
                    value: stats.proximosEventos,
                    label: 'Próximos eventos',
                  },
                ].map((s, i) => (
                  <div key={i} className="vc-stat-item">
                    <div className="vc-stat-icon">{s.icon}</div>
                    <span className="vc-stat-value">{s.value}</span>
                    <span className="vc-stat-label">{s.label}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="vc-card vc-gallery-card">
              <div className="vc-gallery-header">Galeria</div>
              <div className="vc-gallery-grid">
                {galeria.slice(0, 6).map((img, i) => (
                  <div key={i} className="vc-gallery-item">
                    {img ? (
                      <img src={img} alt={`Foto ${i + 1}`} />
                    ) : (
                      <div className="vc-gallery-placeholder">
                        <svg viewBox="0 0 24 24">
                          <rect x="3" y="3" width="18" height="18" rx="2" />
                          <circle cx="8.5" cy="8.5" r="1.5" />
                          <polyline points="21 15 16 10 5 21" />
                        </svg>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>

            <div className="vc-card vc-events-card">
              <div className="vc-events-header">
                <span className="vc-events-title">Próximos eventos</span>
                <Link to="/eventos" className="vc-ver-todos">Ver todos os eventos</Link>
              </div>

              <div className="vc-events-list">
                {eventos.map((ev) => (
                  <Link to={`/evento/${ev.id}`} key={ev.id} className="vc-event-item">
                    {ev.image ? (
                      <img src={ev.image} alt={ev.nome} className="vc-event-thumb" />
                    ) : (
                      <div className="vc-event-thumb-placeholder">
                        <svg viewBox="0 0 24 24">
                          <rect x="3" y="3" width="18" height="18" rx="2" />
                          <circle cx="8.5" cy="8.5" r="1.5" />
                          <polyline points="21 15 16 10 5 21" />
                        </svg>
                      </div>
                    )}

                    <div className="vc-event-info">
                      <div className="vc-event-name">{ev.nome}</div>
                      <div className="vc-event-meta">
                        <div className="vc-event-meta-row">
                          <svg viewBox="0 0 24 24">
                            <rect x="3" y="4" width="18" height="18" rx="2" />
                            <line x1="16" y1="2" x2="16" y2="6" />
                            <line x1="8" y1="2" x2="8" y2="6" />
                            <line x1="3" y1="10" x2="21" y2="10" />
                          </svg>
                          {ev.data}
                          <svg viewBox="0 0 24 24" style={{ marginLeft: '4px' }}>
                            <circle cx="12" cy="12" r="10" />
                            <polyline points="12 6 12 12 16 14" />
                          </svg>
                          {ev.hora}
                        </div>
                        <div className="vc-event-meta-row">
                          <svg viewBox="0 0 24 24">
                            <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                            <circle cx="12" cy="10" r="3" />
                          </svg>
                          {ev.local}
                        </div>
                      </div>
                      <div className="vc-event-confirmados">
                        <svg viewBox="0 0 24 24">
                          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                          <circle cx="9" cy="7" r="4" />
                          <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                          <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                        </svg>
                        {ev.confirmados}/{ev.capacidade} confirmados
                      </div>
                    </div>

                    <div className="vc-event-status-area">
                      <div className="vc-event-arrow">
                        <svg viewBox="0 0 24 24">
                          <line x1="5" y1="12" x2="19" y2="12" />
                          <polyline points="12 5 19 12 12 19" />
                        </svg>
                      </div>
                      <EventStatusBadge status={ev.status} />
                      <div className={`vc-event-countdown ${ev.status === 'andamento' ? 'vc-event-countdown--hoje' : ''}`}>
                        {ev.status === 'agendado' && ev.diasFaltando && `Faltam ${ev.diasFaltando} dias`}
                        {ev.status === 'andamento' && 'Evento hoje'}
                        {ev.status === 'realizado' && ev.dataRealizacao}
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            </div>

          </div>
        </div>
      </main>

      <Footer />
    </div>
  )
}
