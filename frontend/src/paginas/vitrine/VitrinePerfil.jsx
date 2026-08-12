import { useEffect, useState, useCallback } from 'react'
import { Link, useParams } from 'react-router-dom'
import { cn } from '../../utils/cn'
import { loadBandById } from '../../utils/bands'
import { loadCommunityById } from '../../utils/communities'
import { formatPhone } from '../../utils/authFormValidation'
import { useAuth } from '../../contexts/AuthContext'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import Snackbar from '../../components/ui/Snackbar'
import api from '../../services/api'
import styles from './VitrinePerfil.module.css'

const CONFIG = {
  banda: {
    apiBase: 'bandas',
    loadById: loadBandById,
    entidadeSingular: 'banda',
    entidadeCapitalizada: 'Banda',
    naoEncontrado: 'Banda não encontrada.',
    voltarLink: '/bandas',
    voltarLabel: 'Voltar para bandas',
    primeiroStatLabel: 'Apresentações em eventos',
    editFields: [
      { name: 'nome', label: 'Nome artístico:', type: 'text' },
      { name: 'estilo', label: 'Estilo musical:', type: 'text' },
    ],
    editFieldsTab: [
      { name: 'descricao', label: null, type: 'textarea' },
      { name: 'whatsapp', label: 'WhatsApp de contato (dígitos):', type: 'phone', placeholder: 'Ex: (54) 99999-9999' },
      { name: 'videoUrl', label: 'URL de vídeo destaque (YouTube):', type: 'text', placeholder: 'https://youtube.com/...' },
    ],
    perfilPayload: (f) => ({
      nome_artistico: f.nome,
      estilo_musical: f.estilo,
      descricao: f.descricao,
      whatsapp: f.whatsapp,
      video_url: f.videoUrl,
    }),
    mapFromData: (data) => ({
      nome: data.title || '',
      estilo: data.style || '',
      descricao: data.description || '',
      whatsapp: data.whatsapp || '',
      videoUrl: data.video_url || '',
    }),
  },
  comunidade: {
    apiBase: 'comunidades',
    loadById: loadCommunityById,
    entidadeSingular: 'comunidade',
    entidadeCapitalizada: 'Comunidade',
    naoEncontrado: 'Comunidade não encontrada.',
    voltarLink: '/comunidades',
    voltarLabel: 'Voltar para comunidades',
    primeiroStatLabel: 'Eventos',
    editFields: [
      { name: 'nome', label: 'Nome da entidade:', type: 'text' },
      { name: 'cidade', label: 'Cidade:', type: 'text' },
      { name: 'estado', label: 'Estado (ex: SC):', type: 'text', maxLength: 2 },
    ],
    editFieldsTab: [
      { name: 'descricao', label: null, type: 'textarea' },
      { name: 'endereco', label: 'Endereço completo:', type: 'text' },
      { name: 'whatsapp', label: 'WhatsApp de contato (dígitos):', type: 'phone', placeholder: 'Ex: (54) 99999-9999' },
    ],
    perfilPayload: (f) => ({
      nome_entidade: f.nome,
      descricao: f.descricao,
      cidade: f.cidade,
      estado: f.estado,
      endereco: f.endereco,
      whatsapp: f.whatsapp,
    }),
    mapFromData: (data) => ({
      nome: data.title || '',
      cidade: data.city || '',
      estado: data.state || '',
      endereco: data.address || '',
      descricao: data.description || '',
      whatsapp: data.whatsapp || '',
    }),
  },
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
    <div className={styles['vp-stars']}>
      {[1, 2, 3, 4, 5].map((i) => (
        <svg key={i} className={cn(styles['vp-star'], i > Math.round(value) && styles['vp-star--empty'])} viewBox="0 0 24 24">
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      ))}
    </div>
  )
}

function EventStatusBadge({ status }) {
  const map = {
    agendado:  { label: 'Agendado',     cls: 'vp-event-badge--agendado' },
    andamento: { label: 'Em andamento', cls: 'vp-event-badge--andamento' },
    realizado: { label: 'Realizado',    cls: 'vp-event-badge--realizado' },
  }
  const s = map[status] || map.agendado
  return <span className={cn(styles['vp-event-badge'], styles[s.cls])}>{s.label}</span>
}

