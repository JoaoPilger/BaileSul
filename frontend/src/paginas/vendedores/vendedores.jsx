import { useEffect, useMemo, useState } from 'react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import './vendedores.css'

const VENDEDORES_MOCK = [
  { id: 1, nome: 'João Pedro Silva',   email: 'joao.silva@email.com',   telefone: '49972428724', vendasTotais: 540 },
  { id: 2, nome: 'Maria Eduarda Costa', email: 'maria.costa@email.com',  telefone: '49972428724', vendasTotais: 540 },
  { id: 3, nome: 'Carlos Eduardo Lima', email: 'carlos.lima@email.com',  telefone: '49972428724', vendasTotais: 540 },
  { id: 4, nome: 'Ana Beatriz Souza',   email: 'ana.souza@email.com',    telefone: '49972428724', vendasTotais: 540 },
  { id: 5, nome: 'Pedro Henrique Alves', email: 'pedro.alves@email.com', telefone: '49972428724', vendasTotais: 540 },
  { id: 6, nome: 'Fernanda Oliveira',   email: 'fernanda.oliveira@email.com', telefone: '49972428724', vendasTotais: 540 },
]

function formatPhone(value) {
  const digits = String(value || '').replace(/\D/g, '')
  if (digits.length !== 11) return value
  return `(${digits.slice(0, 2)}) ${digits.slice(2, 7)}-${digits.slice(7)}`
}

function formatCurrency(value) {
  const n = Number(value) || 0
  return n.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

export default function Vendedores() {
  const [vendedores, setVendedores] = useState([])
  const [busca, setBusca] = useState('')
  const [selecionadoId, setSelecionadoId] = useState(null)

  useEffect(() => {
    try {
      const raw = localStorage.getItem('bailesul_vendedores')
      const lista = raw ? JSON.parse(raw) : null
      setVendedores(lista && lista.length ? lista : VENDEDORES_MOCK)
    } catch {
      setVendedores(VENDEDORES_MOCK)
    }
  }, [])

  const persist = (lista) => {
    setVendedores(lista)
    try {
      localStorage.setItem('bailesul_vendedores', JSON.stringify(lista))
    } catch {}
  }

  const removerVendedor = (id) => {
    persist(vendedores.filter((v) => v.id !== id))
  }

  const handleAdicionar = () => {
    console.log('Adicionar vendedor')
  }

  const vendedoresFiltrados = useMemo(() => {
    const termo = busca.trim().toLowerCase()
    if (!termo) return vendedores
    return vendedores.filter((v) =>
      v.nome.toLowerCase().includes(termo) ||
      v.email.toLowerCase().includes(termo) ||
      v.telefone.replace(/\D/g, '').includes(termo.replace(/\D/g, ''))
    )
  }, [vendedores, busca])

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
                placeholder="pesquisar por nome, email ou telefone"
                value={busca}
                onChange={(e) => setBusca(e.target.value)}
              />
            </div>
            <button type="button" className="lv-btn-add" onClick={handleAdicionar}>
              + Adicionar
            </button>
          </div>

          <div className="lv-list-frame">
            {vendedoresFiltrados.length > 0 ? (
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
                    <span className="lv-row-field">{v.nome}</span>
                    <span className="lv-row-field lv-row-field--muted">{v.email}</span>
                    <span className="lv-row-field lv-row-field--muted">{formatPhone(v.telefone)}</span>
                    <span className="lv-row-vendas">
                      Vendas Totais:<strong>R$ {formatCurrency(v.vendasTotais)}</strong>
                    </span>
                    <button
                      type="button"
                      className="lv-btn-delete"
                      aria-label={`Remover ${v.nome}`}
                      onClick={(e) => { e.stopPropagation(); removerVendedor(v.id) }}
                    >
                      <svg viewBox="0 0 24 24">
                        <polyline points="3 6 5 6 21 6" />
                        <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
                        <path d="M10 11v6" />
                        <path d="M14 11v6" />
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
    </div>
  )
}
