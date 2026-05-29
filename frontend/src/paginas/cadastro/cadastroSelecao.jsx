import { useNavigate, Link } from 'react-router-dom'
import HeaderCal from '../../components/header/HeaderCal'
import './cadastro.css'

const tipos = [
  {
    key: 'pessoal',
    rota: '/cadastro/pessoal',
    icone: (
      <svg viewBox="0 0 24 24">
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
        <circle cx="12" cy="7" r="4" />
      </svg>
    ),
    titulo: 'Pessoal',
  },
  {
    key: 'comunidade',
    rota: '/cadastro/comunidade',
    icone: (
      <svg viewBox="0 0 24 24">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
        <path d="M16 3.13a4 4 0 0 1 0 7.75" />
      </svg>
    ),
    titulo: 'Comunidade',
  },
  {
    key: 'banda',
    rota: '/cadastro/banda',
    icone: (
      <svg viewBox="0 0 24 24">
        <path d="M9 18V5l12-2v13" />
        <circle cx="6" cy="18" r="3" />
        <circle cx="18" cy="16" r="3" />
      </svg>
    ),
    titulo: 'Banda',
  },
]

export default function CadastroSelecao() {
  const navigate = useNavigate()

  return (
    <>
      <HeaderCal />

      <main className="cadastro-page">
        <div className="selecao-card">
          <div className="card-header">
            <div className="card-icon">
              <svg viewBox="0 0 24 24">
                <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
                <line x1="19" y1="8" x2="19" y2="14" />
                <line x1="22" y1="11" x2="16" y2="11" />
              </svg>
            </div>
            <h1 className="card-title">Criar conta</h1>
            <p className="card-subtitle">Escolha o tipo de cadastro para continuar</p>
          </div>

          <div className="tipo-grid">
            {tipos.map((t) => (
              <button
                key={t.key}
                className="tipo-btn"
                onClick={() => navigate(t.rota)}
                type="button"
              >
                <div className="tipo-icon">{t.icone}</div>
                <span className="tipo-titulo">{t.titulo}</span>
                <span className="tipo-arrow">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <line x1="5" y1="12" x2="19" y2="12" />
                    <polyline points="12 5 19 12 12 19" />
                  </svg>
                </span>
              </button>
            ))}
          </div>

          <div className="card-footer">
            Já tem uma conta? <Link to="/login">Entrar</Link>
          </div>
        </div>
      </main>
    </>
  )
}
