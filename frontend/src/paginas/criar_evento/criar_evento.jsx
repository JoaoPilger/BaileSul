import React, { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { User } from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'
import './criar_evento.css'

export default function CriarEvento() {
  const { isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const [title, setTitle] = useState('')
  const [band, setBand] = useState('')
  const [style, setStyle] = useState('sertanejo')
  const [dateStart, setDateStart] = useState('')
  const [dateEnd, setDateEnd] = useState('')
  const [timeStart, setTimeStart] = useState('')
  const [timeEnd, setTimeEnd] = useState('')
  const [image, setImage] = useState('')
  const [price, setPrice] = useState('')
  const [city, setCity] = useState('')
  const [cep, setCep] = useState('')
  const [bairro, setBairro] = useState('')
  const [rua, setRua] = useState('')
  const [referencia, setReferencia] = useState('')
  const [vendorName, setVendorName] = useState('')
  const [vendors, setVendors] = useState([])

  const contaLink = isAuthenticated ? '/perfil' : '/login'
  const footerLinks = [
    { to: '/eventos', label: 'Eventos' },
    { to: '/calendario', label: 'Calendário' },
    { to: '/mapa', label: 'Mapa' },
    { to: '/meus-eventos', label: 'Meus Eventos' },
    { to: '/criar-evento', label: 'Criar Evento' },
    { to: contaLink, label: 'Perfil' },
  ]

  function addVendor() {
    if (!vendorName) return
    setVendors((s) => [...s, { id: Date.now(), name: vendorName }])
    setVendorName('')
  }

  function removeVendor(id) {
    setVendors((s) => s.filter((v) => v.id !== id))
  }

  function handleSubmit(e) {
    e.preventDefault()
    const newEvent = {
      id: Date.now(),
      title,
      band,
      style,
      date: dateStart || new Date().toISOString().slice(0, 10),
      date_end: dateEnd,
      time_start: timeStart,
      time_end: timeEnd,
      image: image || 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80',
      price: price || 'Grátis',
      city,
      cep,
      bairro,
      rua,
      referencia,
      vendors,
      created_at: new Date().toISOString(),
    }

    try {
      const raw = localStorage.getItem('bailesul_events')
      const list = raw ? JSON.parse(raw) : []
      list.unshift(newEvent)
      localStorage.setItem('bailesul_events', JSON.stringify(list))
    } catch (err) {
      console.error('Erro salvando evento', err)
    }

    navigate('/')
  }

  return (
    <div className="create-shell">
      <header className="create-header">
        <div className="create-header-inner">
          <Link to="/" className="create-logo-link" aria-label="BaileSul">
            <img src="/imagens/BaileSul.png" alt="BaileSul" className="create-logo-img" />
          </Link>
          <Link to={contaLink} className="create-user-btn" aria-label={isAuthenticated ? 'Minha conta' : 'Entrar'}>
            <User size={20} strokeWidth={1.8} />
          </Link>
        </div>
      </header>

      <main className="create-main">
        <div className="create-card">
          <h1>Criar Evento</h1>
          <form onSubmit={handleSubmit} className="create-form">
            <section className="form-section">
              <h3>Informações Básicas</h3>
              <label>
                Título do Evento *
                <input value={title} onChange={(e) => setTitle(e.target.value)} required />
              </label>

              <div className="row">
                <label>
                  Banda/Artista *
                  <input value={band} onChange={(e) => setBand(e.target.value)} required />
                </label>
                <label>
                  Estilo Musical *
                  <select value={style} onChange={(e) => setStyle(e.target.value)}>
                    <option value="sertanejo">Sertanejo</option>
                    <option value="forro">Forró</option>
                    <option value="pagode">Pagode</option>
                    <option value="rock">Rock</option>
                    <option value="gaucha">Gaúcha</option>
                  </select>
                </label>
              </div>
            </section>

            <section className="form-section">
              <h3>Data e Horários</h3>
              <div className="row">
                <label>
                  Data de Início *
                  <input type="date" value={dateStart} onChange={(e) => setDateStart(e.target.value)} required />
                </label>
                <label>
                  Data de Término
                  <input type="date" value={dateEnd} onChange={(e) => setDateEnd(e.target.value)} />
                </label>
              </div>

              <div className="row">
                <label>
                  Horário de Início
                  <input type="time" value={timeStart} onChange={(e) => setTimeStart(e.target.value)} />
                </label>
                <label>
                  Horário de Término
                  <input type="time" value={timeEnd} onChange={(e) => setTimeEnd(e.target.value)} />
                </label>
              </div>
            </section>

            <section className="form-section">
              <h3>Imagem de Capa</h3>
              <label>
                URL da imagem
                <input value={image} onChange={(e) => setImage(e.target.value)} placeholder="https://..." />
              </label>
            </section>

            <section className="form-section">
              <h3>Vendedores</h3>
              <div className="vendor-row">
                <input value={vendorName} onChange={(e) => setVendorName(e.target.value)} placeholder="nome do vendedor" />
                <button type="button" className="btn-add" onClick={addVendor}>Adicionar</button>
              </div>

              <ul className="vendor-list">
                {vendors.map((v) => (
                  <li key={v.id} className="vendor-item">
                    <span>{v.name}</span>
                    <button type="button" className="btn-remove" onClick={() => removeVendor(v.id)}>Remover</button>
                  </li>
                ))}
              </ul>
            </section>

            <section className="form-section">
              <h3>Localização</h3>
              <div className="row">
                <label>
                  CEP
                  <input value={cep} onChange={(e) => setCep(e.target.value)} />
                </label>
                <label>
                  Cidade *
                  <input value={city} onChange={(e) => setCity(e.target.value)} required />
                </label>
              </div>

              <div className="row">
                <label>
                  Bairro
                  <input value={bairro} onChange={(e) => setBairro(e.target.value)} />
                </label>
                <label>
                  Rua
                  <input value={rua} onChange={(e) => setRua(e.target.value)} />
                </label>
              </div>

              <label>
                Referência
                <input value={referencia} onChange={(e) => setReferencia(e.target.value)} />
              </label>
            </section>

            <div className="form-actions">
              <Link to="/" className="btn btn-cancel">Cancelar</Link>
              <button type="submit" className="btn btn-primary">Salvar Evento</button>
            </div>
          </form>
        </div>
      </main>

      <footer className="create-footer">
        <div className="create-footer-inner">
          <div className="create-footer-brand">
            <Link to="/" aria-label="BaileSul">
              <img src="/imagens/BaileSul.png" alt="BaileSul" className="create-footer-logo" />
            </Link>
          </div>

          <div className="create-footer-copy-block">
            <p className="create-footer-copy">© BaileSul – Todos os direitos reservados.</p>
          </div>

          <nav className="create-footer-nav-block" aria-label="Navegação do rodapé">
            <h4 className="create-footer-heading">Navegação</h4>
            <div className="create-footer-nav">
              <div className="create-footer-nav-col">
                {footerLinks.slice(0, 3).map((item) => (
                  <Link key={item.to} to={item.to}>{item.label}</Link>
                ))}
              </div>
              <div className="create-footer-nav-col">
                {footerLinks.slice(3).map((item) => (
                  <Link key={item.to} to={item.to}>{item.label}</Link>
                ))}
              </div>
            </div>
          </nav>
        </div>
      </footer>
    </div>
  )
}
