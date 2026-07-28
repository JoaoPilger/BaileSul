import { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { fetchEventoDashboard } from '../../utils/events'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import styles from './dashboard_evento.module.css'

// ─────────────────────────────────────────────────────────────
//  Ícones SVG inline
// ─────────────────────────────────────────────────────────────
function Icon({ d, children, size = 18 }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
    >
      {d ? <path d={d} /> : children}
    </svg>
  )
}

// ─────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────
function formatBRL(value) {
  if (!value && value !== 0) return 'R$ 0,00'
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value)
}

function formatDate(str) {
  if (!str) return '—'
  const s = str.split('T')[0]
  const [y, m, d] = s.split('-')
  return `${d}/${m}/${y}`
}

function formatDateTime(str) {
  if (!str) return '—'
  const dt = new Date(str)
  return dt.toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

function StatusBadge({ status }) {
  const map = {
    pendente:   { label: 'Pendente',   cls: 'dash-badge--pendente' },
    confirmado: { label: 'Confirmado', cls: 'dash-badge--confirmado' },
    cancelado:  { label: 'Cancelado',  cls: 'dash-badge--cancelado' },
    rejeitado:  { label: 'Rejeitado',  cls: 'dash-badge--rejeitado' },
    aceito:     { label: 'Aceito',     cls: 'dash-badge--confirmado' },
    recusado:   { label: 'Recusado',   cls: 'dash-badge--rejeitado' },
    agendado:   { label: 'Agendado',   cls: 'dash-badge--pendente' },
    finalizado: { label: 'Realizado',  cls: 'dash-badge--confirmado' },
  }
  const s = map[status] || { label: status, cls: 'dash-badge--pendente' }
  return <span className={`${styles['dash-badge']} ${styles[s.cls]}`}>{s.label}</span>
}

// ─────────────────────────────────────────────────────────────
//  Gráfico de crescimento (SVG puro — sem lib externa)
// ─────────────────────────────────────────────────────────────
function GraficoCrescimento({ dados }) {
  if (!dados || dados.length === 0) {
    return (
      <div className={styles['dash-chart-empty']}>
        <Icon size={32}><circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" /></Icon>
        <p>Nenhuma reserva registrada ainda</p>
      </div>
    )
  }

  const W = 580
  const H = 160
  const padL = 36
  const padR = 16
  const padT = 16
  const padB = 40

  const maxVal = Math.max(...dados.map(d => d.novas_reservas), 1)
  const xStep = (W - padL - padR) / Math.max(dados.length - 1, 1)

  const pts = dados.map((d, i) => {
    const x = padL + i * xStep
    const y = padT + (H - padT - padB) * (1 - d.novas_reservas / maxVal)
    return { x, y, d }
  })

  const polyline = pts.map(p => `${p.x},${p.y}`).join(' ')
  const area = [
    `${pts[0].x},${H - padB}`,
    ...pts.map(p => `${p.x},${p.y}`),
    `${pts[pts.length - 1].x},${H - padB}`,
  ].join(' ')

  // Etiquetas do eixo X (mostrar até 6)
  const step = Math.ceil(dados.length / 6)
  const xLabels = pts.filter((_, i) => i % step === 0)

  return (
    <div className={styles['dash-chart-wrap']}>
      <svg viewBox={`0 0 ${W} ${H}`} className={styles['dash-chart-svg']} role="img" aria-label="Gráfico de crescimento de reservas">
        {/* Área preenchida */}
        <polygon points={area} className={styles['dash-chart-area']} />
        {/* Linha */}
        <polyline points={polyline} className={styles['dash-chart-line']} />
        {/* Pontos */}
        {pts.map((p, i) => (
          <circle key={i} cx={p.x} cy={p.y} r="4" className={styles['dash-chart-dot']}>
            <title>{formatDate(p.d.data)}: {p.d.novas_reservas} reserva(s)</title>
          </circle>
        ))}
        {/* Eixo Y — linha base */}
        <line x1={padL} y1={padT} x2={padL} y2={H - padB} className={styles['dash-chart-axis']} />
        {/* Eixo X — linha base */}
        <line x1={padL} y1={H - padB} x2={W - padR} y2={H - padB} className={styles['dash-chart-axis']} />
        {/* Labels eixo Y */}
        <text x={padL - 4} y={padT + 4} className={styles['dash-chart-label']} textAnchor="end">{maxVal}</text>
        <text x={padL - 4} y={H - padB + 4} className={styles['dash-chart-label']} textAnchor="end">0</text>
        {/* Labels eixo X */}
        {xLabels.map((p, i) => (
          <text key={i} x={p.x} y={H - padB + 14} className={styles['dash-chart-label']} textAnchor="middle">
            {formatDate(p.d.data).slice(0, 5)}
          </text>
        ))}
      </svg>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
//  Aba: Visão Geral
// ─────────────────────────────────────────────────────────────
function AbaVisaoGeral({ metricas, crescimento }) {
  const cap = metricas?.capacidade_maxima
  const confirmados = metricas?.total_ingressos_confirmados ?? 0
  const pct = cap ? Math.min(Math.round((confirmados / cap) * 100), 100) : null

  const kpis = [
    {
      label: 'Reservas Totais',
      value: metricas?.total_reservas ?? 0,
      tone: 'blue',
      icon: <Icon><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></Icon>,
    },
    {
      label: 'Confirmadas',
      value: metricas?.reservas_confirmadas ?? 0,
      tone: 'green',
      icon: <Icon><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></Icon>,
    },
    {
      label: 'Pendentes',
      value: metricas?.reservas_pendentes ?? 0,
      tone: 'warning',
      icon: <Icon><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></Icon>,
    },
    {
      label: 'Ingressos Confirmados',
      value: metricas?.total_ingressos_confirmados ?? 0,
      tone: 'accent',
      icon: <Icon><path d="M20 12V22H4V12" /><path d="M22 7H2v5h20V7z" /><path d="M12 22V7" /><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z" /><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z" /></Icon>,
    },
    {
      label: 'Receita Estimada',
      value: formatBRL(metricas?.receita_estimada),
      tone: 'emerald',
      icon: <Icon><line x1="12" y1="1" x2="12" y2="23" /><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" /></Icon>,
      wide: true,
    },
  ]

  return (
    <div className={styles['dash-tab-content']}>
      <div className={styles['dash-kpi-grid']}>
        {kpis.map(k => (
          <div key={k.label} className={`${styles['dash-kpi-card']} ${styles[`dash-kpi--${k.tone}`]} ${k.wide ? styles['dash-kpi--wide'] : ''}`}>
            <div className={styles['dash-kpi-icon']}>{k.icon}</div>
            <div className={styles['dash-kpi-info']}>
              <span className={styles['dash-kpi-label']}>{k.label}</span>
              <span className={styles['dash-kpi-value']}>{k.value}</span>
            </div>
          </div>
        ))}
      </div>

      {cap !== null && cap !== undefined && (
        <div className={styles['dash-capacity-card']}>
          <div className={styles['dash-capacity-header']}>
            <span className={styles['dash-capacity-label']}>Ocupação de Ingressos</span>
            <span className={styles['dash-capacity-pct']}>{pct ?? 0}%</span>
          </div>
          <div className={styles['dash-capacity-bar']}>
            <div
              className={styles['dash-capacity-fill']}
              style={{ width: `${pct ?? 0}%` }}
              role="progressbar"
              aria-valuenow={pct ?? 0}
              aria-valuemin={0}
              aria-valuemax={100}
            />
          </div>
          <div className={styles['dash-capacity-sub']}>
            {confirmados} de {cap} ingressos confirmados
          </div>
        </div>
      )}

      <div className={styles['dash-chart-card']}>
        <h3 className={styles['dash-chart-title']}>Crescimento de Reservas por Dia</h3>
        <GraficoCrescimento dados={crescimento} />
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
//  Aba: Reservas
// ─────────────────────────────────────────────────────────────
function AbaReservas({ reservas }) {
  const [filtro, setFiltro] = useState('todos')
  const [busca, setBusca] = useState('')

  const filtradas = (reservas || []).filter(r => {
    const matchStatus = filtro === 'todos' || r.status_pagamento === filtro
    const q = busca.toLowerCase()
    const matchBusca = !busca
      || (r.comprador_nome || '').toLowerCase().includes(q)
      || (r.comprador_email || '').toLowerCase().includes(q)
      || (r.vendedor_nome || '').toLowerCase().includes(q)
    return matchStatus && matchBusca
  })

  return (
    <div className={styles['dash-tab-content']}>
      <div className={styles['dash-toolbar']}>
        <div className={styles['dash-search']}>
          <Icon><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></Icon>
          <input
            type="text"
            placeholder="Buscar por comprador ou vendedor..."
            value={busca}
            onChange={e => setBusca(e.target.value)}
          />
        </div>
        <div className={styles['dash-filter-group']}>
          {['todos', 'pendente', 'confirmado', 'cancelado', 'rejeitado'].map(s => (
            <button
              key={s}
              className={`${styles['dash-filter-btn']} ${filtro === s ? styles.active : ''}`}
              onClick={() => setFiltro(s)}
            >
              {s === 'todos' ? 'Todos' : s.charAt(0).toUpperCase() + s.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {filtradas.length === 0 ? (
        <div className={styles['dash-empty']}>Nenhuma reserva encontrada.</div>
      ) : (
        <div className={styles['dash-table-wrap']}>
          <table className={styles['dash-table']}>
            <thead>
              <tr>
                <th>#</th>
                <th>Comprador</th>
                <th>Qtd</th>
                <th>Pagamento</th>
                <th>Vendedor</th>
                <th>Status</th>
                <th>Data</th>
              </tr>
            </thead>
            <tbody>
              {filtradas.map(r => (
                <tr key={r.id}>
                  <td className={styles['dash-td-id']}>#{r.id}</td>
                  <td>
                    <div className={styles['dash-td-name']}>{r.comprador_nome || '—'}</div>
                    <div className={styles['dash-td-sub']}>{r.comprador_email}</div>
                    {r.nome_retirada && <div className={styles['dash-td-sub']}>Retirada: {r.nome_retirada}</div>}
                  </td>
                  <td className={styles['dash-td-center']}>{r.quantidade}</td>
                  <td className={styles['dash-td-center']}>{r.forma_pagamento}</td>
                  <td>
                    {r.vendedor_nome
                      ? <>
                          <div className={styles['dash-td-name']}>{r.vendedor_nome}</div>
                          <div className={styles['dash-td-sub']}>{r.vendedor_whatsapp}</div>
                        </>
                      : <span className={styles['dash-td-muted']}>—</span>}
                  </td>
                  <td><StatusBadge status={r.status_pagamento} /></td>
                  <td className={styles['dash-td-date']}>{formatDateTime(r.criado_em)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
//  Aba: Vendedores
// ─────────────────────────────────────────────────────────────
function AbaVendedores({ vendedores, onGerenciar }) {
  return (
    <div className={styles['dash-tab-content']}>
      <div className={styles['dash-section-header']}>
        <p className={styles['dash-section-desc']}>
          Esses são os vendedores ativos da sua comunidade. Todos podem receber reservas deste evento.
        </p>
        <button className={styles['dash-btn-primary']} onClick={onGerenciar}>
          <Icon><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></Icon>
          Gerenciar Vendedores
        </button>
      </div>

      {(!vendedores || vendedores.length === 0) ? (
        <div className={styles['dash-empty']}>
          Nenhum vendedor ativo. Adicione vendedores em Gerenciar Vendedores.
        </div>
      ) : (
        <div className={styles['dash-vendor-grid']}>
          {vendedores.map(v => (
            <div key={v.id} className={styles['dash-vendor-card']}>
              <div className={styles['dash-vendor-avatar']}>
                {(v.nome || 'V').charAt(0).toUpperCase()}
              </div>
              <div className={styles['dash-vendor-info']}>
                <div className={styles['dash-vendor-name']}>{v.nome}</div>
                <div className={styles['dash-vendor-phone']}>
                  <Icon size={13}><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 13 19.79 19.79 0 0 1 1.61 4.38 2 2 0 0 1 3.6 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.4a16 16 0 0 0 6.29 6.29l.95-.95a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" /></Icon>
                  {v.whatsapp}
                </div>
              </div>
              <div className={styles['dash-vendor-stats']}>
                <div className={styles['dash-vendor-stat']}>
                  <span className={styles['dash-vendor-stat-val']}>{v.ingressos_vendidos_evento ?? 0}</span>
                  <span className={styles['dash-vendor-stat-lbl']}>ingressos</span>
                </div>
                <div className={styles['dash-vendor-stat']}>
                  <span className={styles['dash-vendor-stat-val']}>{formatBRL(v.receita_evento ?? 0)}</span>
                  <span className={styles['dash-vendor-stat-lbl']}>receita</span>
                </div>
              </div>
              <a
                href={`https://wa.me/${(v.whatsapp || '').replace(/\D/g, '')}`}
                target="_blank"
                rel="noopener noreferrer"
                className={styles['dash-btn-whatsapp']}
                aria-label={`Contato WhatsApp de ${v.nome}`}
              >
                <Icon size={16}><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" /></Icon>
              </a>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
//  Aba: Bandas
// ─────────────────────────────────────────────────────────────
function AbaBandas({ bandas }) {
  return (
    <div className={styles['dash-tab-content']}>
      {(!bandas || bandas.length === 0) ? (
        <div className={styles['dash-empty']}>Nenhuma banda convidada para este evento.</div>
      ) : (
        <div className={styles['dash-table-wrap']}>
          <table className={styles['dash-table']}>
            <thead>
              <tr>
                <th>Banda / Artista</th>
                <th>Estilo</th>
                <th>WhatsApp</th>
                <th>Status Contrato</th>
                <th>Assinatura</th>
              </tr>
            </thead>
            <tbody>
              {bandas.map(b => (
                <tr key={b.contrato_id}>
                  <td className={styles['dash-td-name']}>{b.nome_artistico}</td>
                  <td>{b.estilo_musical || '—'}</td>
                  <td>
                    {b.whatsapp
                      ? <a href={`https://wa.me/${b.whatsapp.replace(/\D/g, '')}`} target="_blank" rel="noopener noreferrer" className={styles['dash-link']}>{b.whatsapp}</a>
                      : '—'}
                  </td>
                  <td><StatusBadge status={b.status_aceite} /></td>
                  <td className={styles['dash-td-date']}>{formatDateTime(b.data_assinatura)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
//  Aba: Dias
// ─────────────────────────────────────────────────────────────
function AbaDias({ dias }) {
  return (
    <div className={styles['dash-tab-content']}>
      {(!dias || dias.length === 0) ? (
        <div className={styles['dash-empty']}>Nenhum dia cadastrado para este evento.</div>
      ) : (
        <div className={styles['dash-table-wrap']}>
          <table className={styles['dash-table']}>
            <thead>
              <tr>
                <th>Data</th>
                <th>Encerra em</th>
                <th>Início</th>
                <th>Fim</th>
                <th>Observação</th>
              </tr>
            </thead>
            <tbody>
              {dias.map(d => (
                <tr key={d.id}>
                  <td>{formatDate(d.data)}</td>
                  <td>{formatDate(d.data_fim_dia)}</td>
                  <td>{d.hora_inicio?.slice(0, 5) || '—'}</td>
                  <td>{d.hora_fim?.slice(0, 5) || '—'}</td>
                  <td className={styles['dash-td-obs']}>{d.observacao || '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
//  Aba: Histórico
// ─────────────────────────────────────────────────────────────
function AbaHistorico({ historico }) {
  const statusIcon = { confirmado: '✓', cancelado: '✕', rejeitado: '✕', pendente: '…' }

  return (
    <div className={styles['dash-tab-content']}>
      {(!historico || historico.length === 0) ? (
        <div className={styles['dash-empty']}>Nenhuma alteração de pagamento registrada ainda.</div>
      ) : (
        <div className={styles['dash-timeline']}>
          {historico.map(h => (
            <div key={h.id} className={styles['dash-timeline-item']}>
              <div className={`${styles['dash-timeline-dot']} ${styles[`dash-tl--${h.status_novo}`]}`}>
                {statusIcon[h.status_novo] || '•'}
              </div>
              <div className={styles['dash-timeline-body']}>
                <div className={styles['dash-timeline-title']}>
                  Reserva <strong>#{h.reserva_id}</strong> —{' '}
                  <StatusBadge status={h.status_anterior} />
                  <span className={styles['dash-timeline-arrow']}> → </span>
                  <StatusBadge status={h.status_novo} />
                </div>
                <div className={styles['dash-timeline-meta']}>
                  {h.operador_nome || h.operador_email || 'Sistema'} · {formatDateTime(h.criado_em)}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

// ─────────────────────────────────────────────────────────────
//  Componente principal: EventoDashboard
// ─────────────────────────────────────────────────────────────
const TABS = [
  { key: 'geral',      label: 'Visão Geral' },
  { key: 'reservas',   label: 'Reservas' },
  { key: 'vendedores', label: 'Vendedores' },
  { key: 'bandas',     label: 'Bandas' },
  { key: 'dias',       label: 'Dias' },
  { key: 'historico',  label: 'Histórico' },
]

const DEFAULT_IMAGE = 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1200&q=80'

export default function EventoDashboard({ eventoId }) {
  const navigate = useNavigate()
  const [dados, setDados] = useState(null)
  const [carregando, setCarregando] = useState(true)
  const [erro, setErro] = useState('')
  const [abaAtiva, setAbaAtiva] = useState('geral')

  const carregar = useCallback(async () => {
    setCarregando(true)
    const resultado = await fetchEventoDashboard(eventoId)
    if (resultado) {
      setDados(resultado)
    } else {
      setErro('Não foi possível carregar o dashboard do evento.')
    }
    setCarregando(false)
  }, [eventoId])

  useEffect(() => { carregar() }, [carregar])

  if (carregando) {
    return (
      <div className={styles['dash-shell']}>
        <Header />
        <main className={styles['dash-main']}>
          <div className={styles['dash-loading']}>
            <div className={styles['dash-spinner']} />
            <p>Carregando dashboard...</p>
          </div>
        </main>
        <Footer />
      </div>
    )
  }

  if (erro || !dados) {
    return (
      <div className={styles['dash-shell']}>
        <Header />
        <main className={styles['dash-main']}>
          <div className={styles['dash-error']}>
            <p>{erro || 'Erro desconhecido.'}</p>
            <button className={styles['dash-btn-primary']} onClick={() => navigate(-1)}>Voltar</button>
          </div>
        </main>
        <Footer />
      </div>
    )
  }

  const { evento, metricas, reservas, vendedores, bandas, dias, historico_pagamentos, crescimento } = dados

  const imageSrc = evento.foto_capa_url || DEFAULT_IMAGE
  const imageFinal = imageSrc.includes('/media/')
    ? imageSrc.substring(imageSrc.indexOf('/media/'))
    : imageSrc

  return (
    <div className={styles['dash-shell']}>
      <Header />

      {/* ── Foto de capa ── */}
      <div className={styles['dash-hero']}>
        <img src={imageFinal} alt={evento.titulo} className={styles['dash-hero-img']} />
      </div>

      <main className={styles['dash-main']}>
        <button type="button" className={styles['dash-back-btn']} onClick={() => navigate(-1)}>
          <Icon size={14}><line x1="19" y1="12" x2="5" y2="12" /><polyline points="12 19 5 12 12 5" /></Icon>
          Voltar
        </button>

        {/* ── Cabeçalho do evento ── */}
        <div className={styles['dash-header-card']}>
          <div className={styles['dash-header-info']}>
            <div className={styles['dash-hero-badges']}>
              <StatusBadge status={evento.status} />
              {evento.tipo_evento && (
                <span className={styles['dash-hero-type']}>{evento.tipo_evento.replace(/_/g, ' ')}</span>
              )}
            </div>
            <h1 className={styles['dash-hero-title']}>{evento.titulo}</h1>
            <div className={styles['dash-hero-meta']}>
              <span>
                <Icon size={14}><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></Icon>
                {formatDate(evento.data_inicio)}
                {evento.data_fim !== evento.data_inicio && ` – ${formatDate(evento.data_fim)}`}
              </span>
              {evento.local_nome && (
                <span>
                  <Icon size={14}><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></Icon>
                  {evento.local_nome}
                </span>
              )}
              <span>
                <Icon size={14}><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /></Icon>
                {evento.comunidade}
              </span>
            </div>
          </div>
          <div className={styles['dash-hero-actions']}>
            <button
              className={styles['dash-btn-ghost']}
              onClick={() => navigate(`/criar-evento`)}
            >
              <Icon size={15}><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" /></Icon>
              Editar Evento
            </button>
            <button className={styles['dash-btn-primary']} onClick={carregar}>
              <Icon size={15}><polyline points="23 4 23 10 17 10" /><path d="M20.49 15a9 9 0 1 1-.54-4.61" /></Icon>
              Atualizar
            </button>
          </div>
        </div>

        {/* ── Abas de navegação + conteúdo ── */}
        <div className={styles['dash-tabs-card']}>
          <div className={styles['dash-tabs-bar']} role="tablist">
            {TABS.map(t => (
              <button
                key={t.key}
                id={`dash-tab-${t.key}`}
                className={`${styles['dash-tab']} ${abaAtiva === t.key ? styles['dash-tab--active'] : ''}`}
                onClick={() => setAbaAtiva(t.key)}
                aria-selected={abaAtiva === t.key}
                role="tab"
              >
                {t.label}
                {t.key === 'reservas' && metricas?.reservas_pendentes > 0 && (
                  <span className={styles['dash-tab-badge']}>{metricas.reservas_pendentes}</span>
                )}
              </button>
            ))}
          </div>

          <div className={styles['dash-body']} role="tabpanel" aria-labelledby={`dash-tab-${abaAtiva}`}>
            {abaAtiva === 'geral'      && <AbaVisaoGeral metricas={metricas} crescimento={crescimento} />}
            {abaAtiva === 'reservas'   && <AbaReservas reservas={reservas} />}
            {abaAtiva === 'vendedores' && <AbaVendedores vendedores={vendedores} onGerenciar={() => navigate('/vendedores')} />}
            {abaAtiva === 'bandas'     && <AbaBandas bandas={bandas} />}
            {abaAtiva === 'dias'       && <AbaDias dias={dias} />}
            {abaAtiva === 'historico'  && <AbaHistorico historico={historico_pagamentos} />}
          </div>
        </div>
      </main>

      <Footer />
    </div>
  )
}
