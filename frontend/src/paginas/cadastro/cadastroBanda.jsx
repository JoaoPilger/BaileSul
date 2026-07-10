import { useState, useRef } from 'react'
import { cn } from '../../utils/cn';
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import HeaderCal from '../../components/header/HeaderCal'
import styles from './cadastro.module.css';
import { validateImageFile } from '../../utils/criarEventoValidation'
import {
  formatCityField,
  formatCnpj,
  formatNameField,
  formatPhone,
  validateCadastroBandaField,
  validateCadastroBandaForm,
} from '../../utils/authFormValidation'

const ESTILOS = [
  'Forró', 'Axé', 'Samba', 'Pagode', 'Baile Gaúcho', 'MPB',
  'Sertanejo', 'Rock', 'Pop', 'Eletrônico', 'Gospel', 'Outro',
]

const ESTADOS = [
  'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
  'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO',
]

function FieldHint({ message }) {
  if (!message) return null
  return <p className="field-hint" role="alert">{message}</p>
}

export default function CadastroBanda() {
  const navigate = useNavigate()
  const { register } = useAuth()
  const fileRef = useRef(null)

  const [form, setForm] = useState({
    nomeBanda: '',
    telefone: '',
    email: '',
    cnpj: '',
    estilo: '',
    cidadeCriacao: '',
    estadoCriacao: '',
    senha: '',
    confirmarSenha: '',
    termos: false,
  })
  const [imagemPreview, setImagemPreview] = useState(null)
  const [erro, setErro] = useState('')
  const [sucesso, setSucesso] = useState(false)
  const [carregando, setCarregando] = useState(false)
  const [errors, setErrors] = useState({})
  const [touched, setTouched] = useState({})

  const passo = form.nomeBanda && form.email ? (form.estilo ? 3 : 2) : 1
  const showError = (field) => touched[field] && errors[field]
  const inputClass = (field, extra = '') =>
    `field-input${extra ? ` ${extra}` : ''}${showError(field) ? ' field-input--error' : ''}`

  const updateField = (name, value) => {
    setForm((prev) => {
      const updated = { ...prev, [name]: value }
      if (touched[name]) {
        setErrors((errs) => ({ ...errs, [name]: validateCadastroBandaField(name, value, updated) }))
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
    if (name === 'nomeBanda') next = formatNameField(value, 80)
    if (name === 'telefone') next = formatPhone(value)
    if (name === 'cnpj') next = formatCnpj(value)
    if (name === 'cidadeCriacao') next = formatCityField(value)

    updateField(name, next)
    setErro('')
  }

  const handleBlur = (e) => {
    const { name } = e.target
    setTouched((prev) => ({ ...prev, [name]: true }))
    setErrors((prev) => ({
      ...prev,
      [name]: validateCadastroBandaField(name, form[name], form),
    }))
  }

  const handleImagem = (file) => {
    if (!file) return
    const imageError = validateImageFile(file)
    if (imageError) {
      setErrors((prev) => ({ ...prev, imagem: imageError }))
      setTouched((prev) => ({ ...prev, imagem: true }))
      return
    }
    setImagemPreview(URL.createObjectURL(file))
    setErrors((prev) => ({ ...prev, imagem: '' }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErro('')

    const validationErrors = validateCadastroBandaForm(form)
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors)
      setTouched({
        nomeBanda: true,
        telefone: true,
        email: true,
        cnpj: true,
        estilo: true,
        cidadeCriacao: true,
        senha: true,
        confirmarSenha: true,
        termos: true,
      })
      return
    }

    setCarregando(true)
    try {
      await register({
        email: form.email.trim(),
        senha: form.senha,
        tipo: 'banda',
        perfil: {
          nome_artistico: form.nomeBanda,
          estilo_musical: form.estilo,
          cnpj: form.cnpj,
          whatsapp: form.telefone,
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

  return (
    <>
      <HeaderCal />

      <main className={styles['cadastro-page']}>
        <div className={cn(styles['cadastro-card'], styles['cadastro-card--wide'])}>

          <div className={styles['card-header']}>
            <div className={styles['card-icon']}>
              <svg viewBox="0 0 24 24">
                <path d="M9 18V5l12-2v13" />
                <circle cx="6" cy="18" r="3" />
                <circle cx="18" cy="16" r="3" />
              </svg>
            </div>
            <h1 className={styles['card-title']}>Cadastro de Banda</h1>
            <p className={styles['card-subtitle']}>Preencha os dados da sua banda</p>
          </div>

          <div className={styles['steps-bar']}>
            <div className={cn(styles['step-dot'], passo >= 1 && styles.active, passo > 1 && styles.done)}>{passo > 1 ? '✓' : '1'}</div>
            <div className={cn(styles['step-line'], passo > 1 && styles.done)} />
            <div className={cn(styles['step-dot'], passo >= 2 && styles.active, passo > 2 && styles.done)}>{passo > 2 ? '✓' : '2'}</div>
            <div className={cn(styles['step-line'], passo > 2 && styles.done)} />
            <div className={cn(styles['step-dot'], passo >= 3 && styles.active)}>3</div>
          </div>

          {sucesso ? (
            <p className={styles['success-msg']}>✓ Banda cadastrada com sucesso! Redirecionando...</p>
          ) : (
            <form className={styles['cadastro-form']} onSubmit={handleSubmit}>

              <div className={styles['section-label']}>Informações Básicas</div>

              <div className={styles['form-row']}>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="nomeBanda">Nome da Banda *</label>
                  <div className={styles['input-wrapper']}>
                    <input id="nomeBanda" name="nomeBanda" type="text" className={styles['field-input']} placeholder="Ex: Os Gauchões" value={form.nomeBanda} onChange={handleChange} />
                    <svg viewBox="0 0 24 24"><path d="M9 18V5l12-2v13" /><circle cx="6" cy="18" r="3" /><circle cx="18" cy="16" r="3" /></svg>
                  </div>
                  <FieldHint message={showError('nomeBanda')} />
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
                    <input id="email" name="email" type="email" className={styles['field-input']} placeholder="contato@banda.com" value={form.email} onChange={handleChange} autoComplete="email" />
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

              <div className={styles['form-row']}>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="estilo">Estilo da Banda *</label>
                  <div className={styles['input-wrapper']}>
                    <select id="estilo" name="estilo" className={cn(styles['field-input'], styles['no-icon'])} value={form.estilo} onChange={handleChange}>
                      <option value="">Selecione o estilo</option>
                      {ESTILOS.map((e) => <option key={e} value={e.toLowerCase()}>{e}</option>)}
                    </select>
                  </div>
                  <FieldHint message={showError('estilo')} />
                </div>
                <div className={styles['field-group']} />
              </div>

              <div className={styles['form-row']}>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="cidadeCriacao">Cidade de Criação</label>
                  <div className={styles['input-wrapper']}>
                    <input id="cidadeCriacao" name="cidadeCriacao" type="text" className={styles['field-input']} placeholder="Ex: Florianópolis" value={form.cidadeCriacao} onChange={handleChange} />
                    <svg viewBox="0 0 24 24"><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>
                  </div>
                  <FieldHint message={showError('cidadeCriacao')} />
                </div>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="estadoCriacao">Estado</label>
                  <div className={styles['input-wrapper']}>
                    <select id="estadoCriacao" name="estadoCriacao" className={cn(styles['field-input'], styles['no-icon'])} value={form.estadoCriacao} onChange={handleChange}>
                      <option value="">Selecione o estado</option>
                      {ESTADOS.map((uf) => <option key={uf} value={uf}>{uf}</option>)}
                    </select>
                  </div>
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
                      onClick={(e) => { e.stopPropagation(); setImagemCapa(null); setImagemPreview(null) }}
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

              <label className={styles['checkbox-group']}>
                <input type="checkbox" name="termos" checked={form.termos} onChange={handleChange} />
                <span className={styles['checkbox-label']}>
                  Li e aceito os{' '}
                  <a href="/termos" target="_blank" rel="noreferrer">Termos de Uso</a>
                  {' '}e a{' '}
                  <a href="/privacidade" target="_blank" rel="noreferrer">Política de Privacidade</a>
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