import { useEffect, useState, useCallback } from 'react'
import { cn } from '../../utils/cn'
import { Link, useParams } from 'react-router-dom'
import { loadCommunityById } from '../../utils/communities'
import { useAuth } from '../../contexts/AuthContext'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import api from '../../services/api'
import styles from './vitrine_comunidade.module.css'

const SEGUINDO_KEY = 'bailesul_seguindo_comunidade'
const AVALIACOES_KEY = 'bailesul_avaliacoes_comunidade'

function getSeguidos(userId) {
  if (!userId) return []
  try {
    return JSON.parse(localStorage.getItem(`${SEGUINDO_KEY}_${userId}`)) || []
  } catch {
    return []
  }
}

function toggleSeguir(userId, communityId) {
  if (!userId) return false
  const lista = getSeguidos(userId)
  const idx = lista.indexOf(String(communityId))
  if (idx >= 0) {
    lista.splice(idx, 1)
  } else {
    lista.push(String(communityId))
  }
  localStorage.setItem(`${SEGUINDO_KEY}_${userId}`, JSON.stringify(lista))
  return lista.includes(String(communityId))
}

function getAvaliacoes(communityId) {
  try {
    const all = JSON.parse(localStorage.getItem(AVALIACOES_KEY)) || {}
    return all[String(communityId)] || []
  } catch {
    return []
  }
}

