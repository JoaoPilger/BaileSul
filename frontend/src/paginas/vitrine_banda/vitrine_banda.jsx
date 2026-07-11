import { useEffect, useState, useCallback } from 'react'
import { Link, useParams } from 'react-router-dom'
import { loadBandById } from '../../utils/bands'
import { useAuth } from '../../contexts/AuthContext'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import api from '../../services/api'
import './vitrine_banda.css'

const SEGUINDO_KEY = 'bailesul_seguindo_banda'
const AVALIACOES_KEY = 'bailesul_avaliacoes_banda'

function getSeguidos(userId) {
  if (!userId) return []
  try {
    return JSON.parse(localStorage.getItem(`${SEGUINDO_KEY}_${userId}`)) || []
  } catch {
    return []
  }
}

function toggleSeguir(userId, bandId) {
  if (!userId) return false
  const lista = getSeguidos(userId)
  const idx = lista.indexOf(String(bandId))
  if (idx >= 0) {
    lista.splice(idx, 1)
  } else {
    lista.push(String(bandId))
  }
  localStorage.setItem(`${SEGUINDO_KEY}_${userId}`, JSON.stringify(lista))
  return lista.includes(String(bandId))
}

function getAvaliacoes(bandId) {
  try {
    const all = JSON.parse(localStorage.getItem(AVALIACOES_KEY)) || {}
    return all[String(bandId)] || []
  } catch {
    return []
  }
}

function salvarAvaliacao(bandId, userId, nota) {
  try {
    const all = JSON.parse(localStorage.getItem(AVALIACOES_KEY)) || {}
    const lista = all[String(bandId)] || []
    const idx = lista.findIndex((a) => String(a.userId) === String(userId))
    if (idx >= 0) {
      lista[idx].nota = nota
    } else {
      lista.push({ userId, nota })
    }
    all[String(bandId)] = lista
    localStorage.setItem(AVALIACOES_KEY, JSON.stringify(all))
    return lista
  } catch {
    return []
  }
}

function formatDate(isoStr) {
  if (!isoStr) return ''
  const d = new Date(isoStr)
  if (isNaN(d)) return isoStr
  return d.toLocaleDateString('pt-BR')
}

function formatTime(isoStr) {
  if (!isoStr) return ''
  const d = new Date(isoStr)
  if (isNaN(d)) return ''
  return d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}

function StarsDisplay({ value }) {
  return (
    <div className="vb-stars">
      {[1, 2, 3, 4, 5].map((i) => (
        <svg key={i} className={`vb-star ${i > Math.round(value) ? 'vb-star--empty' : ''}`} viewBox="0 0 24 24">
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      ))}
    </div>
  )
}

function EventStatusBadge({ status }) {
  const map = {
    agendado:  { label: 'Agendado',     cls: 'vb-event-badge--agendado' },
    andamento: { label: 'Em andamento', cls: 'vb-event-badge--andamento' },
    realizado: { label: 'Realizado',    cls: 'vb-event-badge--realizado' },
  }
  const s = map[status] || map.agendado
  return <span className={`vb-event-badge ${s.cls}`}>{s.label}</span>
}