function EventoItem({ ev }) {
  return (
    <Link to={`/eventos/${ev.id}`} className={styles['vp-event-item']}>
      {ev.image ? (
        <img src={ev.image} alt={ev.nome} className={styles['vp-event-thumb']} />
      ) : (
        <div className={styles['vp-event-thumb-placeholder']}>
          <svg viewBox="0 0 24 24">
            <rect x="3" y="3" width="18" height="18" rx="2" />
            <circle cx="8.5" cy="8.5" r="1.5" />
            <polyline points="21 15 16 10 5 21" />
          </svg>
        </div>
      )}

      <div className={styles['vp-event-info']}>
        <div className={styles['vp-event-name']}>{ev.nome}</div>
        <div className={styles['vp-event-meta']}>
          <div className={styles['vp-event-meta-row']}>
            <svg viewBox="0 0 24 24">
              <rect x="3" y="4" width="18" height="18" rx="2" />
              <line x1="16" y1="2" x2="16" y2="6" />
              <line x1="8" y1="2" x2="8" y2="6" />
              <line x1="3" y1="10" x2="21" y2="10" />
            </svg>
            {ev.data}
            {ev.hora && ` · ${ev.hora}`}
          </div>
          {ev.local && (
            <div className={styles['vp-event-meta-row']}>
              <svg viewBox="0 0 24 24">
                <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                <circle cx="12" cy="10" r="3" />
              </svg>
              {ev.local}
            </div>
          )}
          {ev.comunidade && (
            <div className={styles['vp-event-meta-row']}>
              <svg viewBox="0 0 24 24">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
              </svg>
              {ev.comunidade}
            </div>
          )}
          {ev.preco && (
            <div className={styles['vp-event-meta-row']}>
              <svg viewBox="0 0 24 24">
                <line x1="12" y1="1" x2="12" y2="23" />
                <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
              </svg>
              {ev.preco}
            </div>
          )}
        </div>
      </div>

      <div className={styles['vp-event-status-area']}>
        <div className={styles['vp-event-arrow']}>
          <svg viewBox="0 0 24 24">
            <line x1="5" y1="12" x2="19" y2="12" />
            <polyline points="12 5 19 12 12 19" />
          </svg>
        </div>
        <EventStatusBadge status={ev.status} />
      </div>
    </Link>
  )
}

