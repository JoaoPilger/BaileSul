import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import HeaderCal from '../../components/header/HeaderCal'
import { formatEmail, validateLoginForm } from '../../utils/authFormValidation'
import './login.css'

function FieldHint({ message }) {
  if (!message) return null
  return <p className="field-hint" role="alert">{message}</p>
}

export default function Login() {
  const navigate = useNavigate()
  const { login } = useAuth()
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [mostrarSenha, setMostrar] = useState(false)
  const [erro, setErro] = useState('')
  const [carregando, setCarregando] = useState(false)
  const [errors, setErrors] = useState({})
  const [touched, setTouched] = useState({})

  const showError = (field) => touched[field] && errors[field]
  const inputClass = (field) => `field-input${showError(field) ? ' field-input--error' : ''}`

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErro('')

    const normalizedEmail = formatEmail(email)
    setEmail(normalizedEmail)

    const validationErrors = validateLoginForm({ email: normalizedEmail, senha })
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors)
      setTouched({ email: true, senha: true })
      return
    }

    setCarregando(true)
    try {
      await login(normalizedEmail, senha)
      navigate('/', { replace: true })
    } catch (err) {
      const msg = err.response?.data?.error
      setErro(msg || 'E-mail ou senha incorretos. Tente novamente.')
    } finally {
      setCarregando(false)
    }
  }

  return (
    <>
      <HeaderCal />

      <main className="login-page">
        <div className="login-card">

          <div className="card-header">
            <div className="card-icon">
              <svg viewBox="0 0 24 24">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                <circle cx="12" cy="7" r="4" />
              </svg>
            </div>
            <h1 className="card-title">Bem-vindo de volta</h1>
            <p className="card-subtitle">Entre com suas credenciais para continuar</p>
          </div>

          <form className="login-form" onSubmit={handleSubmit} noValidate>

            <div className="field-group">
              <label className="field-label" htmlFor="email">E-mail</label>
              <div className="input-wrapper">
                <input
                  id="email"
                  type="email"
                  className={inputClass('email')}
                  placeholder="seu@email.com"
                  value={email}
                  onChange={(e) => {
                    setEmail(e.target.value)
                    if (touched.email) {
                      setErrors((prev) => ({ ...prev, email: validateLoginForm({ email: e.target.value, senha }).email || '' }))
                    }
                  }}
                  onBlur={() => {
                    const normalized = formatEmail(email)
                    setEmail(normalized)
                    setTouched((prev) => ({ ...prev, email: true }))
                    setErrors((prev) => ({
                      ...prev,
                      email: validateLoginForm({ email: normalized, senha }).email || '',
                    }))
                  }}
                  autoComplete="email"
                />
                <svg viewBox="0 0 24 24">
                  <rect x="2" y="4" width="20" height="16" rx="2" />
                  <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
                </svg>
              </div>
              <FieldHint message={showError('email')} />
            </div>

            <div className="field-group">
              <label className="field-label" htmlFor="senha">Senha</label>
              <div className="input-wrapper">
                <input
                  id="senha"
                  type={mostrarSenha ? 'text' : 'password'}
                  className={inputClass('senha')}
                  placeholder="••••••••"
                  value={senha}
                  onChange={(e) => {
                    setSenha(e.target.value)
                    if (touched.senha) {
                      setErrors((prev) => ({ ...prev, senha: validateLoginForm({ email, senha: e.target.value }).senha || '' }))
                    }
                  }}
                  onBlur={() => {
                    setTouched((prev) => ({ ...prev, senha: true }))
                    setErrors((prev) => ({
                      ...prev,
                      senha: validateLoginForm({ email, senha }).senha || '',
                    }))
                  }}
                  autoComplete="current-password"
                />
                <svg viewBox="0 0 24 24">
                  <rect x="3" y="11" width="18" height="11" rx="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
                <button
                  type="button"
                  className="toggle-password"
                  onClick={() => setMostrar(!mostrarSenha)}
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
              <FieldHint message={showError('senha')} />
              <a href="/esqueci-senha" className="forgot-link">Esqueci minha senha</a>
            </div>

            {erro && <p className="error-msg">{erro}</p>}

            <button type="submit" className="btn-primary" disabled={carregando}>
              {carregando ? 'Entrando...' : 'Entrar'}
            </button>
          </form>

          <div className="card-footer">
            Não tem uma conta? <Link to="/cadastro">Cadastre-se</Link>
          </div>
        </div>
      </main>
    </>
  )
}
