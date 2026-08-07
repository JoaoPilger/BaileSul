import { useState, useRef } from 'react'
import { cn } from '../../utils/cn';
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import api from '../../services/api'
import HeaderCal from '../../components/header/HeaderCal'
import styles from './cadastro.module.css';
import { validateImageFile } from '../../utils/criarEventoValidation'
import {
  formatCep,
  formatCityField,
  formatCnpj,
  formatNameField,
  formatPhone,
  validateCadastroComunidadeField,
  validateCadastroComunidadeForm,
} from '../../utils/authFormValidation'

function FieldHint({ message }) {
  if (!message) return null
  return <p className="field-hint" role="alert">{message}</p>
}

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
  const [imagemPreview, setImagemPreview] = useState(null)
  const [imagemFile, setImagemFile] = useState(null)
  const [erro, setErro] = useState('')
  const [sucesso, setSucesso] = useState(false)
  const [carregando, setCarregando] = useState(false)
  const [cepCarregando, setCepCarregando] = useState(false)
  const [errors, setErrors] = useState({})
  const [touched, setTouched] = useState({})

  const passo = form.nomeComunidade && form.email ? (form.cep ? 3 : 2) : 1
  const showError = (field) => touched[field] && errors[field]

  const updateField = (name, value) => {
    setForm((prev) => {
      const updated = { ...prev, [name]: value }
      if (touched[name]) {
        setErrors((errs) => ({ ...errs, [name]: validateCadastroComunidadeField(name, value, updated) }))
      }
      return updated
    })
  }

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target
    if (type === 'checkbox') {
      setForm((prev) => ({ ...prev, [name]: checked }))
      setErrors((prev) => ({ ...prev, termos: checked ? '' : 'Aceite os termos para continuar.' }))
      return
    }

    let next = value
    if (name === 'nomeComunidade') next = formatNameField(value, 80)
    if (name === 'telefone') next = formatPhone(value)
    if (name === 'cnpj') next = formatCnpj(value)
    if (name === 'cep') next = formatCep(value)
    if (name === 'cidade' || name === 'bairro') next = formatCityField(value)

    updateField(name, next)
    setErro('')
  }

  const handleImagem = (file) => {
    if (!file) return
    const imageError = validateImageFile(file)
    if (imageError) {
      setErrors((prev) => ({ ...prev, imagem: imageError }))
      setTouched((prev) => ({ ...prev, imagem: true }))
      return
    }
    setImagemFile(file)
    setImagemPreview(URL.createObjectURL(file))
    setErrors((prev) => ({ ...prev, imagem: '' }))
  }

  const buscarCep = async () => {
    const cep = form.cep.replace(/\D/g, '')
    if (cep.length !== 8) return
    setCepCarregando(true)
    const res = await fetch(`https://viacep.com.br/ws/${cep}/json/`).catch(() => null)
    const data = res ? await res.json().catch(() => null) : null
    if (data && !data.erro) {
      setForm((prev) => {
        const updated = {
          ...prev,
          cidade: data.localidade || prev.cidade,
          estado: data.uf || prev.estado,
          bairro: data.bairro || prev.bairro,
          rua: data.logradouro || prev.rua,
        }
        setErrors((errs) => ({
          ...errs,
          cidade: validateCadastroComunidadeField('cidade', updated.cidade, updated),
          bairro: validateCadastroComunidadeField('bairro', updated.bairro, updated),
          rua: validateCadastroComunidadeField('rua', updated.rua, updated),
        }))
        return updated
      })
    }
    setCepCarregando(false)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErro('')

    const validationErrors = validateCadastroComunidadeForm(form)
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors)
      setTouched({
        nomeComunidade: true,
        telefone: true,
        email: true,
        cnpj: true,
        cep: true,
        cidade: true,
        bairro: true,
        rua: true,
        senha: true,
        confirmarSenha: true,
        termos: true,
      })
      return
    }

    const endereco = [form.rua, form.bairro, form.referencia].filter(Boolean).join(', ')
    setCarregando(true)
    try {
      await register({
        email: form.email.trim(),
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
      if (imagemFile) {
        const fd = new FormData()
        fd.append('arquivo', imagemFile)
        await api.post('/comunidades/me/foto-perfil', fd).catch(() => null)
      }
      setSucesso(true)
      navigate('/', { replace: true })
    } catch (err) {
      const msg = err.response?.data?.error
      setErro(msg || 'Erro ao criar conta. Tente novamente.')
    } finally {
      setCarregando(false)
    }
  }

  return (
    <>
      <HeaderCal />

      <main className={styles['cadastro-page']}>
        <div className={cn(styles['cadastro-card'], styles['cadastro-card--wide'])}>

          <div className={styles['card-header']}>
            <div className={styles['card-icon']}>
              <svg viewBox="0 0 24 24">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
                <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                <path d="M16 3.13a4 4 0 0 1 0 7.75" />
              </svg>
            </div>
            <h1 className={styles['card-title']}>Cadastro de Comunidade</h1>
            <p className={styles['card-subtitle']}>Preencha os dados da sua comunidade</p>
          </div>

          <div className={styles['steps-bar']}>
            <div className={cn(styles['step-dot'], passo >= 1 && styles.active, passo > 1 && styles.done)}>{passo > 1 ? '✓' : '1'}</div>
            <div className={cn(styles['step-line'], passo > 1 && styles.done)} />
            <div className={cn(styles['step-dot'], passo >= 2 && styles.active, passo > 2 && styles.done)}>{passo > 2 ? '✓' : '2'}</div>
            <div className={cn(styles['step-line'], passo > 2 && styles.done)} />
            <div className={cn(styles['step-dot'], passo >= 3 && styles.active)}>3</div>
          </div>

          {sucesso ? (
            <p className={styles['success-msg']}>✓ Comunidade cadastrada com sucesso! Redirecionando...</p>
          ) : (
            <form className={styles['cadastro-form']} onSubmit={handleSubmit}>

              <div className={styles['section-label']}>Informações Básicas</div>

              <div className={styles['form-row']}>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="nomeComunidade">Nome da Comunidade *</label>
                  <div className={styles['input-wrapper']}>
                    <input id="nomeComunidade" name="nomeComunidade" type="text" className={styles['field-input']} placeholder="Ex: Comunidade Gaúcha" value={form.nomeComunidade} onChange={handleChange} />
                    <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /></svg>
                  </div>
                  <FieldHint message={showError('nomeComunidade')} />
                </div>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="telefone">Telefone *</label>
                  <div className={styles['input-wrapper']}>
                    <input id="telefone" name="telefone" type="tel" className={styles['field-input']} placeholder="(48) 9 0000-0000" value={form.telefone} onChange={handleChange} />
                    <svg viewBox="0 0 24 24"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.8 12.1 19.79 19.79 0 0 1 1.77 3.47 2 2 0 0 1 3.73 1.32h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.1A16 16 0 0 0 14.9 16.1l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 23 16.92z" /></svg>
                  </div>
                  <FieldHint message={showError('telefone')} />
                </div>
              </div>

              <div className={styles['form-row']}>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="email">E-mail *</label>
                  <div className={styles['input-wrapper']}>
                    <input id="email" name="email" type="email" className={styles['field-input']} placeholder="contato@comunidade.com" value={form.email} onChange={handleChange} autoComplete="email" />
                    <svg viewBox="0 0 24 24"><rect x="2" y="4" width="20" height="16" rx="2" /><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" /></svg>
                  </div>
                  <FieldHint message={showError('email')} />
                </div>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="cnpj">CNPJ *</label>
                  <div className={styles['input-wrapper']}>
                    <input id="cnpj" name="cnpj" type="text" className={styles['field-input']} placeholder="00.000.000/0000-00" value={form.cnpj} onChange={handleChange} />
                    <svg viewBox="0 0 24 24"><rect x="2" y="7" width="20" height="14" rx="2" /><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16" /></svg>
                  </div>
                  <FieldHint message={showError('cnpj')} />
                </div>
              </div>

              <div className={styles['section-label']}>Senha de acesso</div>

              <div className={styles['form-row']}>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="senha">Senha *</label>
                  <div className={styles['input-wrapper']}>
                    <input
                      id="senha"
                      name="senha"
                      type="password"
                      className={cn(styles['field-input'], styles['no-icon'])}
                      placeholder="Mínimo 8 caracteres"
                      value={form.senha}
                      onChange={handleChange}
                      autoComplete="new-password"
                    />
                  </div>
                  <FieldHint message={showError('senha')} />
                </div>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="confirmarSenha">Confirmar senha *</label>
                  <div className={styles['input-wrapper']}>
                    <input
                      id="confirmarSenha"
                      name="confirmarSenha"
                      type="password"
                      className={cn(styles['field-input'], styles['no-icon'])}
                      placeholder="Repita a senha"
                      value={form.confirmarSenha}
                      onChange={handleChange}
                      autoComplete="new-password"
                    />
                  </div>
                  <FieldHint message={showError('confirmarSenha')} />
                </div>
              </div>

              <div className={styles['section-label']}>Imagem de Capa</div>

              <div
                className={cn(styles['upload-area'], imagemPreview && styles['upload-area--filled'])}
                onClick={() => fileRef.current?.click()}
                onDrop={(e) => { e.preventDefault(); handleImagem(e.dataTransfer.files[0]) }}
                onDragOver={(e) => e.preventDefault()}
              >
                {imagemPreview ? (
                  <>
                    <img src={imagemPreview} alt="Prévia da capa" className={styles['upload-preview']} />
                    <button
                      type="button"
                      className={styles['upload-remove']}
                      onClick={(e) => { e.stopPropagation(); setImagemPreview(null); setImagemFile(null) }}
                    >
                      ✕ Remover
                    </button>
                  </>
                ) : (
                  <div className={styles['upload-placeholder']}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                      <rect x="3" y="3" width="18" height="18" rx="2" />
                      <circle cx="8.5" cy="8.5" r="1.5" />
                      <polyline points="21 15 16 10 5 21" />
                    </svg>
                    <span>Clique para fazer upload de imagens</span>
                    <small>PNG, JPG ou WEBP · Máx 5 MB</small>
                  </div>
                )}
                <input ref={fileRef} type="file" accept="image/png,image/jpeg,image/webp" style={{ display: 'none' }} onChange={(e) => handleImagem(e.target.files[0])} />
              </div>
              <FieldHint message={showError('imagem')} />

              <div className={styles['section-label']}>Localização</div>

              <div className={styles['form-row']}>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="cep">CEP *</label>
                  <div className={styles['input-wrapper']}>
                    <input
                      id="cep" name="cep" type="text" className={styles['field-input']}
                      placeholder="00000-000" value={form.cep}
                      onChange={handleChange} onBlur={buscarCep}
                    />
                    <svg viewBox="0 0 24 24"><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>
                    {cepCarregando && <span className={styles['cep-loading']}>⟳</span>}
                  </div>
                  <FieldHint message={showError('cep')} />
                </div>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="cidade">Cidade *</label>
                  <div className={styles['input-wrapper']}>
                    <input id="cidade" name="cidade" type="text" className={cn(styles['field-input'], styles['no-icon'])} placeholder="Ex: Joinville" value={form.cidade} onChange={handleChange} />
                  </div>
                  <FieldHint message={showError('cidade')} />
                </div>
              </div>

              <div className={styles['form-row']}>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="bairro">Bairro *</label>
                  <div className={styles['input-wrapper']}>
                    <input id="bairro" name="bairro" type="text" className={cn(styles['field-input'], styles['no-icon'])} placeholder="Ex: Centro" value={form.bairro} onChange={handleChange} />
                  </div>
                  <FieldHint message={showError('bairro')} />
                </div>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="rua">Rua *</label>
                  <div className={styles['input-wrapper']}>
                    <input id="rua" name="rua" type="text" className={cn(styles['field-input'], styles['no-icon'])} placeholder="Ex: Rua das Flores, 100" value={form.rua} onChange={handleChange} />
                  </div>
                  <FieldHint message={showError('rua')} />
                </div>
              </div>

              <div className={styles['field-group']}>
                <label className={styles['field-label']} htmlFor="referencia">Referência</label>
                <div className={styles['input-wrapper']}>
                  <input id="referencia" name="referencia" type="text" className={cn(styles['field-input'], styles['no-icon'])} placeholder="Ex: Próximo ao mercado central" value={form.referencia} onChange={handleChange} />
                </div>
              </div>

              <div className={styles['mapa-container']}>
                <iframe
                  title="mapa-localizacao"
                  src={`https://www.openstreetmap.org/export/embed.html?bbox=-53.0,-29.5,-48.0,-26.0&layer=mapnik`}
                  className={styles['mapa-iframe']}
                  loading="lazy"
                />
              </div>

              <label className={styles['checkbox-group']}>
                <input type="checkbox" name="termos" checked={form.termos} onChange={handleChange} />
                <span className={styles['checkbox-label']}>
                  Aceito os{' '}
                  <a href="/termos" target="_blank" rel="noreferrer">Termos de compartilhamento de informações</a>
                </span>
              </label>
              <FieldHint message={showError('termos')} />

              {erro && <p className={styles['error-msg']}>{erro}</p>}

              <div className={styles['form-actions']}>
                <button type="button" className={styles['btn-secondary']} onClick={() => navigate('/cadastro')}>
                  Cancelar
                </button>
                <button type="submit" className={styles['btn-primary']} disabled={carregando}>
                  {carregando ? 'Cadastrando...' : 'Cadastrar-se'}
                </button>
              </div>

            </form>
          )}

          <div className={styles['card-footer']}>
            Já tem uma conta? <Link to="/login">Entrar</Link>
          </div>
        </div>
      </main>
    </>
  )
}
