import { useState } from 'react'
import { cn } from '../../utils/cn';
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import styles from './cadastro.module.css';
import HeaderCal from "../../components/header/HeaderCal"
import { validateCadastroPessoalField, validateCadastroPessoalForm, formatNameField, formatPhone } from '../../utils/authFormValidation'

function calcForca(senha) {
  if (!senha) return { pct: '0%', label: '', cor: 'transparent' }
  let score = 0
  if (senha.length >= 8) score++
  if (/[A-Z]/.test(senha)) score++
  if (/[0-9]/.test(senha)) score++
  if (/[^A-Za-z0-9]/.test(senha)) score++
  const map = [
    { pct: '25%', label: 'Muito fraca', cor: '#e05a6a' },
    { pct: '25%', label: 'Muito fraca', cor: '#e05a6a' },
    { pct: '55%', label: 'Moderada', cor: '#f0a050' },
    { pct: '80%', label: 'Forte', cor: '#4eca8b' },
    { pct: '100%', label: 'Muito forte', cor: '#4eca8b' },
  ]
  return map[score]
}

function FieldHint({ message }) {
  if (!message) return null
  return <p className="field-hint" role="alert">{message}</p>
}

export default function CadastroPessoal() {
  const navigate = useNavigate()
  const { register } = useAuth()
  const [form, setForm] = useState({
    nome: '',
    sobrenome: '',
    email: '',
    telefone: '',
    senha: '',
    confirmarSenha: '',
    termos: false,
  })
  const [mostrarSenha, setMostrarSenha] = useState(false)
  const [mostrarConfirmar, setMostrarConfirmar] = useState(false)
  const [erro, setErro] = useState('')
  const [sucesso, setSucesso] = useState(false)
  const [carregando, setCarregando] = useState(false)
  const [errors, setErrors] = useState({})
  const [touched, setTouched] = useState({})

  const forca = calcForca(form.senha)
  const passo = form.nome && form.email ? (form.senha ? 3 : 2) : 1

  const showError = (field) => touched[field] && errors[field]
  const inputClass = (field, extra = '') =>
    `field-input${extra ? ` ${extra}` : ''}${showError(field) ? ' field-input--error' : ''}`

  const updateField = (name, value) => {
    setForm((prev) => {
      const updated = { ...prev, [name]: value }
      if (touched[name]) {
        setErrors((errs) => ({ ...errs, [name]: validateCadastroPessoalField(name, value, updated) }))
      }
      return updated
    })
  }

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target
    if (type === 'checkbox') {
      setForm((prev) => ({ ...prev, [name]: checked }))
      if (!checked) setErrors((prev) => ({ ...prev, termos: 'Aceite os termos para continuar.' }))
      else setErrors((prev) => ({ ...prev, termos: '' }))
      return
    }

    let next = value
    if (name === 'nome' || name === 'sobrenome') next = formatNameField(value)
    if (name === 'telefone') next = formatPhone(value)

    updateField(name, next)
    setErro('')
  }

  const handleBlur = (e) => {
    const { name } = e.target
    setTouched((prev) => ({ ...prev, [name]: true }))
    setErrors((prev) => ({
      ...prev,
      [name]: validateCadastroPessoalField(name, form[name], form),
    }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErro('')

    const validationErrors = validateCadastroPessoalForm(form)
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors)
      setTouched({
        nome: true,
        sobrenome: true,
        email: true,
        telefone: true,
        senha: true,
        confirmarSenha: true,
        termos: true,
      })
      return
    }

    const nomeCompleto = [form.nome, form.sobrenome].filter(Boolean).join(' ').trim()

    setCarregando(true)
    try {
      await register({
        email: form.email.trim(),
        senha: form.senha,
        tipo: 'pessoal',
        perfil: { nome: nomeCompleto },
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
        <div className={styles['cadastro-card']}>

          <div className={styles['card-header']}>
            <div className={styles['card-icon']}>
              <svg viewBox="0 0 24 24">
                <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
                <line x1="19" y1="8" x2="19" y2="14" />
                <line x1="22" y1="11" x2="16" y2="11" />
              </svg>
            </div>
            <h1 className={styles['card-title']}>Criar conta</h1>
            <p className={styles['card-subtitle']}>Preencha os dados para começar</p>
          </div>

          <div className={styles['steps-bar']}>
            <div className={cn(styles['step-dot'], passo >= 1 && styles.active, passo > 1 && styles.done)}>
              {passo > 1 ? '✓' : '1'}
            </div>
            <div className={cn(styles['step-line'], passo > 1 && styles.done)} />
            <div className={cn(styles['step-dot'], passo >= 2 && styles.active, passo > 2 && styles.done)}>
              {passo > 2 ? '✓' : '2'}
            </div>
            <div className={cn(styles['step-line'], passo > 2 && styles.done)} />
            <div className={cn(styles['step-dot'], passo >= 3 && styles.active)}>3</div>
          </div>

          {sucesso ? (
            <p className={styles['success-msg']}>✓ Conta criada com sucesso! Redirecionando...</p>
          ) : (
            <form className={styles['cadastro-form']} onSubmit={handleSubmit}>

              <div className={styles['form-row']}>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="nome">Nome *</label>
                  <div className={styles['input-wrapper']}>
                    <input
                      id="nome"
                      name="nome"
                      type="text"
                      className={styles['field-input']}
                      placeholder="João"
                      value={form.nome}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      maxLength={60}
                    />
                    <svg viewBox="0 0 24 24">
                      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                      <circle cx="12" cy="7" r="4" />
                    </svg>
                  </div>
                  <FieldHint message={showError('nome')} />
                </div>
                <div className={styles['field-group']}>
                  <label className={styles['field-label']} htmlFor="sobrenome">Sobrenome</label>
                  <div className={styles['input-wrapper']}>
                    <input
                      id="sobrenome"
                      name="sobrenome"
                      type="text"
                      className={cn(styles['field-input'], styles['no-icon'])}
                      placeholder="Silva"
                      value={form.sobrenome}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      maxLength={60}
                    />
                  </div>
                  <FieldHint message={showError('sobrenome')} />
                </div>
              </div>

              <div className={styles['field-group']}>
                <label className={styles['field-label']} htmlFor="email">E-mail *</label>
                <div className={styles['input-wrapper']}>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    className={styles['field-input']}
                    placeholder="seu@email.com"
                    value={form.email}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    autoComplete="email"
                  />
                  <svg viewBox="0 0 24 24">
                    <rect x="2" y="4" width="20" height="16" rx="2" />
                    <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
                  </svg>
                </div>
                <FieldHint message={showError('email')} />
              </div>

              <div className={styles['field-group']}>
                <label className={styles['field-label']} htmlFor="telefone">Telefone</label>
                <div className={styles['input-wrapper']}>
                  <input
                    id="telefone"
                    name="telefone"
                    type="tel"
                    className={styles['field-input']}
                    placeholder="(11) 9 0000-0000"
                    value={form.telefone}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    inputMode="tel"
                  />
                  <svg viewBox="0 0 24 24">
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.8 12.1 19.79 19.79 0 0 1 1.77 3.47 2 2 0 0 1 3.73 1.32h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.1A16 16 0 0 0 14.9 16.1l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 23 16.92z" />
                  </svg>
                </div>
                <FieldHint message={showError('telefone')} />
              </div>

              <div className={styles['field-group']}>
                <label className={styles['field-label']} htmlFor="senha">Senha *</label>
                <div className={styles['input-wrapper']}>
                  <input
                    id="senha"
                    name="senha"
                    type={mostrarSenha ? 'text' : 'password'}
                    className={styles['field-input']}
                    placeholder="Mínimo 8 caracteres"
                    value={form.senha}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    autoComplete="new-password"
                  />
                  <svg viewBox="0 0 24 24">
                    <rect x="3" y="11" width="18" height="11" rx="2" />
                    <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                  </svg>
                  <button
                    type="button"
                    className={styles['toggle-password']}
                    onClick={() => setMostrarSenha(!mostrarSenha)}
                    aria-label={mostrarSenha ? 'Ocultar senha' : 'Mostrar senha'}
                  >
                    {mostrarSenha ? (
                      <svg viewBox="0 0 24 24">
                        <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" />
                        <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" />
                        <line x1="1" y1="1" x2="23" y2="23" />
                      </svg>
                    ) : (
                      <svg viewBox="0 0 24 24">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                        <circle cx="12" cy="12" r="3" />
                      </svg>
                    )}
                  </button>
                </div>
                {form.senha && (
                  <div className={styles['password-strength']}>
                    <div className={styles['strength-bar']}>
                      <div className={styles['strength-fill']} style={{ width: forca.pct, background: forca.cor }} />
                    </div>
                    <p className={styles['strength-label']} style={{ color: forca.cor }}>{forca.label}</p>
                  </div>
                )}
                <FieldHint message={showError('senha')} />
              </div>

              <div className={styles['field-group']}>
                <label className={styles['field-label']} htmlFor="confirmarSenha">Confirmar senha *</label>
                <div className={styles['input-wrapper']}>
                  <input
                    id="confirmarSenha"
                    name="confirmarSenha"
                    type={mostrarConfirmar ? 'text' : 'password'}
                    className={styles['field-input']}
                    placeholder="Repita a senha"
                    value={form.confirmarSenha}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    autoComplete="new-password"
                  />
                  <svg viewBox="0 0 24 24">
                    <rect x="3" y="11" width="18" height="11" rx="2" />
                    <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                  </svg>
                  <button
                    type="button"
                    className={styles['toggle-password']}
                    onClick={() => setMostrarConfirmar(!mostrarConfirmar)}
                    aria-label={mostrarConfirmar ? 'Ocultar confirmação' : 'Mostrar confirmação'}
                  >
                    {mostrarConfirmar ? (
                      <svg viewBox="0 0 24 24">
                        <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" />
                        <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" />
                        <line x1="1" y1="1" x2="23" y2="23" />
                      </svg>
                    ) : (
                      <svg viewBox="0 0 24 24">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                        <circle cx="12" cy="12" r="3" />
                      </svg>
                    )}
                  </button>
                </div>
                <FieldHint message={showError('confirmarSenha')} />
              </div>

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

              <button type="submit" className={styles['btn-primary']} disabled={carregando}>
                {carregando ? 'Criando conta...' : 'Criar conta'}
              </button>
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