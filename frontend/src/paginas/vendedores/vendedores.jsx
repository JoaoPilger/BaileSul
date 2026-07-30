import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import api from '../../services/api'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import './vendedores.css'

function formatPhone(value) {
  const digits = String(value || '').replace(/\D/g, '')
  if (digits.length === 11) return `(${digits.slice(0, 2)}) ${digits.slice(2, 7)}-${digits.slice(7)}`
  if (digits.length === 10) return `(${digits.slice(0, 2)}) ${digits.slice(2, 6)}-${digits.slice(6)}`
  if (digits.length === 13 && digits.startsWith('55')) {
    return `+55 (${digits.slice(2, 4)}) ${digits.slice(4, 9)}-${digits.slice(9)}`
  }
  if (digits.length === 12 && digits.startsWith('55')) {
    return `+55 (${digits.slice(2, 4)}) ${digits.slice(4, 8)}-${digits.slice(8)}`
  }
  return value
}

function formatCurrency(value) {
  const n = Number(value) || 0
  return n.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

export default function Vendedores() {
  const { usuario, isAuthenticated } = useAuth()
  const navigate = useNavigate()

  const [vendedores, setVendedores] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [busca, setBusca] = useState('')
  const [selecionadoId, setSelecionadoId] = useState(null)

  // Modal
  const [modalAberto, setModalAberto] = useState(false)
  const [modalEmail, setModalEmail] = useState('')
  const [modalWhatsapp, setModalWhatsapp] = useState('')
  const [modalLoading, setModalLoading] = useState(false)
  const [modalError, setModalError] = useState('')

  // Sugestão de usuário por email
  const [sugestao, setSugestao] = useState(null)       // { id, nome, email } | null
  const [sugestaoStatus, setSugestaoStatus] = useState('idle') // 'idle' | 'loading' | 'found' | 'not_found'
  const debounceRef = useRef(null)

  // Route Guard
  useEffect(() => {
    if (!isAuthenticated) navigate('/login')
    else if (usuario?.tipo !== 'comunidade') navigate('/')
  }, [isAuthenticated, usuario, navigate])

  const fetchVendedores = async () => {
    try {
      const res = await api.get('/vendedores')
      setVendedores(res.data)
      setError('')
    } catch (err) {
      console.error('Erro ao buscar vendedores:', err)
      setError('Não foi possível carregar a lista de vendedores. Recarregue a página ou tente novamente.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (isAuthenticated && usuario?.tipo === 'comunidade') {
      api.get('/vendedores')
        .then((res) => { setVendedores(res.data); setError('') })
        .catch((err) => {
          console.error('Erro ao buscar vendedores:', err)
          setError('Não foi possível carregar a lista de vendedores. Recarregue a página ou tente novamente.')
        })
        .finally(() => setLoading(false))
    }
  }, [isAuthenticated, usuario])

  const removerVendedor = async (id, nome) => {
    if (!window.confirm(`Tem certeza que deseja remover o vendedor "${nome}"?`)) return
    try {
      await api.delete(`/vendedores/${id}`)
      setVendedores((prev) => prev.filter((v) => v.id !== id))
      if (selecionadoId === id) setSelecionadoId(null)
    } catch (err) {
      console.error('Erro ao remover vendedor:', err)
      alert(err.response?.data?.error || 'Erro ao remover o vendedor. Tente novamente.')
    }
  }

  const fecharModal = () => {
    setModalAberto(false)
    setModalEmail('')
    setModalWhatsapp('')
    setModalError('')
    setModalLoading(false)
    setSugestao(null)
    setSugestaoStatus('idle')
    if (debounceRef.current) clearTimeout(debounceRef.current)
  }

  const buscarSugestao = useCallback((email) => {
    if (debounceRef.current) clearTimeout(debounceRef.current)

    const emailTrim = email.trim()
    // Espera um email minimamente plausível antes de disparar
    if (!emailTrim || !emailTrim.includes('@') || emailTrim.length < 5) {
      setSugestao(null)
      setSugestaoStatus('idle')
      return
    }

    setSugestaoStatus('loading')

    debounceRef.current = setTimeout(async () => {
      try {
        const res = await api.get('/vendedores/sugestoes', { params: { email: emailTrim } })
        if (res.data && res.data.length > 0) {
          setSugestao(res.data[0])
          setSugestaoStatus('found')
        } else {
          setSugestao(null)
          setSugestaoStatus('not_found')
        }
      } catch {
        setSugestao(null)
        setSugestaoStatus('idle')
      }
    }, 500)
  }, [])

  const handleAdicionar = async (e) => {
    e.preventDefault()
    setModalError('')

    const emailTrim = modalEmail.trim()
    if (!emailTrim) {
      setModalError('O e-mail do usuário é obrigatório.')
      return
    }

    if (sugestaoStatus === 'not_found') {
      setModalError('Nenhum usuário pessoal encontrado com esse e-mail.')
      return
    }

    const whatsappFinal = modalWhatsapp.replace(/\D/g, '')
    if (!whatsappFinal || whatsappFinal.length < 10 || whatsappFinal.length > 15) {
      setModalError('WhatsApp inválido. Use de 10 a 15 dígitos.')
      return
    }

    setModalLoading(true)
    try {
      await api.post('/vendedores', {
        email: emailTrim,
        whatsapp: whatsappFinal,
      })
      fecharModal()
      fetchVendedores()
    } catch (err) {
      console.error('Erro ao adicionar vendedor:', err)
      setModalError(err.response?.data?.error || 'Erro ao adicionar o vendedor.')
    } finally {
      setModalLoading(false)
    }
  }

  const vendedoresFiltrados = useMemo(() => {
    const termo = busca.trim().toLowerCase()
    if (!termo) return vendedores
    return vendedores.filter((v) =>
      v.nome.toLowerCase().includes(termo) ||
      (v.usuario_email && v.usuario_email.toLowerCase().includes(termo))
    )
  }, [vendedores, busca])

  if (!isAuthenticated || usuario?.tipo !== 'comunidade') return null

  return (
    <div className="lv-shell">
      <Header />

      <main className="lv-main">
        <div className="lv-card">

          <div className="lv-card-header">
            <svg viewBox="0 0 24 24">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
              <circle cx="9" cy="7" r="4" />
            </svg>
            <h1 className="lv-card-title">Vendedores</h1>
          </div>

          <div className="lv-toolbar">
            <div className="lv-search-wrap">
              <svg viewBox="0 0 24 24">
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
              <input
                type="text"
                className="lv-search-input"
                placeholder="pesquisar por nome ou email"
                value={busca}
                onChange={(e) => setBusca(e.target.value)}
              />
            </div>
            <button type="button" className="lv-btn-add" onClick={() => setModalAberto(true)}>
              + Adicionar
            </button>
          </div>

          {error && <div className="lv-error-alert">{error}</div>}

          <div className="lv-list-frame">
            {loading ? (
              <div className="lv-loading">
                <div className="lv-spinner"></div>
                <span>Carregando vendedores...</span>
              </div>
            ) : vendedoresFiltrados.length > 0 ? (
              <ul className="lv-list">
                {vendedoresFiltrados.map((v) => (
                  <li
                    key={v.id}
                    className={`lv-row${selecionadoId === v.id ? ' lv-row--active' : ''}`}
                    onClick={() => setSelecionadoId(v.id)}
                  >
                    <div className="lv-row-avatar">
                      <svg viewBox="0 0 24 24">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                        <circle cx="12" cy="7" r="4" />
                      </svg>
                    </div>
                    <span className="lv-row-field">
                      {v.nome}
                    </span>
                    <span className="lv-row-field lv-row-field--muted" title={v.usuario_email || (v.usuario_id ? 'Conta vinculada' : 'Sem conta cadastrada')}>
                      {v.usuario_email || (v.usuario_id ? 'Conta vinculada' : 'Sem conta')}
                    </span>
                    <span className="lv-row-field lv-row-field--muted">{formatPhone(v.whatsapp)}</span>
                    <span className="lv-row-vendas">
                      Vendas Totais:<strong>R$ {formatCurrency(v.vendas_totais)}</strong>
                    </span>
                    <button
                      type="button"
                      className="lv-btn-delete"
                      aria-label={`Remover ${v.nome}`}
                      onClick={(e) => { e.stopPropagation(); removerVendedor(v.id, v.nome) }}
                    >
                      <svg viewBox="0 0 24 24">
                        <polyline points="3 6 5 6 21 6" />
                        <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
                        <path d="M10 11v6" /><path d="M14 11v6" />
                        <path d="M9 6V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2" />
                      </svg>
                    </button>
                  </li>
                ))}
              </ul>
            ) : (
              <div className="lv-empty">
                <svg viewBox="0 0 24 24">
                  <circle cx="11" cy="11" r="8" />
                  <line x1="21" y1="21" x2="16.65" y2="16.65" />
                </svg>
                <span>Nenhum vendedor encontrado para essa busca.</span>
              </div>
            )}
          </div>

          <div className="lv-footer-info">
            <span className="lv-count">
              <strong>{vendedoresFiltrados.length}</strong> de <strong>{vendedores.length}</strong> vendedores
            </span>
          </div>

        </div>
      </main>

      <Footer />

      {/* Modal */}
      {modalAberto && (
        <div className="lv-modal-overlay" onClick={fecharModal}>
          <div className="lv-modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="lv-modal-header">
              <h2>Novo Vendedor</h2>
              <button type="button" className="lv-modal-close" onClick={fecharModal}>✕</button>
            </div>

            <form className="lv-modal-form" onSubmit={handleAdicionar}>
              {modalError && <div className="lv-modal-alert">{modalError}</div>}

              {/* Input de Email com busca de sugestão */}
              <div className="lv-modal-field">
                <label htmlFor="modalEmail">E-mail do usuário *</label>
                <input
                  id="modalEmail"
                  type="email"
                  placeholder="Ex: joao@email.com"
                  value={modalEmail}
                  onChange={(e) => {
                    setModalEmail(e.target.value)
                    buscarSugestao(e.target.value)
                  }}
                  disabled={modalLoading}
                  autoFocus
                  autoComplete="off"
                  required
                />

                {/* Feedback inline do status da busca */}
                {sugestaoStatus === 'loading' && (
                  <span className="lv-field-hint" style={{ color: 'var(--text-muted)' }}>
                    <span className="lv-spinner-sm" style={{ display: 'inline-block', verticalAlign: 'middle', marginRight: 6 }} />
                    Buscando usuário...
                  </span>
                )}
                {sugestaoStatus === 'not_found' && (
                  <span className="lv-field-hint lv-field-hint--error">
                    Nenhum usuário pessoal encontrado com esse e-mail.
                  </span>
                )}

                {/* Card do usuário encontrado */}
                {sugestaoStatus === 'found' && sugestao && (
                  <div className="lv-usuario-card">
                    <div className="lv-usuario-card-avatar">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                        <circle cx="12" cy="7" r="4" />
                      </svg>
                    </div>
                    <div className="lv-usuario-card-info">
                      <span className="lv-usuario-card-nome">{sugestao.nome}</span>
                      <span className="lv-usuario-card-email">{sugestao.email}</span>
                    </div>
                    <span className="lv-usuario-card-badge">Encontrado ✓</span>
                  </div>
                )}
              </div>

              {/* WhatsApp */}
              <div className="lv-modal-field">
                <label htmlFor="modalWhatsapp">WhatsApp (com DDD) *</label>
                <input
                  id="modalWhatsapp"
                  type="tel"
                  placeholder="Ex: 47999999999"
                  value={modalWhatsapp}
                  onChange={(e) => setModalWhatsapp(e.target.value)}
                  disabled={modalLoading}
                  autoComplete="off"
                  required
                />
              </div>

              <div className="lv-modal-actions">
                <button
                  type="button"
                  className="lv-modal-btn-cancel"
                  onClick={fecharModal}
                  disabled={modalLoading}
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="lv-modal-btn-submit"
                  disabled={modalLoading}
                >
                  {modalLoading ? 'Adicionando...' : 'Adicionar Vendedor'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}