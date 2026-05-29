import { useState, useRef } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import HeaderCal from '../../components/header/HeaderCal'
import './cadastro.css'

const senhaValida = (senha) => senha.length >= 8 && /[a-zA-Z]/.test(senha) && /\d/.test(senha)

export default function CadastroComunidade() {
  const navigate = useNavigate()
  const { register } = useAuth()
  const fileRef = useRef(null)

  const [form, setForm] = useState({
    nomeComunidade: '',
    telefone: '',
    email: '',
    cnpj: '',
    cep: '',
    cidade: '',
    estado: '',
    bairro: '',
    rua: '',
    referencia: '',
    senha: '',
    confirmarSenha: '',
    termos: false,
  })
  const [imagemCapa, setImagemCapa] = useState(null)
  const [imagemPreview, setImagemPreview] = useState(null)
  const [erro, setErro] = useState('')
  const [sucesso, setSucesso] = useState(false)
  const [carregando, setCarregando] = useState(false)
  const [cepCarregando, setCepCarregando] = useState(false)

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target
    setForm((p) => ({ ...p, [name]: type === 'checkbox' ? checked : value }))
  }

  const handleImagem = (e) => {
    const file = e.target.files[0]
    if (!file) return
    setImagemCapa(file)
    setImagemPreview(URL.createObjectURL(file))
  }

  const handleDrop = (e) => {
    e.preventDefault()
    const file = e.dataTransfer.files[0]
    if (!file) return
    setImagemCapa(file)
    setImagemPreview(URL.createObjectURL(file))
  }

  const buscarCep = async () => {
    const cep = form.cep.replace(/\D/g, '')
    if (cep.length !== 8) return
    setCepCarregando(true)
    try {
      const res = await fetch(`https://viacep.com.br/ws/${cep}/json/`)
      const data = await res.json()
      if (!data.erro) {
        setForm((p) => ({
          ...p,
          cidade: data.localidade || '',
          estado: data.uf || '',
          bairro: data.bairro || '',
          rua: data.logradouro || '',
        }))
      }
    } catch {
    } finally {
      setCepCarregando(false)
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErro('')
    if (!form.nomeComunidade || !form.email || !form.telefone || !form.cnpj) {
      setErro('Preencha todos os campos obrigatórios (incluindo CNPJ).')
      return
    }
    if (!form.senha || !form.confirmarSenha) {
      setErro('Defina uma senha de acesso.')
      return
    }
    if (form.senha !== form.confirmarSenha) {
      setErro('As senhas não coincidem.')
      return
    }
    if (!senhaValida(form.senha)) {
      setErro('A senha deve ter ao menos 8 caracteres, incluindo letras e números.')
      return
    }
    if (!form.termos) {
      setErro('Você precisa aceitar os termos de compartilhamento.')
      return
    }
    const endereco = [form.rua, form.bairro, form.referencia].filter(Boolean).join(', ')
    setCarregando(true)
    try {
      await register({
        email: form.email,
        senha: form.senha,
        tipo: 'comunidade',
        perfil: {
          nome_entidade: form.nomeComunidade,
          cnpj: form.cnpj,
          whatsapp: form.telefone,
          endereco: endereco || form.rua,
          cidade: form.cidade,
          estado: form.estado,
        },
      })
      setSucesso(true)
      navigate('/', { replace: true })
    } catch (err) {
      const msg = err.response?.data?.error
      setErro(msg || 'Erro ao criar conta. Tente novamente.')
    } finally {
      setCarregando(false)
    }
  }

  const passo = form.nomeComunidade && form.email ? (form.cep ? 3 : 2) : 1

  return (
    <>
      <HeaderCal />

      <main className="cadastro-page">
        <div className="cadastro-card cadastro-card--wide">

          <div className="card-header">
            <div className="card-icon">
              <svg viewBox="0 0 24 24">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
                <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                <path d="M16 3.13a4 4 0 0 1 0 7.75" />
              </svg>
            </div>
            <h1 className="card-title">Cadastro de Comunidade</h1>
            <p className="card-subtitle">Preencha os dados da sua comunidade</p>
          </div>

          <div className="steps-bar">
            <div className={`step-dot ${passo >= 1 ? 'active' : ''} ${passo > 1 ? 'done' : ''}`}>{passo > 1 ? '✓' : '1'}</div>
            <div className={`step-line ${passo > 1 ? 'done' : ''}`} />
            <div className={`step-dot ${passo >= 2 ? 'active' : ''} ${passo > 2 ? 'done' : ''}`}>{passo > 2 ? '✓' : '2'}</div>
            <div className={`step-line ${passo > 2 ? 'done' : ''}`} />
            <div className={`step-dot ${passo >= 3 ? 'active' : ''}`}>3</div>
          </div>

          {sucesso ? (
            <p className="success-msg">✓ Comunidade cadastrada com sucesso! Redirecionando...</p>
          ) : (
            <form className="cadastro-form" onSubmit={handleSubmit}>

              <div className="section-label">Informações Básicas</div>

              <div className="form-row">
                <div className="field-group">
                  <label className="field-label" htmlFor="nomeComunidade">Nome da Comunidade *</label>
                  <div className="input-wrapper">
                    <input id="nomeComunidade" name="nomeComunidade" type="text" className="field-input" placeholder="Ex: Comunidade Gaúcha" value={form.nomeComunidade} onChange={handleChange} />
                    <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /></svg>
                  </div>
                </div>
                <div className="field-group">
                  <label className="field-label" htmlFor="telefone">Telefone *</label>
                  <div className="input-wrapper">
                    <input id="telefone" name="telefone" type="tel" className="field-input" placeholder="(48) 9 0000-0000" value={form.telefone} onChange={handleChange} />
                    <svg viewBox="0 0 24 24"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.8 12.1 19.79 19.79 0 0 1 1.77 3.47 2 2 0 0 1 3.73 1.32h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.1A16 16 0 0 0 14.9 16.1l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 23 16.92z" /></svg>
                  </div>
                </div>
              </div>

              <div className="form-row">
                <div className="field-group">
                  <label className="field-label" htmlFor="email">E-mail *</label>
                  <div className="input-wrapper">
                    <input id="email" name="email" type="email" className="field-input" placeholder="contato@comunidade.com" value={form.email} onChange={handleChange} autoComplete="email" />
                    <svg viewBox="0 0 24 24"><rect x="2" y="4" width="20" height="16" rx="2" /><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" /></svg>
                  </div>
                </div>
                <div className="field-group">
                  <label className="field-label" htmlFor="cnpj">CNPJ *</label>
                  <div className="input-wrapper">
                    <input id="cnpj" name="cnpj" type="text" className="field-input" placeholder="00.000.000/0000-00" value={form.cnpj} onChange={handleChange} />
                    <svg viewBox="0 0 24 24"><rect x="2" y="7" width="20" height="14" rx="2" /><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16" /></svg>
                  </div>
                </div>
              </div>

              <div className="section-label">Senha de acesso</div>

              <div className="form-row">
                <div className="field-group">
                  <label className="field-label" htmlFor="senha">Senha *</label>
                  <div className="input-wrapper">
                    <input
                      id="senha"
                      name="senha"
                      type="password"
                      className="field-input no-icon"
                      placeholder="Mínimo 8 caracteres"
                      value={form.senha}
                      onChange={handleChange}
                      autoComplete="new-password"
                    />
                  </div>
                </div>
                <div className="field-group">
                  <label className="field-label" htmlFor="confirmarSenha">Confirmar senha *</label>
                  <div className="input-wrapper">
                    <input
                      id="confirmarSenha"
                      name="confirmarSenha"
                      type="password"
                      className="field-input no-icon"
                      placeholder="Repita a senha"
                      value={form.confirmarSenha}
                      onChange={handleChange}
                      autoComplete="new-password"
                    />
                  </div>
                </div>
              </div>

              <div className="section-label">Imagem de Capa</div>

              <div
                className={`upload-area ${imagemPreview ? 'upload-area--filled' : ''}`}
                onClick={() => fileRef.current?.click()}
                onDrop={handleDrop}
                onDragOver={(e) => e.preventDefault()}
              >
                {imagemPreview ? (
                  <>
                    <img src={imagemPreview} alt="Prévia da capa" className="upload-preview" />
                    <button
                      type="button"
                      className="upload-remove"
                      onClick={(e) => { e.stopPropagation(); setImagemCapa(null); setImagemPreview(null) }}
                    >
                      ✕ Remover
                    </button>
                  </>
                ) : (
                  <div className="upload-placeholder">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                      <rect x="3" y="3" width="18" height="18" rx="2" />
                      <circle cx="8.5" cy="8.5" r="1.5" />
                      <polyline points="21 15 16 10 5 21" />
                    </svg>
                    <span>Clique para fazer upload de imagens</span>
                    <small>PNG, JPG ou WEBP · Máx 5 MB</small>
                  </div>
                )}
                <input ref={fileRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handleImagem} />
              </div>

              <div className="section-label">Localização</div>

              <div className="form-row">
                <div className="field-group">
                  <label className="field-label" htmlFor="cep">CEP *</label>
                  <div className="input-wrapper">
                    <input
                      id="cep" name="cep" type="text" className="field-input"
                      placeholder="00000-000" value={form.cep}
                      onChange={handleChange} onBlur={buscarCep}
                    />
                    <svg viewBox="0 0 24 24"><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>
                    {cepCarregando && <span className="cep-loading">⟳</span>}
                  </div>
                </div>
                <div className="field-group">
                  <label className="field-label" htmlFor="cidade">Cidade *</label>
                  <div className="input-wrapper">
                    <input id="cidade" name="cidade" type="text" className="field-input no-icon" placeholder="Ex: Joinville" value={form.cidade} onChange={handleChange} />
                  </div>
                </div>
              </div>

              <div className="form-row">
                <div className="field-group">
                  <label className="field-label" htmlFor="bairro">Bairro *</label>
                  <div className="input-wrapper">
                    <input id="bairro" name="bairro" type="text" className="field-input no-icon" placeholder="Ex: Centro" value={form.bairro} onChange={handleChange} />
                  </div>
                </div>
                <div className="field-group">
                  <label className="field-label" htmlFor="rua">Rua *</label>
                  <div className="input-wrapper">
                    <input id="rua" name="rua" type="text" className="field-input no-icon" placeholder="Ex: Rua das Flores, 100" value={form.rua} onChange={handleChange} />
                  </div>
                </div>
              </div>

              <div className="field-group">
                <label className="field-label" htmlFor="referencia">Referência</label>
                <div className="input-wrapper">
                  <input id="referencia" name="referencia" type="text" className="field-input no-icon" placeholder="Ex: Próximo ao mercado central" value={form.referencia} onChange={handleChange} />
                </div>
              </div>

              <div className="mapa-container">
                <iframe
                  title="mapa-localizacao"
                  src={`https://www.openstreetmap.org/export/embed.html?bbox=-53.0,-29.5,-48.0,-26.0&layer=mapnik`}
                  className="mapa-iframe"
                  loading="lazy"
                />
              </div>

              <label className="checkbox-group">
                <input type="checkbox" name="termos" checked={form.termos} onChange={handleChange} />
                <span className="checkbox-label">
                  Aceito os{' '}
                  <a href="/termos" target="_blank" rel="noreferrer">Termos de compartilhamento de informações</a>
                </span>
              </label>

              {erro && <p className="error-msg">{erro}</p>}

              <div className="form-actions">
                <button type="button" className="btn-secondary" onClick={() => navigate('/cadastro')}>
                  Cancelar
                </button>
                <button type="submit" className="btn-primary" disabled={carregando}>
                  {carregando ? 'Cadastrando...' : 'Cadastrar-se'}
                </button>
              </div>

            </form>
          )}

          <div className="card-footer">
            Já tem uma conta? <Link to="/login">Entrar</Link>
          </div>
        </div>
      </main>
    </>
  )
}
