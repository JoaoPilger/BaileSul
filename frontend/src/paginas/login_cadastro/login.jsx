import { useState } from 'react'
import { Link } from 'react-router-dom'
import './login.css'

export default function Login() {
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [mostrarSenha, setMostrar] = useState(false)
  const [erro, setErro] = useState('')
  const [carregando, setCarregando] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErro('')
    if (!email || !senha) {
      setErro('Preencha todos os campos.')
      return
    }
    setCarregando(true)
    try {
      await new Promise((r) => setTimeout(r, 1200))
    } catch {
      setErro('E-mail ou senha incorretos. Tente novamente.')
    } finally {
      setCarregando(false)
    }
  }

  return (
    <>
      <header className="header">
        <div className="header-inner">
          <Link to="/login" className="logo-area" aria-label="BaileSul — início">
            <img
              src="/imagens/BaileSul.png"
              alt=""
              className="header-logo"
              decoding="sync"
              fetchPriority="high"
            />
          </Link>
        </div>
      </header>

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

          <form className="login-form" onSubmit={handleSubmit}>

            <div className="field-group">
              <label className="field-label" htmlFor="email">E-mail</label>
              <div className="input-wrapper">
                <input
                  id="email"
                  type="email"
                  className="field-input"
                  placeholder="seu@email.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  autoComplete="email"
                />
                <svg viewBox="0 0 24 24">
                  <rect x="2" y="4" width="20" height="16" rx="2" />
                  <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
                </svg>
              </div>
            </div>

            <div className="field-group">
              <label className="field-label" htmlFor="senha">Senha</label>
              <div className="input-wrapper">
                <input
                  id="senha"
                  type={mostrarSenha ? 'text' : 'password'}
                  className="field-input"
                  placeholder="••••••••"
                  value={senha}
                  onChange={(e) => setSenha(e.target.value)}
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