function salvarAvaliacao(communityId, userId, nota) {
  try {
    const all = JSON.parse(localStorage.getItem(AVALIACOES_KEY)) || {}
    const lista = all[String(communityId)] || []
    const idx = lista.findIndex((a) => String(a.userId) === String(userId))
    if (idx >= 0) {
      lista[idx].nota = nota
    } else {
      lista.push({ userId, nota })
    }
    all[String(communityId)] = lista
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

function formatPrice(valor) {
  if (valor === null || valor === undefined) return ''
  const v = parseFloat(valor)
  if (isNaN(v) || v <= 0) return 'Grátis'
  return `R$ ${v.toFixed(2).replace('.', ',')}`
}

function StarsDisplay({ value }) {
  return (
    <div className={styles['vc-stars']}>
      {[1, 2, 3, 4, 5].map((i) => (
        <svg key={i} className={cn(styles['vc-star'], i > Math.round(value) && styles['vc-star--empty'])} viewBox="0 0 24 24">
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
  return <span className={cn(styles['vc-event-badge'], styles[s.cls])}>{s.label}</span>
}

export default function VitrineComunidade() {
  const { id } = useParams()
  const { usuario } = useAuth()
  const [comunidade, setComunidade] = useState(null)
  const [isLoading, setIsLoading] = useState(true)
  const [erro, setErro] = useState(false)
  const [abaAtiva, setAbaAtiva] = useState('sobre')
  
  const [seguindo, setSeguindo] = useState(false)
  const [textoExpandido, setTextoExpandido] = useState(false)

  // Avaliação local interativa
  const [minhaNota, setMinhaNota] = useState(0)
  const [hoverNota, setHoverNota] = useState(0)
  const [avaliacoesList, setAvaliacoesList] = useState([])

  // Edição perfil
  const [modoEdicao, setModoEdicao] = useState(false)
  const [editNome, setEditNome] = useState('')
  const [editDescricao, setEditDescricao] = useState('')
  const [editCidade, setEditCidade] = useState('')
  const [editEstado, setEditEstado] = useState('')
  const [editEndereco, setEditEndereco] = useState('')
  const [editWhatsapp, setEditWhatsapp] = useState('')

  // Upload de mídia na galeria (arquivo real do computador)
  const [novaMidiaArquivo, setNovaMidiaArquivo] = useState(null)
  const [novaMidiaPreview, setNovaMidiaPreview] = useState('')
  const [novaMidiaTipo, setNovaMidiaTipo] = useState('imagem')
  const [novaMidiaTitulo, setNovaMidiaTitulo] = useState('')
  const [showAddMidia, setShowAddMidia] = useState(false)
  const [enviandoMidia, setEnviandoMidia] = useState(false)

  const isDono = usuario && String(usuario.id) === String(id) && usuario.tipo === 'comunidade'

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

  const carregarComunidade = useCallback(() => {
    setIsLoading(true)
    setErro(false)
    loadCommunityById(id).then((data) => {
      if (data) {
        setComunidade(data)
        setEditNome(data.title || '')
        setEditDescricao(data.description || '')
        setEditCidade(data.city || '')
        setEditEstado(data.state || '')
        setEditEndereco(data.address || '')
        setEditWhatsapp(data.whatsapp || '')
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
      carregarComunidade()
    }, 0)
    return () => clearTimeout(timer)
  }, [carregarComunidade])

  function handleSeguir() {
    if (!usuario) {
      alert('Você precisa estar logado para seguir esta comunidade!')
      return
    }
    const agora = toggleSeguir(usuario.id, id)
    setSeguindo(agora)
  }

  function handleContato() {
    if (comunidade?.whatsapp) {
      window.open(`https://wa.me/${comunidade.whatsapp}`, '_blank')
    }
  }

  function handleAvaliar(nota) {
    if (!usuario) {
      alert('Você precisa estar logado para avaliar esta comunidade!')
      return
    }
    const novaLista = salvarAvaliacao(id, usuario.id, nota)
    setAvaliacoesList(novaLista)
    setMinhaNota(nota)
  }

  async function handleSalvarPerfil() {
    try {
      await api.put('/comunidades/me/perfil', {
        nome_entidade: editNome,
        descricao: editDescricao,
        cidade: editCidade,
        estado: editEstado,
        endereco: editEndereco,
        whatsapp: editWhatsapp
      })
      alert('Perfil da comunidade atualizado com sucesso no banco de dados!')
      setModoEdicao(false)
      carregarComunidade()
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

      await api.post('/comunidades/me/midias', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      alert('Mídia adicionada com sucesso na galeria!')
      setShowAddMidia(false)
      limparFormMidia()
      carregarComunidade()
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
      await api.delete(`/comunidades/me/midias/${midiaId}`)
      alert('Mídia removida com sucesso!')
      carregarComunidade()
    } catch (err) {
      console.error(err)
      alert('Erro ao remover mídia.')
    }
  }

  if (isLoading) {
    return (
      <div className={styles['vc-shell']}>
        <Header />
        <main className={styles['vc-main']}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '40vh', gap: '12px', color: 'var(--text-muted)' }}>
            <p>Carregando perfil da comunidade...</p>
          </div>
        </main>
        <Footer />
      </div>
    )
  }

  if (erro || !comunidade) {
    return (
      <div className={styles['vc-shell']}>
        <Header />
        <main className={styles['vc-main']}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '40vh', gap: '12px', color: 'var(--text-muted)' }}>
            <p>Comunidade não encontrada.</p>
            <Link to="/comunidades" className={styles['vc-btn-contato']} style={{ marginTop: '12px' }}>
              Voltar para comunidades
            </Link>
          </div>
        </main>
        <Footer />
      </div>
    )
  }

  const nome = comunidade.title || 'Comunidade'
  const sobre = comunidade.description || ''
  const cidade = [comunidade.city, comunidade.state].filter(Boolean).join(', ')
  const localizacao = comunidade.address || cidade
  const whatsapp = comunidade.whatsapp || ''
  const eventos = (comunidade.eventos || []).map((e) => {
    let image = e.foto_capa_url || ''
    if (image && image.includes('/media/')) {
      const idx = image.indexOf('/media/')
      image = image.substring(idx)
    }
    return {
      id: e.id,
      nome: e.titulo || '',
      data: formatDate(e.data_inicio),
      hora: formatTime(e.data_inicio),
      local: e.local || '',
      preco: formatPrice(e.valor_ingresso),
      status: e.status || 'agendado',
      image,
    }
  })
  const midias = (comunidade.midias || []).filter((m) => m.url)

  // Calcular stats de avaliação e seguidores locais
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
    eventosRealizados: eventos.length,
    seguidores: seguindo ? 1 : 0,
    avaliacao: mediaAvaliacao,
    proximosEventos: eventos.length,
    totalAvaliacoes: totalAvaliacoes,
  }


  return (
    <div className={styles['vc-shell']}>
      <Header />

      <main className={styles['vc-main']}>
        <div className={styles['vc-layout']}>

          <div className={styles['vc-col-left']}>

            <div className={cn(styles['vc-card'], styles['vc-profile-card'])}>
              <div className={styles['vc-cover']}>
                <div className={styles['vc-cover-placeholder']}>
                  <svg viewBox="0 0 24 24">
                    <rect x="3" y="3" width="18" height="18" rx="2" />
                    <circle cx="8.5" cy="8.5" r="1.5" />
                    <polyline points="21 15 16 10 5 21" />
                  </svg>
                </div>
              </div>

              <div className={styles['vc-avatar-row']}>
                <div className={styles['vc-avatar-wrap']}>
                  <div className={styles['vc-avatar']}>
                    {comunidade.foto_perfil_url ? (
                      <img src={comunidade.foto_perfil_url} alt={nome} />
                    ) : (
                      editNome ? editNome.slice(0, 3) : nome.slice(0, 3)
                    )}
                  </div>
                </div>
                <span className={styles['vc-seguidores-badge']}>
                  {stats.seguidores} Seguidores
                </span>
              </div>

              <div className={styles['vc-profile-info']}>
                {modoEdicao ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', width: '100%', marginTop: '12px' }}>
                    <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Nome da Entidade:</label>
                    <input
                      className={styles['vc-about-text']}
                      style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)' }}
                      value={editNome}
                      onChange={(e) => setEditNome(e.target.value)}
                    />
                    <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Cidade:</label>
                    <input
                      className={styles['vc-about-text']}
                      style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)' }}
                      value={editCidade}
                      onChange={(e) => setEditCidade(e.target.value)}
                    />
                    <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Estado (Ex: SC):</label>
                    <input
                      maxLength={2}
                      className={styles['vc-about-text']}
                      style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)' }}
                      value={editEstado}
                      onChange={(e) => setEditEstado(e.target.value)}
                    />
                  </div>
                ) : (
                  <>
                    <div className={styles['vc-community-name']}>{nome}</div>
                    {cidade && (
                      <div className={styles['vc-location-row']}>
                        <svg viewBox="0 0 24 24">
                          <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                          <circle cx="12" cy="10" r="3" />
                        </svg>
                        {cidade}
                      </div>
                    )}
                  </>
                )}
                <div className={styles['vc-profile-actions']} style={{ marginTop: '16px' }}>
                  {isDono ? (
                    modoEdicao ? (
                      <>
                        <button className={styles['vc-btn-seguir']} style={{ background: '#0F6E56', color: '#fff' }} onClick={handleSalvarPerfil}>
                          Salvar
                        </button>
                        <button className={styles['vc-btn-contato']} style={{ background: '#C24545', color: '#fff' }} onClick={() => setModoEdicao(false)}>
                          Cancelar
                        </button>
                      </>
                    ) : (
                      <button className={styles['vc-btn-seguir']} onClick={() => setModoEdicao(true)}>
                        Editar Perfil
                      </button>
                    )
                  ) : (
                    <button
                      className={cn(styles['vc-btn-seguir'], seguindo && styles['vc-btn-seguir--seguindo'])}
                      onClick={handleSeguir}
                    >
                      {seguindo ? '✓ Seguindo' : 'Seguir'}
                    </button>
                  )}
                  
                  <button
                    className={styles['vc-btn-contato']}
                    onClick={handleContato}
                    disabled={!whatsapp}
                    title={whatsapp ? `WhatsApp: ${whatsapp}` : 'Sem contato cadastrado'}
                  >
                    Contato
                  </button>
                </div>
              </div>
            </div>

            <div className={cn(styles['vc-card'], styles['vc-tabs-card'])}>
              <div className={styles['vc-tabs']}>
                {['sobre', 'eventos', 'galeria', 'avaliacoes'].map((aba) => (
                  <button
                    key={aba}
                    className={cn(styles['vc-tab'], abaAtiva === aba && styles.active)}
                    onClick={() => setAbaAtiva(aba)}
                  >
                    {aba === 'avaliacoes' ? 'Avaliações' : aba.charAt(0).toUpperCase() + aba.slice(1)}
                  </button>
                ))}
              </div>

              <div className={styles['vc-tab-content']}>
                {abaAtiva === 'sobre' && (
                  <>
                    <div className={styles['vc-section-title']}>Sobre a comunidade</div>
                    {modoEdicao ? (
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '8px' }}>
                        <textarea
                          rows={4}
                          className={styles['vc-about-text']}
                          style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)', width: '100%' }}
                          value={editDescricao}
                          onChange={(e) => setEditDescricao(e.target.value)}
                        />
                        <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Endereço Completo:</label>
                        <input
                          className={styles['vc-about-text']}
                          style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)' }}
                          value={editEndereco}
                          onChange={(e) => setEditEndereco(e.target.value)}
                        />
                        <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>WhatsApp (Dígitos):</label>
                        <input
                          className={styles['vc-about-text']}
                          style={{ padding: '8px', border: '1px solid var(--border)', borderRadius: '4px', background: 'var(--surface)', color: 'var(--text)' }}
                          value={editWhatsapp}
                          onChange={(e) => setEditWhatsapp(e.target.value)}
                          placeholder="Ex: 554999999999"
                        />
                      </div>
                    ) : (
                      <>
                        {sobre ? (
                          <>
                            <p className={styles['vc-about-text']}>
                              {textoExpandido
                                ? sobre
                                : sobre.slice(0, 160) + (sobre.length > 160 ? '...' : '')}
                            </p>
                            {sobre.length > 160 && (
                              <button className={styles['vc-ver-mais']} onClick={() => setTextoExpandido(!textoExpandido)}>
                                {textoExpandido ? 'Ver menos ▲' : 'Ver mais ▼'}
                              </button>
                            )}
                          </>
                        ) : (
                          <p className={styles['vc-about-text']} style={{ opacity: 0.5 }}>
                            Nenhuma descrição cadastrada.
                          </p>
                        )}

                        <div className={styles['vc-meta-list']}>
                          {localizacao && (
                            <>
                              <div className={styles['vc-meta-item']}>
                                <svg viewBox="0 0 24 24">
                                  <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                                  <circle cx="12" cy="10" r="3" />
                                </svg>
                                <span>Localização</span>
                              </div>
                              <div className={styles['vc-meta-item']} style={{ paddingLeft: '24px', marginTop: '-6px' }}>
                                {localizacao}
                              </div>
                            </>
                          )}

                          {whatsapp && (
                            <>
                              <div className={styles['vc-meta-item']} style={{ marginTop: '4px' }}>
                                <svg viewBox="0 0 24 24">
                                  <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" />
                                </svg>
                                <span>Contato</span>
                              </div>
                              <div className={styles['vc-meta-item']} style={{ paddingLeft: '24px', marginTop: '-6px' }}>
                                {whatsapp}
                              </div>
                            </>
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

            <div className={cn(styles['vc-card'], styles['vc-ratings-card'])} id="avaliacoes">
              <div className={styles['vc-ratings-header']}>
                <span className={styles['vc-ratings-title']}>Avaliações da comunidade</span>
              </div>

              <div className={styles['vc-rating-big']}>
                <span className={styles['vc-rating-score']}>{stats.avaliacao}</span>
                <div className={styles['vc-rating-info']}>
                  <StarsDisplay value={stats.avaliacao} />
                  <span className={styles['vc-rating-count']}>
                    {stats.totalAvaliacoes === 0
                      ? 'Nenhuma avaliação ainda'
                      : `Baseado em ${stats.totalAvaliacoes} avaliações`}
                  </span>
                </div>
              </div>

              <div style={{ marginTop: '20px', padding: '15px', borderTop: '1px solid var(--border)' }}>
                <span style={{ fontSize: '0.9rem', fontWeight: 600, display: 'block', marginBottom: '8px', color: 'var(--text)' }}>
                  {usuario ? (minhaNota > 0 ? 'Sua avaliação enviada:' : 'Avalie esta comunidade:') : 'Faça login para avaliar esta comunidade'}
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
                  <Link to="/login" className={styles['vc-btn-contato']} style={{ display: 'inline-block', textDecoration: 'none', fontSize: '0.85rem', padding: '6px 12px' }}>
                    Entrar
                  </Link>
                )}
              </div>

              <div className={styles['vc-rating-bars']} style={{ marginTop: '16px' }}>
                {[5, 4, 3, 2, 1].map((n) => (
                  <div key={n} className={styles['vc-rating-bar-row']}>
                    <span className={styles['vc-bar-label']}>{n}</span>
                    <div className={styles['vc-bar-track']}>
                      <div
                        className={styles['vc-bar-fill']}
                        style={{ width: totalAvaliacoes > 0 ? `${((avaliacaoBars[n] || 0) / totalAvaliacoes) * 100}%` : '0%' }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

          </div>

          <div className={styles['vc-col-right']}>

            <div className={cn(styles['vc-card'], styles['vc-stats-card'])}>
              <div className={styles['vc-stats-grid']}>
                {[
                  {
                    icon: <svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></svg>,
                    value: stats.eventosRealizados,
                    label: 'Eventos',
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
                  <div key={i} className={styles['vc-stat-item']}>
                    <div className={styles['vc-stat-icon']}>{s.icon}</div>
                    <span className={styles['vc-stat-value']}>{s.value}</span>
                    <span className={styles['vc-stat-label']}>{s.label}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className={cn(styles['vc-card'], styles['vc-gallery-card'])}>
              <div className={styles['vc-gallery-header']} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                Galeria
                {isDono && (
                  <button
                    className={styles['vc-btn-gallery-add']}
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
                <form onSubmit={handleAdicionarMidia} className={styles['vc-upload-form']}>
                  <label className={styles['vc-upload-dropzone']} htmlFor="comunidade-midia-input">
                    {novaMidiaPreview ? (
                      novaMidiaTipo === 'video' ? (
                        <video src={novaMidiaPreview} className={styles['vc-upload-preview']} controls />
                      ) : (
                        <img src={novaMidiaPreview} alt="Pré-visualização" className={styles['vc-upload-preview']} />
                      )
                    ) : (
                      <div className={styles['vc-upload-placeholder']}>
                        <svg viewBox="0 0 24 24">
                          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                          <polyline points="17 8 12 3 7 8" />
                          <line x1="12" y1="3" x2="12" y2="15" />
                        </svg>
                        <span>Clique para escolher uma foto ou vídeo do seu computador</span>
                      </div>
                    )}
                    <input
                      id="comunidade-midia-input"
                      type="file"
                      accept="image/*,video/*"
                      onChange={handleSelecionarArquivo}
                      className={styles['vc-upload-input-hidden']}
                    />
                  </label>

                  {novaMidiaArquivo && (
                    <button
                      type="button"
                      className={styles['vc-upload-trocar']}
                      onClick={() => document.getElementById('comunidade-midia-input').click()}
                    >
                      Trocar arquivo
                    </button>
                  )}

                  <label className={styles['vc-upload-field-label']}>Título (opcional):</label>
                  <input
                    placeholder="Entrada do CTG..."
                    className={styles['vc-upload-text-input']}
                    value={novaMidiaTitulo}
                    onChange={(e) => setNovaMidiaTitulo(e.target.value)}
                  />

                  <button
                    type="submit"
                    className={cn(styles['vc-btn-contato'], styles['vc-upload-submit'])}
                    disabled={!novaMidiaArquivo || enviandoMidia}
                  >
                    {enviandoMidia ? 'Enviando...' : 'Salvar na Galeria'}
                  </button>
                </form>
              )}

              <div className={styles['vc-gallery-grid']} style={{ display: 'flex', gap: '10px', flexWrap: 'wrap', marginTop: '12px' }}>
                {midias.length === 0 ? (
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', textAlign: 'center', padding: '20px 0', width: '100%' }}>
                    Nenhuma imagem ou vídeo na galeria
                  </div>
                ) : (
                  midias.map((img) => (
                    <div key={img.id} className={styles['vc-gallery-item']} style={{ position: 'relative', width: 'calc(50% - 5px)', minHeight: '120px' }}>
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

            <div className={cn(styles['vc-card'], styles['vc-events-card'])}>
              <div className={styles['vc-events-header']}>
                <span className={styles['vc-events-title']}>Próximos eventos</span>
                <Link to="/eventos" className={styles['vc-ver-todos']}>Ver todos os eventos</Link>
              </div>

              <div className={styles['vc-events-list']}>
                {eventos.length === 0 ? (
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', textAlign: 'center', padding: '20px 0' }}>
                    Nenhum evento agendado
                  </div>
                ) : (
                  eventos.map((ev) => (
                    <Link to={`/eventos/${ev.id}`} key={ev.id} className={styles['vc-event-item']}>
                      {ev.image ? (
                        <img src={ev.image} alt={ev.nome} className={styles['vc-event-thumb']} />
                      ) : (
                        <div className={styles['vc-event-thumb-placeholder']}>
                          <svg viewBox="0 0 24 24">
                            <rect x="3" y="3" width="18" height="18" rx="2" />
                            <circle cx="8.5" cy="8.5" r="1.5" />
                            <polyline points="21 15 16 10 5 21" />
                          </svg>
                        </div>
                      )}

                      <div className={styles['vc-event-info']}>
                        <div className={styles['vc-event-name']}>{ev.nome}</div>
                        <div className={styles['vc-event-meta']}>
                          <div className={styles['vc-event-meta-row']}>
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
                            <div className={styles['vc-event-meta-row']}>
                              <svg viewBox="0 0 24 24">
                                <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                                <circle cx="12" cy="10" r="3" />
                              </svg>
                              {ev.local}
                            </div>
                          )}
                          {ev.preco && (
                            <div className={styles['vc-event-meta-row']}>
                              <svg viewBox="0 0 24 24">
                                <line x1="12" y1="1" x2="12" y2="23" />
                                <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
                              </svg>
                              {ev.preco}
                            </div>
                          )}
                        </div>
                      </div>

                      <div className={styles['vc-event-status-area']}>
                        <div className={styles['vc-event-arrow']}>
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