export default function VitrinePerfil({ tipo }) {
  const cfg = CONFIG[tipo]
  const { id } = useParams()
  const { usuario } = useAuth()
  const [perfil, setPerfil] = useState(null)
  const [isLoading, setIsLoading] = useState(true)
  const [erro, setErro] = useState(false)
  const [abaAtiva, setAbaAtiva] = useState('sobre')
  const [textoExpandido, setTextoExpandido] = useState(false)
  const [snackbar, setSnackbar] = useState({ open: false, message: '' })

  const [seguindoLoading, setSeguindoLoading] = useState(false)
  const [avaliarLoading, setAvaliarLoading] = useState(false)
  const [hoverNota, setHoverNota] = useState(0)

  const [modoEdicao, setModoEdicao] = useState(false)
  const [editForm, setEditForm] = useState({})
  const [salvandoPerfil, setSalvandoPerfil] = useState(false)

  const [novaMidiaArquivo, setNovaMidiaArquivo] = useState(null)
  const [novaMidiaPreview, setNovaMidiaPreview] = useState('')
  const [novaMidiaTipo, setNovaMidiaTipo] = useState('imagem')
  const [novaMidiaTitulo, setNovaMidiaTitulo] = useState('')
  const [showAddMidia, setShowAddMidia] = useState(false)
  const [enviandoMidia, setEnviandoMidia] = useState(false)
  const [midiaParaRemover, setMidiaParaRemover] = useState(null)

  const isDono = usuario && String(usuario.id) === String(id) && usuario.tipo === tipo

  const notificar = (message) => setSnackbar({ open: true, message })

  const carregarPerfil = useCallback(() => {
    setIsLoading(true)
    setErro(false)
    cfg.loadById(id).then((data) => {
      if (data) {
        setPerfil(data)
        setEditForm(cfg.mapFromData(data))
      } else {
        setErro(true)
      }
      setIsLoading(false)
    }).catch(() => {
      setErro(true)
      setIsLoading(false)
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, tipo])

  useEffect(() => {
    carregarPerfil()
  }, [carregarPerfil])

  useEffect(() => {
    return () => {
      if (novaMidiaPreview) URL.revokeObjectURL(novaMidiaPreview)
    }
  }, [novaMidiaPreview])

  async function handleSeguir() {
    if (!usuario) {
      notificar(`Você precisa estar logado para seguir ${tipo === 'banda' ? 'esta banda' : 'esta comunidade'}!`)
      return
    }
    if (seguindoLoading) return

    const seguindoAntes = perfil.seguindo
    setPerfil((p) => ({
      ...p,
      seguindo: !seguindoAntes,
      seguidores: p.seguidores + (seguindoAntes ? -1 : 1),
    }))
    setSeguindoLoading(true)
    try {
      if (seguindoAntes) {
        await api.delete(`/${cfg.apiBase}/${id}/seguir`)
      } else {
        await api.post(`/${cfg.apiBase}/${id}/seguir`)
      }
    } catch (err) {
      setPerfil((p) => ({
        ...p,
        seguindo: seguindoAntes,
        seguidores: p.seguidores + (seguindoAntes ? 1 : -1),
      }))
      notificar(err.response?.data?.error || 'Não foi possível atualizar. Tente novamente.')
    } finally {
      setSeguindoLoading(false)
    }
  }

  function handleContato() {
    if (perfil?.whatsapp) {
      window.open(`https://wa.me/${perfil.whatsapp}`, '_blank')
    }
  }

  async function handleAvaliar(nota) {
    if (!usuario) {
      notificar(`Você precisa estar logado para avaliar ${tipo === 'banda' ? 'esta banda' : 'esta comunidade'}!`)
      return
    }
    if (isDono || avaliarLoading) return

    setAvaliarLoading(true)
    try {
      const { data } = await api.put(`/${cfg.apiBase}/${id}/avaliar`, { nota })
      setPerfil((p) => ({
        ...p,
        minha_avaliacao: data.minha_avaliacao,
        media_avaliacao: data.media_avaliacao,
        total_avaliacoes: data.total_avaliacoes,
      }))
    } catch (err) {
      notificar(err.response?.data?.error || 'Não foi possível registrar sua avaliação.')
    } finally {
      setAvaliarLoading(false)
    }
  }

  function handleEditFieldChange(name, value) {
    setEditForm((f) => ({ ...f, [name]: value }))
  }

  async function handleSalvarPerfil() {
    setSalvandoPerfil(true)
    try {
      await api.put(`/${cfg.apiBase}/me/perfil`, cfg.perfilPayload(editForm))
      notificar('Perfil atualizado com sucesso!')
      setModoEdicao(false)
      carregarPerfil()
    } catch (err) {
      notificar(err.response?.data?.error || 'Erro ao atualizar perfil.')
    } finally {
      setSalvandoPerfil(false)
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

      await api.post(`/${cfg.apiBase}/me/midias`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      notificar('Mídia adicionada com sucesso na galeria!')
      setShowAddMidia(false)
      limparFormMidia()
      carregarPerfil()
    } catch (err) {
      notificar(err.response?.data?.error || 'Erro ao adicionar mídia.')
    } finally {
      setEnviandoMidia(false)
    }
  }

  async function handleRemoverMidia(midiaId) {
    try {
      await api.delete(`/${cfg.apiBase}/me/midias/${midiaId}`)
      notificar('Mídia removida com sucesso!')
      setMidiaParaRemover(null)
      carregarPerfil()
    } catch {
      notificar('Erro ao remover mídia.')
    }
  }

  if (isLoading) {
    return (
      <div className={styles['vp-shell']}>
        <Header />
        <main className={styles['vp-main']}>
          <div className={styles['vp-state']}>
            <p>Carregando perfil {tipo === 'banda' ? 'da banda' : 'da comunidade'}...</p>
          </div>
        </main>
        <Footer />
      </div>
    )
  }

  if (erro || !perfil) {
    return (
      <div className={styles['vp-shell']}>
        <Header />
        <main className={styles['vp-main']}>
          <div className={styles['vp-state']}>
            <p>{cfg.naoEncontrado}</p>
            <Link to={cfg.voltarLink} className={styles['vp-btn-contato']}>
              {cfg.voltarLabel}
            </Link>
          </div>
        </main>
        <Footer />
      </div>
    )
  }

  const nome = perfil.title || cfg.entidadeCapitalizada
  const sobre = perfil.description || ''
  const whatsapp = perfil.whatsapp || ''
  const videoUrl = perfil.video_url || ''
  const cidade = tipo === 'comunidade' ? [perfil.city, perfil.state].filter(Boolean).join(', ') : ''
  const subtitulo = tipo === 'banda' ? perfil.style : cidade
  const localizacao = tipo === 'comunidade' ? (perfil.address || cidade) : ''

  const eventos = (perfil.eventos || []).map((e) => ({
    id: e.id,
    nome: e.titulo || '',
    data: formatDate(e.data_inicio),
    hora: formatTime(e.data_inicio),
    local: tipo === 'banda'
      ? ([e.cidade, e.estado].filter(Boolean).join(', ') || e.local || '')
      : (e.local || ''),
    comunidade: tipo === 'banda' ? (e.comunidade || '') : '',
    preco: tipo === 'comunidade' ? formatPrice(e.valor_ingresso) : '',
    status: e.status || 'agendado',
    image: tipo === 'comunidade' ? (e.foto_capa_url || '') : '',
  }))
  const midias = (perfil.midias || []).filter((m) => m.url)

  const stats = {
    primeiro: eventos.length,
    seguidores: perfil.seguidores || 0,
    avaliacao: perfil.media_avaliacao || 0,
    totalAvaliacoes: perfil.total_avaliacoes || 0,
    proximosEventos: eventos.length,
  }

  const midiaInputId = `${tipo}-midia-input`

  return (
    <div className={styles['vp-shell']}>
      <Header />

      <main className={styles['vp-main']}>
        <div className={styles['vp-layout']}>

          <div className={styles['vp-col-left']}>

            <div className={cn(styles['vp-card'])}>
              <div className={styles['vp-cover']}>
                <div className={styles['vp-cover-placeholder']}>
                  <svg viewBox="0 0 24 24">
                    <rect x="3" y="3" width="18" height="18" rx="2" />
                    <circle cx="8.5" cy="8.5" r="1.5" />
                    <polyline points="21 15 16 10 5 21" />
                  </svg>
                </div>
              </div>

              <div className={styles['vp-avatar-row']}>
                <div className={styles['vp-avatar-wrap']}>
                  <div className={styles['vp-avatar']}>
                    {perfil.foto_perfil_url ? (
                      <img src={perfil.foto_perfil_url} alt={nome} />
                    ) : (
                      (editForm.nome || nome).slice(0, 3)
                    )}
                  </div>
                </div>
                <span className={styles['vp-seguidores-badge']}>
                  {stats.seguidores} Seguidores
                </span>
              </div>

              <div className={styles['vp-profile-info']}>
                {modoEdicao ? (
                  <div className={styles['vp-edit-form']}>
                    {cfg.editFields.map((f) => (
                      <div key={f.name}>
                        <label className={styles['vp-edit-label']}>{f.label}</label>
                        <input
                          className={styles['vp-edit-input']}
                          value={editForm[f.name] || ''}
                          maxLength={f.maxLength}
                          onChange={(e) => handleEditFieldChange(f.name, e.target.value)}
                        />
                      </div>
                    ))}
                  </div>
                ) : (
                  <>
                    <div className={styles['vp-entity-name']}>{nome}</div>
                    {subtitulo && (
                      <div className={styles['vp-location-row']}>
                        <svg viewBox="0 0 24 24">
                          <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                          <circle cx="12" cy="10" r="3" />
                        </svg>
                        {subtitulo}
                      </div>
                    )}
                  </>
                )}

                <div className={styles['vp-profile-actions']}>
                  {!modoEdicao && (
                    <button className={styles['vp-btn-tag']}>{cfg.entidadeCapitalizada}</button>
                  )}
                  {!modoEdicao && tipo === 'banda' && videoUrl && (
                    <button className={styles['vp-btn-tag']}>Ao vivo</button>
                  )}

                  {isDono ? (
                    modoEdicao ? (
                      <>
                        <button className={styles['vp-btn-salvar']} onClick={handleSalvarPerfil} disabled={salvandoPerfil}>
                          {salvandoPerfil ? 'Salvando...' : 'Salvar'}
                        </button>
                        <button className={styles['vp-btn-cancelar']} onClick={() => { setModoEdicao(false); setEditForm(cfg.mapFromData(perfil)) }} disabled={salvandoPerfil}>
                          Cancelar
                        </button>
                      </>
                    ) : (
                      <button className={styles['vp-btn-seguir']} onClick={() => setModoEdicao(true)}>
                        Editar Perfil
                      </button>
                    )
                  ) : (
                    <button
                      className={cn(styles['vp-btn-seguir'], perfil.seguindo && styles['vp-btn-seguir--seguindo'])}
                      onClick={handleSeguir}
                      disabled={seguindoLoading}
                    >
                      {perfil.seguindo ? '✓ Seguindo' : 'Seguir'}
                    </button>
                  )}

                  <button
                    className={styles['vp-btn-contato']}
                    onClick={handleContato}
                    disabled={!whatsapp}
                    title={whatsapp ? `WhatsApp: ${whatsapp}` : 'Sem contato cadastrado'}
                  >
                    Contato
                  </button>
                </div>
              </div>
            </div>

            <div className={cn(styles['vp-card'], styles['vp-tabs-card'])}>
              <div className={styles['vp-tabs']}>
                {['sobre', 'eventos'].map((aba) => (
                  <button
                    key={aba}
                    className={cn(styles['vp-tab'], abaAtiva === aba && styles.active)}
                    onClick={() => setAbaAtiva(aba)}
                  >
                    {aba.charAt(0).toUpperCase() + aba.slice(1)}
                  </button>
                ))}
              </div>

              <div className={styles['vp-tab-content']}>
                {abaAtiva === 'sobre' && (
                  <>
                    <div className={styles['vp-section-title']}>Sobre {tipo === 'banda' ? 'a banda' : 'a comunidade'}</div>
                    {modoEdicao ? (
                      <div className={cn(styles['vp-edit-form'], styles['vp-edit-form--tab'])}>
                        <textarea
                          rows={4}
                          className={styles['vp-edit-input']}
                          value={editForm.descricao || ''}
                          onChange={(e) => handleEditFieldChange('descricao', e.target.value)}
                        />
                        {cfg.editFieldsTab.filter((f) => f.name !== 'descricao').map((f) => (
                          <div key={f.name}>
                            <label className={styles['vp-edit-label']}>{f.label}</label>
                            <input
                              className={styles['vp-edit-input']}
                              value={editForm[f.name] || ''}
                              placeholder={f.placeholder}
                              onChange={(e) => handleEditFieldChange(
                                f.name,
                                f.type === 'phone' ? formatPhone(e.target.value) : e.target.value,
                              )}
                            />
                          </div>
                        ))}
                      </div>
                    ) : (
                      <>
                        {sobre ? (
                          <>
                            <p className={styles['vp-about-text']}>
                              {textoExpandido ? sobre : sobre.slice(0, 160) + (sobre.length > 160 ? '...' : '')}
                            </p>
                            {sobre.length > 160 && (
                              <button className={styles['vp-ver-mais']} onClick={() => setTextoExpandido(!textoExpandido)}>
                                {textoExpandido ? 'Ver menos ▲' : 'Ver mais ▼'}
                              </button>
                            )}
                          </>
                        ) : (
                          <p className={cn(styles['vp-about-text'], styles['vp-about-text--empty'])}>
                            Nenhuma descrição cadastrada.
                          </p>
                        )}

                        <div className={styles['vp-meta-list']}>
                          {tipo === 'banda' && subtitulo && (
                            <div className={styles['vp-meta-item']}>
                              <svg viewBox="0 0 24 24">
                                <path d="M9 18V5l12-2v13" />
                                <circle cx="6" cy="18" r="3" />
                                <circle cx="18" cy="16" r="3" />
                              </svg>
                              Estilo musical: {subtitulo}
                            </div>
                          )}
                          {tipo === 'comunidade' && localizacao && (
                            <>
                              <div className={styles['vp-meta-item']}>
                                <svg viewBox="0 0 24 24">
                                  <path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" />
                                  <circle cx="12" cy="10" r="3" />
                                </svg>
                                <span>Localização</span>
                              </div>
                              <div className={styles['vp-meta-sub']}>{localizacao}</div>
                            </>
                          )}
                          {whatsapp && (
                            <div className={styles['vp-meta-item']}>
                              <svg viewBox="0 0 24 24">
                                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" />
                              </svg>
                              Contato: {whatsapp}
                            </div>
                          )}
                          {tipo === 'banda' && videoUrl && (
                            <div className={styles['vp-meta-item']}>
                              <svg viewBox="0 0 24 24">
                                <polygon points="23 7 16 12 23 17 23 7" />
                                <rect x="1" y="5" width="15" height="14" rx="2" />
                              </svg>
                              <a href={videoUrl} target="_blank" rel="noopener noreferrer" className={styles['vp-meta-link']}>
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
                  <div className={styles['vp-events-list']}>
                    {eventos.length === 0 ? (
                      <div className={styles['vp-events-empty']}>Nenhum evento agendado</div>
                    ) : (
                      eventos.map((ev) => <EventoItem key={ev.id} ev={ev} />)
                    )}
                  </div>
                )}
              </div>
            </div>

            <div className={cn(styles['vp-card'], styles['vp-ratings-card'])} id="avaliacoes">
              <div className={styles['vp-ratings-header']}>
                <span className={styles['vp-ratings-title']}>Avaliações {tipo === 'banda' ? 'da banda' : 'da comunidade'}</span>
              </div>

              <div className={styles['vp-rating-big']}>
                <span className={styles['vp-rating-score']}>{stats.avaliacao}</span>
                <div>
                  <StarsDisplay value={stats.avaliacao} />
                  <span className={styles['vp-rating-count']}>
                    {stats.totalAvaliacoes === 0
                      ? 'Nenhuma avaliação ainda'
                      : `Baseado em ${stats.totalAvaliacoes} avaliações`}
                  </span>
                </div>
              </div>

              <div className={styles['vp-rate-prompt']}>
                <span className={styles['vp-rate-prompt-label']}>
                  {isDono
                    ? 'Você não pode avaliar seu próprio perfil'
                    : usuario
                      ? (perfil.minha_avaliacao > 0 ? 'Sua avaliação enviada:' : `Avalie ${tipo === 'banda' ? 'esta banda' : 'esta comunidade'}:`)
                      : `Faça login para avaliar ${tipo === 'banda' ? 'esta banda' : 'esta comunidade'}`}
                </span>
                {isDono ? null : usuario ? (
                  <div className={styles['vp-rate-stars']}>
                    {[1, 2, 3, 4, 5].map((star) => (
                      <button
                        key={star}
                        type="button"
                        className={styles['vp-star-btn']}
                        disabled={avaliarLoading}
                        onClick={() => handleAvaliar(star)}
                        onMouseEnter={() => setHoverNota(star)}
                        onMouseLeave={() => setHoverNota(0)}
                      >
                        <svg
                          style={{ fill: star <= (hoverNota || perfil.minha_avaliacao) ? '#FFC107' : 'none' }}
                          viewBox="0 0 24 24"
                        >
                          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                        </svg>
                      </button>
                    ))}
                  </div>
                ) : (
                  <Link to="/login" className={styles['vp-btn-contato']}>Entrar</Link>
                )}
              </div>
            </div>

          </div>

          <div className={styles['vp-col-right']}>

            <div className={cn(styles['vp-card'], styles['vp-stats-card'])}>
              <div className={styles['vp-stats-grid']}>
                {[
                  {
                    icon: <svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></svg>,
                    value: stats.primeiro,
                    label: cfg.primeiroStatLabel,
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
                  <div key={i} className={styles['vp-stat-item']}>
                    <div className={styles['vp-stat-icon']}>{s.icon}</div>
                    <span className={styles['vp-stat-value']}>{s.value}</span>
                    <span className={styles['vp-stat-label']}>{s.label}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className={cn(styles['vp-card'], styles['vp-gallery-card'])}>
              <div className={styles['vp-gallery-header']}>
                <span>Galeria</span>
                {isDono && (
                  <button
                    className={styles['vp-btn-gallery-add']}
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
                <form onSubmit={handleAdicionarMidia} className={styles['vp-upload-form']}>
                  <label className={styles['vp-upload-dropzone']} htmlFor={midiaInputId}>
                    {novaMidiaPreview ? (
                      novaMidiaTipo === 'video' ? (
                        <video src={novaMidiaPreview} className={styles['vp-upload-preview']} controls />
                      ) : (
                        <img src={novaMidiaPreview} alt="Pré-visualização" className={styles['vp-upload-preview']} />
                      )
                    ) : (
                      <div className={styles['vp-upload-placeholder']}>
                        <svg viewBox="0 0 24 24">
                          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                          <polyline points="17 8 12 3 7 8" />
                          <line x1="12" y1="3" x2="12" y2="15" />
                        </svg>
                        <span>Clique para escolher uma foto ou vídeo do seu computador</span>
                      </div>
                    )}
                    <input
                      id={midiaInputId}
                      type="file"
                      accept="image/*,video/*"
                      onChange={handleSelecionarArquivo}
                      className={styles['vp-upload-input-hidden']}
                    />
                  </label>

                  {novaMidiaArquivo && (
                    <button
                      type="button"
                      className={styles['vp-upload-trocar']}
                      onClick={() => document.getElementById(midiaInputId).click()}
                    >
                      Trocar arquivo
                    </button>
                  )}

                  <label className={styles['vp-upload-field-label']}>Título (opcional):</label>
                  <input
                    placeholder="Foto do último evento..."
                    className={styles['vp-upload-text-input']}
                    value={novaMidiaTitulo}
                    onChange={(e) => setNovaMidiaTitulo(e.target.value)}
                  />

                  <button
                    type="submit"
                    className={cn(styles['vp-btn-contato'], styles['vp-upload-submit'])}
                    disabled={!novaMidiaArquivo || enviandoMidia}
                  >
                    {enviandoMidia ? 'Enviando...' : 'Salvar na Galeria'}
                  </button>
                </form>
              )}

              <div className={styles['vp-gallery-grid']}>
                {midias.length === 0 ? (
                  <div className={styles['vp-gallery-empty']}>Nenhuma imagem ou vídeo na galeria</div>
                ) : (
                  midias.map((img) => (
                    <div key={img.id} className={styles['vp-gallery-item']}>
                      {img.tipo === 'video' ? (
                        <div className={styles['vp-gallery-video']}>
                          <a href={img.url} target="_blank" rel="noopener noreferrer">Assistir Vídeo</a>
                        </div>
                      ) : (
                        <img src={img.url} alt={img.titulo || 'Imagem'} />
                      )}
                      {isDono && (
                        midiaParaRemover === img.id ? (
                          <div className={styles['vp-gallery-remove']} style={{ display: 'flex', gap: '4px' }}>
                            <button type="button" onClick={() => handleRemoverMidia(img.id)} title="Confirmar remoção">✓</button>
                            <button type="button" onClick={() => setMidiaParaRemover(null)} title="Cancelar">✗</button>
                          </div>
                        ) : (
                          <button
                            type="button"
                            className={styles['vp-gallery-remove']}
                            onClick={() => setMidiaParaRemover(img.id)}
                            title="Remover mídia"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                              <polyline points="3 6 5 6 21 6"></polyline>
                              <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                              <line x1="10" y1="11" x2="10" y2="17"></line>
                              <line x1="14" y1="11" x2="14" y2="17"></line>
                            </svg>
                          </button>
                        )
                      )}
                    </div>
                  ))
                )}
              </div>
            </div>

            <div className={cn(styles['vp-card'], styles['vp-events-card'])}>
              <div className={styles['vp-events-header']}>
                <span className={styles['vp-events-title']}>Próximos eventos</span>
                <Link to="/eventos" className={styles['vp-ver-todos']}>Ver todos os eventos</Link>
              </div>

              <div className={styles['vp-events-list']}>
                {eventos.length === 0 ? (
                  <div className={styles['vp-events-empty']}>Nenhum evento agendado</div>
                ) : (
                  eventos.map((ev) => <EventoItem key={ev.id} ev={ev} />)
                )}
              </div>
            </div>

          </div>
        </div>
      </main>

      <Footer />
      <Snackbar
        open={snackbar.open}
        message={snackbar.message}
        onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
      />
    </div>
  )
}