export default function VitrineBanda() {
  const { id } = useParams()
  const { usuario } = useAuth()
  const [banda, setBanda] = useState(null)
  const [isLoading, setIsLoading] = useState(true)
  const [erro, setErro] = useState(false)
  const [abaAtiva, setAbaAtiva] = useState('sobre')
  
  const [seguindo, setSeguindo] = useState(false)
  const [textoExpandido, setTextoExpandido] = useState(false)

  // Avaliação local interativa
  const [minhaNota, setMinhaNota] = useState(0)
  const [hoverNota, setHoverNota] = useState(0)
  const [avaliacoesList, setAvaliacoesList] = useState([])

  // Estados de edição do perfil (Dono da vitrine)
  const [modoEdicao, setModoEdicao] = useState(false)
  const [editNome, setEditNome] = useState('')
  const [editEstilo, setEditEstilo] = useState('')
  const [editDescricao, setEditDescricao] = useState('')
  const [editWhatsapp, setEditWhatsapp] = useState('')
  const [editVideoUrl, setEditVideoUrl] = useState('')
  
  // Upload de mídia na galeria (arquivo real do computador)
  const [novaMidiaArquivo, setNovaMidiaArquivo] = useState(null)
  const [novaMidiaPreview, setNovaMidiaPreview] = useState('')
  const [novaMidiaTipo, setNovaMidiaTipo] = useState('imagem')
  const [novaMidiaTitulo, setNovaMidiaTitulo] = useState('')
  const [showAddMidia, setShowAddMidia] = useState(false)
  const [enviandoMidia, setEnviandoMidia] = useState(false)

  const isDono = usuario && String(usuario.id) === String(id) && usuario.tipo === 'banda'

  useEffect(() => {
    const timer = setTimeout(() => {
      if (usuario) {
        setSeguindo(getSeguidos(usuario.id).includes(String(id)))
        const avs = getAvaliacoes(id)
        setAvaliacoesList(avs)
        const userAv = avs.find((a) => String(a.userId) === String(usuario.id))
        if (userAv) setMinhaNota(userAv.nota)
      } else {
        setSeguindo(false)
        setMinhaNota(0)
        setAvaliacoesList(getAvaliacoes(id))
      }
    }, 0)
    return () => clearTimeout(timer)
  }, [id, usuario])

  // Libera a URL temporária de preview quando o componente desmonta
  // ou quando um novo arquivo é escolhido, evitando vazamento de memória.
  useEffect(() => {
    return () => {
      if (novaMidiaPreview) URL.revokeObjectURL(novaMidiaPreview)
    }
  }, [novaMidiaPreview])

  const carregarBanda = useCallback(() => {
    setIsLoading(true)
    setErro(false)
    loadBandById(id).then((data) => {
      if (data) {
        setBanda(data)
        setEditNome(data.title || '')
        setEditEstilo(data.style || '')
        setEditDescricao(data.description || '')
        setEditWhatsapp(data.whatsapp || '')
        setEditVideoUrl(data.video_url || '')
      } else {
        setErro(true)
      }
      setIsLoading(false)
    }).catch(() => {
      setErro(true)
      setIsLoading(false)
    })
  }, [id])

  useEffect(() => {
    const timer = setTimeout(() => {
      carregarBanda()
    }, 0)
    return () => clearTimeout(timer)
  }, [carregarBanda])

  function handleSeguir() {
    if (!usuario) {
      alert('Você precisa estar logado para seguir esta banda!')
      return
    }
    const agora = toggleSeguir(usuario.id, id)
    setSeguindo(agora)
  }

  function handleContato() {
    if (banda?.whatsapp) {
      window.open(`https://wa.me/${banda.whatsapp}`, '_blank')
    }
  }

  function handleAvaliar(nota) {
    if (!usuario) {
      alert('Você precisa estar logado para avaliar esta banda!')
      return
    }
    const novaLista = salvarAvaliacao(id, usuario.id, nota)
    setAvaliacoesList(novaLista)
    setMinhaNota(nota)
  }

  async function handleSalvarPerfil() {
    try {
      await api.put('/bandas/me/perfil', {
        nome_artistico: editNome,
        estilo_musical: editEstilo,
        descricao: editDescricao,
        whatsapp: editWhatsapp,
        video_url: editVideoUrl,
      })
      alert('Perfil atualizado com sucesso no banco de dados!')
      setModoEdicao(false)
      carregarBanda()
    } catch (err) {
      console.error(err)
      alert(err.response?.data?.error || 'Erro ao atualizar perfil no banco de dados.')
    }
  }

  function handleSelecionarArquivo(e) {
    const file = e.target.files?.[0]
    if (!file) return
    if (novaMidiaPreview) URL.revokeObjectURL(novaMidiaPreview)
    setNovaMidiaArquivo(file)
    setNovaMidiaTipo(file.type.startsWith('video') ? 'video' : 'imagem')
    setNovaMidiaPreview(URL.createObjectURL(file))
  }

  function limparFormMidia() {
    if (novaMidiaPreview) URL.revokeObjectURL(novaMidiaPreview)
    setNovaMidiaArquivo(null)
    setNovaMidiaPreview('')
    setNovaMidiaTitulo('')
  }

  async function handleAdicionarMidia(e) {
    e.preventDefault()
    if (!novaMidiaArquivo) return
    setEnviandoMidia(true)
    try {
      const formData = new FormData()
      formData.append('arquivo', novaMidiaArquivo)
      if (novaMidiaTitulo) formData.append('titulo', novaMidiaTitulo)

      await api.post('/bandas/me/midias', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      alert('Mídia adicionada com sucesso na galeria!')
      setShowAddMidia(false)
      limparFormMidia()
      carregarBanda()
    } catch (err) {
      console.error(err)
      alert(err.response?.data?.error || 'Erro ao adicionar mídia.')
    } finally {
      setEnviandoMidia(false)
    }
  }

  async function handleRemoverMidia(midiaId) {
    if (!confirm('Deseja realmente remover esta mídia da galeria?')) return
    try {
      await api.delete(`/bandas/me/midias/${midiaId}`)
      alert('Mídia removida com sucesso!')
      carregarBanda()
    } catch (err) {
      console.error(err)
      alert('Erro ao remover mídia.')
    }
  }

  if (isLoading) {
    return (
      <div className="vb-shell">
        <Header />
        <main className="vb-main">
          <div className="vb-loading">
            <div className="vb-spinner" />
            <p>Carregando perfil da banda...</p>
          </div>
        </main>
        <Footer />
      </div>
    )
  }

  if (erro || !banda) {
    return (
      <div className="vb-shell">
        <Header />
        <main className="vb-main">
          <div className="vb-loading">
            <p>Banda não encontrada.</p>
            <Link to="/bandas" className="vb-btn-contato" style={{ marginTop: '12px' }}>
              Voltar para bandas
            </Link>
          </div>
        </main>
        <Footer />
      </div>
    )
  }

  const nome = banda.title || 'Banda'
  const sobre = banda.description || ''
  const estiloMusical = banda.style || ''
  const whatsapp = banda.whatsapp || ''
  const videoUrl = banda.video_url || ''
  const eventos = (banda.eventos || []).map((e) => ({
    id: e.id,
    nome: e.titulo || '',
    data: formatDate(e.data_inicio),
    hora: formatTime(e.data_inicio),
    local: [e.cidade, e.estado].filter(Boolean).join(', ') || e.local || '',
    localNome: e.local || '',
    comunidade: e.comunidade || '',
    status: 'agendado',
    image: '',
  }))
  const midias = (banda.midias || []).filter((m) => m.url)

  // Calcular stats dinamicamente das avaliações locais do localStorage
  const totalAvaliacoes = avaliacoesList.length
  const somaNotas = avaliacoesList.reduce((acc, curr) => acc + curr.nota, 0)
  const mediaAvaliacao = totalAvaliacoes > 0 ? parseFloat((somaNotas / totalAvaliacoes).toFixed(1)) : 0

  const avaliacaoBars = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 }
  avaliacoesList.forEach((av) => {
    if (avaliacaoBars[av.nota] !== undefined) {
      avaliacaoBars[av.nota] += 1
    }
  })

  const stats = {
    apresentacoes: eventos.length,
    seguidores: seguindo ? 1 : 0,
    avaliacao: mediaAvaliacao,
    totalAvaliacoes: totalAvaliacoes,
    proximosEventos: eventos.length,
  }

  return (
    <div className="vb-shell">
      <Header />

      <main className="vb-main">
        <div className="vb-layout">

          <div className="vb-col-left">

            <div className="vb-card vb-profile-card">
              <div className="vb-cover">
                <div className="vb-cover-placeholder">
                  <svg viewBox="0 0 24 24">
                    <rect x="3" y="3" width="18" height="18" rx="2" />
                    <circle cx="8.5" cy="8.5" r="1.5" />
                    <polyline points="21 15 16 10 5 21" />
                  </svg>
                </div>
              </div>

              <div className="vb-avatar-row">
                <div className="vb-avatar-wrap">
                  <div className="vb-avatar">
                    {editNome ? editNome.slice(0, 5) : nome.slice(0, 5)}
                  </div>
                </div>
                <span className="vb-seguidores-badge">
                  {stats.seguidores} Seguidores
                </span>
              </div>

              <div className="vb-profile-info">
                {modoEdicao ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', width: '100%', marginTop: '12px' }}>
                    <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Nome artístico:</label>
                    <input
                      className="vb-about-text"
                      style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)' }}
                      value={editNome}
                      onChange={(e) => setEditNome(e.target.value)}
                    />
                    <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Estilo musical:</label>
                    <input
                      className="vb-about-text"
                      style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)' }}
                      value={editEstilo}
                      onChange={(e) => setEditEstilo(e.target.value)}
                    />
                  </div>
                ) : (
                  <>
                    <div className="vb-band-name">{nome}</div>
                    {estiloMusical && (
                      <div className="vb-location-row">
                        <svg viewBox="0 0 24 24">
                          <path d="M9 18V5l12-2v13" />
                          <circle cx="6" cy="18" r="3" />
                          <circle cx="18" cy="16" r="3" />
                        </svg>
                        {estiloMusical}
                      </div>
                    )}
                  </>
                )}
              </div>

              <div className="vb-profile-actions">
                <button className="vb-btn-tag">Banda</button>
                {videoUrl && <button className="vb-btn-tag">Ao vivo</button>}
                
                {isDono ? (
                  modoEdicao ? (
                    <>
                      <button className="vb-btn-seguir" style={{ background: '#28a745', color: '#fff' }} onClick={handleSalvarPerfil}>
                        Salvar
                      </button>
                      <button className="vb-btn-contato" style={{ background: '#dc3545', color: '#fff' }} onClick={() => setModoEdicao(false)}>
                        Cancelar
                      </button>
                    </>
                  ) : (
                    <button className="vb-btn-seguir" onClick={() => setModoEdicao(true)}>
                      Editar Perfil
                    </button>
                  )
                ) : (
                  <button
                    className={`vb-btn-seguir ${seguindo ? 'vb-btn-seguir--seguindo' : ''}`}
                    onClick={handleSeguir}
                  >
                    {seguindo ? '✓ Seguindo' : 'Seguir'}
                  </button>
                )}
                
                <button
                  className="vb-btn-contato"
                  onClick={handleContato}
                  disabled={!whatsapp}
                  title={whatsapp ? `WhatsApp: ${whatsapp}` : 'Sem contato cadastrado'}
                >
                  Contato
                </button>
              </div>
            </div>

            <div className="vb-card vb-tabs-card">
              <div className="vb-tabs">
                {['sobre', 'eventos', 'galeria', 'avaliacoes'].map((aba) => (
                  <button
                    key={aba}
                    className={`vb-tab ${abaAtiva === aba ? 'active' : ''}`}
                    onClick={() => setAbaAtiva(aba)}
                  >
                    {aba === 'avaliacoes' ? 'Avaliações' : aba.charAt(0).toUpperCase() + aba.slice(1)}
                  </button>
                ))}
              </div>

              <div className="vb-tab-content">
                {abaAtiva === 'sobre' && (
                  <>
                    <div className="vb-section-title">Sobre a banda</div>
                    {modoEdicao ? (
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '8px' }}>
                        <textarea
                          rows={4}
                          className="vb-about-text"
                          style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)', width: '100%' }}
                          value={editDescricao}
                          onChange={(e) => setEditDescricao(e.target.value)}
                        />
                        <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>WhatsApp de Contato (Dígitos):</label>
                        <input
                          className="vb-about-text"
                          style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)' }}
                          value={editWhatsapp}
                          onChange={(e) => setEditWhatsapp(e.target.value)}
                          placeholder="Ex: 554999999999"
                        />
                        <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>URL de Vídeo Destaque (YouTube):</label>
                        <input
                          className="vb-about-text"
                          style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)' }}
                          value={editVideoUrl}
                          onChange={(e) => setEditVideoUrl(e.target.value)}
                          placeholder="https://youtube.com/..."
                        />
                      </div>
                    ) : (
                      <>
                        {sobre ? (
                          <>
                            <p className="vb-about-text">
                              {textoExpandido
                                ? sobre
                                : sobre.slice(0, 160) + (sobre.length > 160 ? '...' : '')}
                            </p>
                            {sobre.length > 160 && (
                              <button className="vb-ver-mais" onClick={() => setTextoExpandido(!textoExpandido)}>
                                {textoExpandido ? 'Ver menos ▲' : 'Ver mais ▼'}
                              </button>
                            )}
                          </>
                        ) : (
                          <p className="vb-about-text" style={{ opacity: 0.5 }}>
                            Nenhuma descrição cadastrada.
                          </p>
                        )}

                        <div className="vb-meta-grid">
                          {estiloMusical && (
                            <div className="vb-meta-item" style={{ gridColumn: '1 / -1' }}>
                              <div className="vb-meta-label">
                                <svg viewBox="0 0 24 24">
                                  <path d="M9 18V5l12-2v13" />
                                  <circle cx="6" cy="18" r="3" />
                                  <circle cx="18" cy="16" r="3" />
                                </svg>
                                Estilo musical
                              </div>
                              <span className="vb-meta-value">{estiloMusical}</span>
                            </div>
                          )}

                          {whatsapp && (
                            <div className="vb-meta-item">
                              <div className="vb-meta-label">
                                <svg viewBox="0 0 24 24">
                                  <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" />
                                </svg>
                                Contato
                              </div>
                              <span className="vb-meta-value">{whatsapp}</span>
                            </div>
                          )}

                          {videoUrl && (
                            <div className="vb-meta-item">
                              <div className="vb-meta-label">
                                <svg viewBox="0 0 24 24">
                                  <polygon points="23 7 16 12 23 17 23 7" />
                                  <rect x="1" y="5" width="15" height="14" rx="2" />
                                </svg>
                                Vídeo
                              </div>
                              <a
                                href={videoUrl}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="vb-meta-value"
                                style={{ color: 'var(--primary)', textDecoration: 'underline' }}
                              >
                                Assistir vídeo
                              </a>
                            </div>
                          )}
                        </div>
                      </>
                    )}
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

            <div className="vb-card vb-ratings-card" id="avaliacoes">
              <div className="vb-ratings-header">
                <span className="vb-ratings-title">Avaliações da banda</span>
              </div>

              <div className="vb-rating-big">
                <span className="vb-rating-score">{stats.avaliacao}</span>
                <div>
                  <StarsDisplay value={stats.avaliacao} />
                  <span className="vb-rating-count">
                    {stats.totalAvaliacoes === 0
                      ? 'Nenhuma avaliação ainda'
                      : `Baseado em ${stats.totalAvaliacoes} avaliações`}
                  </span>
                </div>
              </div>

              <div style={{ marginTop: '20px', padding: '15px', borderTop: '1px solid var(--border)' }}>
                <span style={{ fontSize: '0.9rem', fontWeight: 600, display: 'block', marginBottom: '8px' }}>
                  {usuario ? (minhaNota > 0 ? 'Sua avaliação enviada:' : 'Avalie esta banda:') : 'Faça login para avaliar esta banda'}
                </span>
                {usuario ? (
                  <div style={{ display: 'flex', gap: '4px' }}>
                    {[1, 2, 3, 4, 5].map((star) => (
                      <button
                        key={star}
                        type="button"
                        onClick={() => handleAvaliar(star)}
                        onMouseEnter={() => setHoverNota(star)}
                        onMouseLeave={() => setHoverNota(0)}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
                      >
                        <svg
                          style={{
                            width: '32px',
                            height: '32px',
                            fill: star <= (hoverNota || minhaNota) ? '#FFC107' : 'none',
                            stroke: '#FFC107',
                            strokeWidth: '1.5'
                          }}
                          viewBox="0 0 24 24"
                        >
                          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                        </svg>
                      </button>
                    ))}
                  </div>
                ) : (
                  <Link to="/login" className="vb-btn-contato" style={{ display: 'inline-block', textDecoration: 'none', fontSize: '0.85rem', padding: '6px 12px' }}>
                    Entrar
                  </Link>
                )}
              </div>

              <div className="vb-rating-bars" style={{ marginTop: '16px' }}>
                {[5, 4, 3, 2, 1].map((n) => (
                  <div key={n} className="vb-rating-bar-row">
                    <span className="vb-bar-label">{n}</span>
                    <div className="vb-bar-track">
                      <div
                        className="vb-bar-fill"
                        style={{ width: totalAvaliacoes > 0 ? `${((avaliacaoBars[n] || 0) / totalAvaliacoes) * 100}%` : '0%' }}
                      />
                    </div>
                    <span className="vb-bar-count">({avaliacaoBars[n] || 0})</span>
                  </div>
                ))}
              </div>
            </div>

          </div>

          <div className="vb-col-right">

            <div className="vb-card vb-stats-card">
              <div className="vb-stats-grid">
                {[
                  {
                    icon: <svg viewBox="0 0 24 24"><path d="M9 18V5l12-2v13" /><circle cx="6" cy="18" r="3" /><circle cx="18" cy="16" r="3" /></svg>,
                    value: stats.apresentacoes,
                    label: 'Apresentações em eventos',
                  },
                  {
                    icon: <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>,
                    value: stats.seguidores.toLocaleString('pt-BR'),
                    label: 'Seguidores',
                  },
                  {
                    icon: <svg viewBox="0 0 24 24"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>,
                    value: stats.avaliacao,
                    label: stats.totalAvaliacoes === 0 ? 'Sem avaliações' : `${stats.totalAvaliacoes} avaliações`,
                  },
                  {
                    icon: <svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /><line x1="12" y1="14" x2="12" y2="18" /><line x1="10" y1="16" x2="14" y2="16" /></svg>,
                    value: stats.proximosEventos,
                    label: 'Próximos eventos',
                  },
                ].map((s, i) => (
                  <div key={i} className="vb-stat-item">
                    <div className="vb-stat-icon">{s.icon}</div>
                    <span className="vb-stat-value">{s.value}</span>
                    <span className="vb-stat-label">{s.label}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="vb-card vb-gallery-card">
              <div className="vb-gallery-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span className="vb-gallery-title">Galeria</span>
                {isDono && (
                  <button
                    className="vb-btn-tag"
                    style={{ cursor: 'pointer', background: 'var(--accent)', color: '#fff', border: 'none' }}
                    onClick={() => {
                      if (showAddMidia) limparFormMidia()
                      setShowAddMidia(!showAddMidia)
                    }}
                  >
                    {showAddMidia ? 'Fechar' : 'Adicionar Mídia'}
                  </button>
                )}
              </div>

              {showAddMidia && (
                <form onSubmit={handleAdicionarMidia} className="vb-upload-form">
                  <label className="vb-upload-dropzone" htmlFor="banda-midia-input">
                    {novaMidiaPreview ? (
                      novaMidiaTipo === 'video' ? (
                        <video src={novaMidiaPreview} className="vb-upload-preview" controls />
                      ) : (
                        <img src={novaMidiaPreview} alt="Pré-visualização" className="vb-upload-preview" />
                      )
                    ) : (
                      <div className="vb-upload-placeholder">
                        <svg viewBox="0 0 24 24">
                          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                          <polyline points="17 8 12 3 7 8" />
                          <line x1="12" y1="3" x2="12" y2="15" />
                        </svg>
                        <span>Clique para escolher uma foto ou vídeo do seu computador</span>
                      </div>
                    )}
                    <input
                      id="banda-midia-input"
                      type="file"
                      accept="image/*,video/*"
                      onChange={handleSelecionarArquivo}
                      className="vb-upload-input-hidden"
                    />
                  </label>

                  {novaMidiaArquivo && (
                    <button
                      type="button"
                      className="vb-upload-trocar"
                      onClick={() => document.getElementById('banda-midia-input').click()}
                    >
                      Trocar arquivo
                    </button>
                  )}

                  <label className="vb-upload-field-label">Título (opcional):</label>
                  <input
                    placeholder="Foto de show..."
                    className="vb-upload-text-input"
                    value={novaMidiaTitulo}
                    onChange={(e) => setNovaMidiaTitulo(e.target.value)}
                  />

                  <button
                    type="submit"
                    className="vb-btn-contato vb-upload-submit"
                    disabled={!novaMidiaArquivo || enviandoMidia}
                  >
                    {enviandoMidia ? 'Enviando...' : 'Salvar na Galeria'}
                  </button>
                </form>
              )}

              <div className="vb-gallery-carousel">
                <div className="vb-gallery-track" style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                  {midias.length === 0 ? (
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', textAlign: 'center', padding: '20px 0', width: '100%' }}>
                      Nenhuma imagem ou vídeo na galeria
                    </div>
                  ) : (
                    midias.map((img) => (
                      <div key={img.id} className="vb-gallery-item" style={{ position: 'relative', width: 'calc(50% - 5px)', minHeight: '120px' }}>
                        {img.tipo === 'video' ? (
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#000', color: '#fff', width: '100%', height: '100%', borderRadius: '8px', fontSize: '0.8rem', textDecoration: 'none' }}>
                            <a href={img.url} target="_blank" rel="noopener noreferrer" style={{ color: '#fff' }}>
                              Assistir Vídeo
                            </a>
                          </div>
                        ) : (
                          <img src={img.url} alt={img.titulo || 'Imagem'} style={{ objectFit: 'cover', width: '100%', height: '100%', borderRadius: '8px' }} />
                        )}
                        {isDono && (
                          <button
                          type="button"
                          onClick={() => handleRemoverMidia(img.id)}
                          style={{ 
                            position: 'absolute', 
                            top: '5px', 
                            right: '5px', 
                            background: '#dc3545', 
                            border: 'none', 
                            color: '#fff', 
                            padding: '6px', 
                            borderRadius: '4px', 
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center'
                          }}
                          title="Remover mídia"
                        >
                          <svg 
                            xmlns="http://www.w3.org/2000/svg" 
                            width="16" 
                            height="16" 
                            viewBox="0 0 24 24" 
                            fill="none" 
                            stroke="currentColor" 
                            strokeWidth="2.5" 
                            strokeLinecap="round" 
                            strokeLinejoin="round"
                          >
                            <polyline points="3 6 5 6 21 6"></polyline>
                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                            <line x1="10" y1="11" x2="10" y2="17"></line>
                            <line x1="14" y1="11" x2="14" y2="17"></line>
                          </svg>
                        </button>
                        )}
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>

            <div className="vb-card vb-events-card">
              <div className="vb-events-header">
                <span className="vb-events-title">Próximos eventos</span>
                <Link to="/eventos" className="vb-ver-todos">Ver todos os eventos</Link>
              </div>

              <div className="vb-events-list">
                {eventos.length === 0 ? (
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', textAlign: 'center', padding: '20px 0' }}>
                    Nenhum evento agendado
                  </div>
                ) : (
                  eventos.map((ev) => (
                    <Link to={`/eventos/${ev.id}`} key={ev.id} className="vb-event-item">
                      {ev.image ? (
                        <img src={ev.image} alt={ev.nome} className="vb-event-thumb" />
                      ) : (
                        <div className="vb-event-thumb-placeholder">
                          <svg viewBox="0 0 24 24">
                            <rect x="3" y="3" width="18" height="18" rx="2" />
                            <circle cx="8.5" cy="8.5" r="1.5" />
                            <polyline points="21 15 16 10 5 21" />
                          </svg>
                        </div>
                      )}

                      <div className="vb-event-info">
                        <div className="vb-event-name">{ev.nome}</div>
                        <div className="vb-event-meta">
                          <div className="vb-event-meta-row">
                            <svg viewBox="0 0 24 24">
                              <rect x="3" y="4" width="18" height="18" rx="2" />
                              <line x1="16" y1="2" x2="16" y2="6" />
                              <line x1="8" y1="2" x2="8" y2="6" />
                              <line x1="3" y1="10" x2="21" y2="10" />
                            </svg>
                            {ev.data}
                            {ev.hora && (
                              <>
                                <svg viewBox="0 0 24 24" style={{ marginLeft: '4px' }}>
                                  <circle cx="12" cy="12" r="10" />
                                  <polyline points="12 6 12 12 16 14" />
                                </svg>
                                {ev.hora}
                              </>
                            )}
                          </div>
                          {ev.local && (
                            <div className="vb-event-meta-row">
                              <svg viewBox="0 0 24 24">
                                <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                                <circle cx="12" cy="10" r="3" />
                              </svg>
                              {ev.local}
                            </div>
                          )}
                          {ev.comunidade && (
                            <div className="vb-event-meta-row">
                              <svg viewBox="0 0 24 24">
                                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                                <circle cx="9" cy="7" r="4" />
                              </svg>
                              {ev.comunidade}
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="vb-event-status-area">
                        <div className="vb-event-arrow">
                          <svg viewBox="0 0 24 24">
                            <line x1="5" y1="12" x2="19" y2="12" />
                            <polyline points="12 5 19 12 12 19" />
                          </svg>
                        </div>
                        <EventStatusBadge status={ev.status} />
                      </div>
                    </Link>
                  ))
                )}
              </div>
            </div>

          </div>
        </div>
      </main>

      <Footer />
    </div>
  )
}