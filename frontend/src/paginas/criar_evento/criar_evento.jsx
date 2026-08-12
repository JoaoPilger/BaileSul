import { useState, useRef, useEffect } from 'react'
import { cn } from '../../utils/cn';
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { User } from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'
import api from '../../services/api'
import {
  formatCep,
  formatCityField,
  formatPriceBlur,
  formatPriceInput,
  formatTextField,
  validateField,
  validateForm,
  validateImageFile,
  validateVendorName,
} from '../../utils/criarEventoValidation'
import styles from './criar_evento.module.css';

const TIPOS_EVENTO = [
  { value: 'musical', label: 'Musical' },
  { value: 'almoco',  label: 'Almoço' },
  { value: 'bingo',   label: 'Bingo' },
  { value: 'expos',   label: 'Expos' },
  { value: 'futebol', label: 'Futebol' },
]

const ESTILOS_MUSICAIS = [
  { value: 'gaucha',    label: 'Gaúcha' },
  { value: 'bandinha',  label: 'Bandinha' },
]

const TEXT_LIMITS = {
  title: 120,
  band: 80,
  descricao: 1000,
  rua: 120,
  referencia: 150,
}

function FieldHint({ message }) {
  if (!message) return null
  return <p className={styles['ce-field-error']} role="alert">{message}</p>
}

export default function CriarEvento() {
  const { isAuthenticated, token } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const fileRef = useRef(null)

  const initialDateStart = location.state?.dateStart || ''

  const [form, setForm] = useState({
    title:     '',
    band:      '',
    descricao: '',
    tipoEvento:     'musical',
    estiloMusical:  'gaucha',
    dateStart: initialDateStart,
    dateEnd:   '',
    timeStart: '',
    timeEnd:   '',
    price:     '',
    cep:       '',
    city:      '',
    bairro:    '',
    rua:       '',
    referencia:'',
  })
  const [imagemFile, setImagemFile]     = useState(null)
  const [imagemPreview, setImagemPreview] = useState(null)
  const [vendorName, setVendorName]     = useState('')
  const [vendors, setVendors]           = useState([])
  const [cepLoading, setCepLoading]     = useState(false)
  const [errors, setErrors]             = useState({})
  const [touched, setTouched]           = useState({})
  const [submitAttempted, setSubmitAttempted] = useState(false)
  const [vendorError, setVendorError]   = useState('')
  const [formAlert, setFormAlert]       = useState('')

  const [bandaId, setBandaId]                 = useState(null)
  const [bandaSugestoes, setBandaSugestoes]    = useState([])
  const [bandaSugestoesOpen, setBandaSugestoesOpen] = useState(false)
  const [, setBandaBuscando]      = useState(false)

  const [vendedoresComunidade, setVendedoresComunidade] = useState([])
  const [vendorSugestoes, setVendorSugestoes]           = useState([])
  const [vendorSugestoesOpen, setVendorSugestoesOpen]   = useState(false)

  const MAP_DEFAULT = 'https://www.openstreetmap.org/export/embed.html?bbox=-53.0,-29.5,-48.0,-26.0&layer=mapnik'
  const [mapSrc, setMapSrc]       = useState(MAP_DEFAULT)
  const [mapLoading, setMapLoading] = useState(false)

  const contaLink   = isAuthenticated ? '/configuracoes' : '/login'
  const footerLinks = [
    { to: '/eventos',      label: 'Eventos' },
    { to: '/calendario',   label: 'Calendário' },
    { to: '/meus-eventos', label: 'Meus Eventos' },
    { to: '/criar-evento', label: 'Criar Evento' },
    { to: contaLink,       label: 'Perfil' },
  ]

  const showError = (field) => (touched[field] || submitAttempted) && errors[field]
  const inputClass = (field, extra = '') =>
    cn(
      styles['ce-input'],
      extra === 'no-icon' && styles['no-icon'],
      showError(field) && styles['ce-input--error'],
    )

  const setFieldErrors = (updatedForm, fields = []) => {
    setErrors((prev) => {
      const next = { ...prev }
      const names = fields.length ? fields : Object.keys(updatedForm)
      names.forEach((field) => {
        next[field] = validateField(field, updatedForm[field], updatedForm)
      })
      return next
    })
  }

  const handleChange = (e) => {
    const { name, value } = e.target
    let next = value

    if (name === 'cep') next = formatCep(value)
    else if (name === 'price') next = formatPriceInput(value)
    else if (name === 'city' || name === 'bairro') next = formatCityField(value)
    else if (TEXT_LIMITS[name]) next = formatTextField(value, TEXT_LIMITS[name])

    if (name === 'band') setBandaId(null)

    setForm((prev) => {
      const updated = { ...prev, [name]: next }
      const related = [name]
      if (name === 'dateStart' && updated.dateEnd) related.push('dateEnd')
      if (name === 'timeStart' && updated.timeEnd) related.push('timeEnd')
      if (name === 'dateEnd' && updated.timeEnd) related.push('timeEnd')
      setFieldErrors(updated, related)
      return updated
    })
    setFormAlert('')
  }

  const handleBlur = (e) => {
    const { name, value } = e.target
    setTouched((prev) => ({ ...prev, [name]: true }))

    if (name === 'price') {
      const formatted = formatPriceBlur(value)
      setForm((prev) => {
        const updated = { ...prev, price: formatted }
        setFieldErrors(updated, ['price'])
        return updated
      })
    } else {
      setForm((prev) => {
        setFieldErrors(prev, [name])
        return prev
      })
    }

    if (name === 'cep') buscarCep()
  }

  useEffect(() => {
    if (!isAuthenticated) return
    api
      .get('/vendedores', { headers: { Authorization: `Bearer ${token}` } })
      .then(({ data }) => setVendedoresComunidade(Array.isArray(data) ? data : []))
      .catch(() => setVendedoresComunidade([]))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Atualiza o mapa dinamicamente conforme o endereço é preenchido (debounce 800ms)
  useEffect(() => {
    const { rua, bairro, city, cep } = form
    let cancelled = false
    const timer = setTimeout(async () => {
      if (!city.trim()) {
        if (!cancelled) setMapSrc(MAP_DEFAULT)
        return
      }
      setMapLoading(true)
      try {
        let data = []

        // Tentativa 1: busca estruturada (mais precisa)
        if (rua.trim()) {
          const params = new URLSearchParams({
            format: 'json',
            limit: '1',
            country: 'Brasil',
            city: city.trim(),
            street: rua.trim(),
          })
          const res = await fetch(
            `https://nominatim.openstreetmap.org/search?${params.toString()}`,
            { headers: { 'Accept-Language': 'pt-BR' } }
          )
          data = await res.json()
        }

        // Tentativa 2: busca livre com todos os campos, se a estruturada não achou nada
        if (!data?.[0]) {
          const parts = [rua, bairro, city, cep].map(p => String(p || '').trim()).filter(Boolean)
          const q = encodeURIComponent(`${parts.join(', ')}, Brasil`)
          const res = await fetch(
            `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${q}`,
            { headers: { 'Accept-Language': 'pt-BR' } }
          )
          data = await res.json()
        }

        // Tentativa 3: só cidade, como último recurso
        if (!data?.[0]) {
          const q = encodeURIComponent(`${city.trim()}, Brasil`)
          const res = await fetch(
            `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${q}`,
            { headers: { 'Accept-Language': 'pt-BR' } }
          )
          data = await res.json()
        }

        if (!cancelled && data?.[0]) {
          const lat = parseFloat(data[0].lat)
          const lon = parseFloat(data[0].lon)
          if (!Number.isNaN(lat) && !Number.isNaN(lon)) {
            const pad = 0.012
            const bbox = [lon - pad, lat - pad, lon + pad, lat + pad].join(',')
            setMapSrc(`https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat}%2C${lon}`)
          }
        }
      } catch {
        // Falha silenciosa: mantém o mapa padrão
      } finally {
        if (!cancelled) setMapLoading(false)
      }
    }, 800)

    return () => {
      cancelled = true
      clearTimeout(timer)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [form.rua, form.bairro, form.city, form.cep])

  useEffect(() => {
    let cancelado = false
    const t = setTimeout(async () => {
      if (form.tipoEvento !== 'musical') {
        if (!cancelado) {
          setBandaSugestoes([])
          setBandaSugestoesOpen(false)
        }
        return
      }

      if (bandaId && form.band.trim() === '') setBandaId(null)

      if (bandaId) {
        if (!cancelado) setBandaSugestoesOpen(false)
        return
      }

      const termo = form.band.trim()
      if (termo.length < 2) {
        if (!cancelado) {
          setBandaSugestoes([])
          setBandaSugestoesOpen(false)
        }
        return
      }

      if (!cancelado) setBandaBuscando(true)
      try {
        const { data } = await api.get('/bandas/sugestoes', {
          params: { nome: termo },
          headers: { Authorization: `Bearer ${token}` },
        })
        if (!cancelado) {
          setBandaSugestoes(Array.isArray(data) ? data : [])
          setBandaSugestoesOpen(true)
        }
      } catch {
        if (!cancelado) setBandaSugestoes([])
      } finally {
        if (!cancelado) setBandaBuscando(false)
      }
    }, 300)

    return () => {
      cancelado = true
      clearTimeout(t)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [form.band, form.tipoEvento])

  const selecionarBanda = (banda) => {
    setBandaId(banda.usuario_id)
    setForm((prev) => ({ ...prev, band: banda.nome_artistico }))
    setBandaSugestoesOpen(false)
    setBandaSugestoes([])
  }

  const handleImagem = (file) => {
    if (!file) return
    const imageError = validateImageFile(file)
    if (imageError) {
      setErrors((prev) => ({ ...prev, image: imageError }))
      setTouched((prev) => ({ ...prev, image: true }))
      return
    }
    setImagemFile(file)
    setImagemPreview(URL.createObjectURL(file))
    setErrors((prev) => ({ ...prev, image: '' }))
  }

  const buscarCep = async () => {
    const cep = form.cep.replace(/\D/g, '')
    if (cep.length !== 8) return
    setCepLoading(true)
    const res  = await fetch(`https://viacep.com.br/ws/${cep}/json/`).catch(() => null)
    const data = res ? await res.json().catch(() => null) : null
    if (data && !data.erro) {
      setForm((p) => {
        const updated = {
          ...p,
          city:   data.localidade || p.city,
          bairro: data.bairro     || p.bairro,
          rua:    data.logradouro || p.rua,
        }
        setFieldErrors(updated, ['city', 'bairro', 'rua'])
        return updated
      })
    }
    setCepLoading(false)
  }

  const addVendor = () => {
    const message = validateVendorName(vendorName)
    if (message) {
      setVendorError(message)
      return
    }
    setVendorError('')
    setVendors((s) => [...s, { id: Date.now(), name: vendorName.trim() }])
    setVendorName('')
    setVendorSugestoesOpen(false)
    setVendorSugestoes([])
  }

  const removeVendor = (id) => setVendors((s) => s.filter((v) => v.id !== id))

  const handleVendorNameChange = (e) => {
    const value = e.target.value.slice(0, 80)
    setVendorName(value)
    if (vendorError) setVendorError('')

    const termo = value.trim().toLowerCase()
    if (termo.length < 2) {
      setVendorSugestoes([])
      setVendorSugestoesOpen(false)
      return
    }

    const jaAdicionados = new Set(vendors.map((v) => v.name.toLowerCase()))
    const encontrados = vendedoresComunidade
      .filter((v) => v.nome?.toLowerCase().includes(termo) && !jaAdicionados.has(v.nome.toLowerCase()))
      .slice(0, 5)

    setVendorSugestoes(encontrados)
    setVendorSugestoesOpen(encontrados.length > 0)
  }

  const selecionarVendor = (v) => {
    setVendors((s) => [...s, { id: v.id, name: v.nome }])
    setVendorName('')
    setVendorError('')
    setVendorSugestoesOpen(false)
    setVendorSugestoes([])
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSubmitAttempted(true)
    setFormAlert('')

    const normalizedForm = {
      ...form,
      price: formatPriceBlur(form.price),
    }
    setForm(normalizedForm)

    const validationErrors = validateForm(normalizedForm)
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors)
      setFormAlert('Revise os campos destacados antes de salvar.')
      return
    }

    const tipoEventoFinal = normalizedForm.tipoEvento === 'musical'
      ? `musical_${normalizedForm.estiloMusical}`
      : normalizedForm.tipoEvento

    const descricaoParts = []
    if (normalizedForm.descricao?.trim()) {
      descricaoParts.push(normalizedForm.descricao.trim())
    }
    if (normalizedForm.tipoEvento === 'musical' && !bandaId && normalizedForm.band?.trim()) {
      // Banda digitada mas não vinculada a um cadastro existente
      descricaoParts.push(`Banda/Artista: ${normalizedForm.band.trim()}`)
    }
    const descricao = descricaoParts.join('\n\n')

    const localNome = normalizedForm.city || ''
    const localEndereco = [
      normalizedForm.rua || '',
      normalizedForm.bairro || '',
      normalizedForm.referencia || '',
      normalizedForm.city || '',
      normalizedForm.cep || '',
    ].map(p => String(p).trim()).join(';')

    let valorIngresso = null
    const priceStr = normalizedForm.price
    if (priceStr && !/^(grátis|gratis)$/i.test(priceStr)) {
      const numericString = priceStr.replace(/^R\$\s*/i, '').replace(',', '.')
      const val = parseFloat(numericString)
      if (!Number.isNaN(val) && val >= 0) {
        valorIngresso = val
      }
    }

    const formData = new FormData()
    formData.append('titulo', normalizedForm.title.trim())
    if (descricao) formData.append('descricao', descricao)
    formData.append('tipo_evento', tipoEventoFinal)
    formData.append('data_inicio', normalizedForm.dateStart)
    formData.append('data_fim', normalizedForm.dateEnd || normalizedForm.dateStart)
    if (localNome) formData.append('local_nome', localNome)
    if (localEndereco) formData.append('local_endereco', localEndereco)
    if (valorIngresso !== null) {
      formData.append('valor_ingresso', String(valorIngresso))
    }

    const fallbackImage = 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80'
    if (imagemFile) {
      formData.append('foto_capa', imagemFile)
    } else {
      formData.append('foto_capa_url', fallbackImage)
    }

    try {
      const response = await api.post('/eventos', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      })

      const databaseEvent = response.data.evento || {}

      if (bandaId && databaseEvent.id) {
        try {
          await api.post(
            `/eventos/${databaseEvent.id}/contratos`,
            { banda_id: bandaId },
            { headers: { Authorization: `Bearer ${token}` } },
          )
        } catch (contratoErr) {
          // Evento já foi criado; apenas avisa que o convite à banda falhou
          console.error('Erro ao convidar banda:', contratoErr)
          setFormAlert('Evento criado, mas não foi possível convidar a banda selecionada. Tente convidá-la depois.')
        }
      }

      navigate('/')
    } catch (err) {
      console.error('Erro ao salvar evento:', err)
      const errorMsg = err.response?.data?.error || 'Erro ao salvar evento. Tente novamente.'
      setFormAlert(errorMsg)
    }
  }

  return (
    <div className={styles['ce-shell']}>

      <header className={styles['ce-header']}>
        <div className={styles['ce-header-inner']}>
          <Link to="/" className={styles['ce-logo-link']} aria-label="BaileSul">
            <img src="/imagens/BaileSul.png" alt="BaileSul" className={styles['ce-logo-img']} />
          </Link>
          <Link to={contaLink} className={styles['ce-user-btn']} aria-label={isAuthenticated ? 'Minha conta' : 'Entrar'}>
            <User size={20} strokeWidth={1.8} />
          </Link>
        </div>
      </header>

      <main className={styles['ce-main']}>
        <div className={styles['ce-card']}>

          <div className={styles['ce-card-header']}>
            <h1 className={styles['ce-card-title']}>Criar Evento</h1>
          </div>

          <form className={styles['ce-form']} onSubmit={handleSubmit} noValidate>

            {formAlert && (
              <div className={styles['ce-form-alert']} role="alert">{formAlert}</div>
            )}

            <div className={styles['ce-section']}>
              <div className={styles['ce-section-label']}>Informações Básicas</div>

              <div className={styles['ce-field']}>
                <label className={styles['ce-field-label']} htmlFor="title">Título do Evento *</label>
                <div className={styles['ce-input-wrap']}>
                  <input
                    id="title"
                    name="title"
                    type="text"
                    className={inputClass('title')}
                    placeholder="Ex: Baile Gaúcho de Verão"
                    value={form.title}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    maxLength={TEXT_LIMITS.title}
                    required
                  />
                  <svg viewBox="0 0 24 24"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" /></svg>
                </div>
                <FieldHint message={showError('title')} />
              </div>

              <div className={styles['ce-field']}>
                <label className={styles['ce-field-label']} htmlFor="descricao">Descrição do Evento</label>
                <textarea
                  id="descricao"
                  name="descricao"
                  className={cn(styles['ce-input'], styles['no-icon'])}
                  style={{ height: 'auto', minHeight: '96px', padding: '12px 14px', resize: 'vertical' }}
                  placeholder="Conte um pouco sobre o evento: atrações, público, o que esperar..."
                  value={form.descricao}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  maxLength={TEXT_LIMITS.descricao}
                />
                <FieldHint message={showError('descricao')} />
              </div>

              <div className={styles['ce-row']}>
                {form.tipoEvento === 'musical' && (
                  <div className={styles['ce-field']} style={{ position: 'relative' }}>
                    <label className={styles['ce-field-label']} htmlFor="band">Banda / Artista *</label>
                    <div className={styles['ce-input-wrap']}>
                      <input
                        id="band"
                        name="band"
                        type="text"
                        autoComplete="off"
                        className={inputClass('band')}
                        placeholder="Ex: Os Gauchões"
                        value={form.band}
                        onChange={handleChange}
                        onBlur={(e) => { handleBlur(e); setTimeout(() => setBandaSugestoesOpen(false), 120) }}
                        onFocus={() => bandaSugestoes.length > 0 && setBandaSugestoesOpen(true)}
                        maxLength={TEXT_LIMITS.band}
                        required
                      />
                      <svg viewBox="0 0 24 24"><path d="M9 18V5l12-2v13" /><circle cx="6" cy="18" r="3" /><circle cx="18" cy="16" r="3" /></svg>
                    </div>
                    {bandaId && (
                      <p style={{ fontSize: '0.76rem', color: 'var(--success)', marginTop: '2px' }}>
                        ✓ Vinculada a uma banda cadastrada — um convite será enviado ao criar o evento.
                      </p>
                    )}
                    {bandaSugestoesOpen && bandaSugestoes.length > 0 && (
                      <ul
                        className={styles['ce-vendor-list']}
                        style={{
                          position: 'absolute',
                          top: '100%',
                          left: 0,
                          right: 0,
                          zIndex: 20,
                          background: 'var(--surface)',
                          border: '1px solid var(--border)',
                          borderRadius: '10px',
                          boxShadow: '0 8px 24px rgba(0,0,0,0.1)',
                          marginTop: '4px',
                        }}
                      >
                        {bandaSugestoes.map((b) => (
                          <li
                            key={b.usuario_id}
                            className={styles['ce-vendor-item']}
                            style={{ cursor: 'pointer' }}
                            onMouseDown={() => selecionarBanda(b)}
                          >
                            <span>{b.nome_artistico}</span>
                            {b.estilo_musical && (
                              <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                                {b.estilo_musical}
                              </span>
                            )}
                          </li>
                        ))}
                      </ul>
                    )}
                    <FieldHint message={showError('band')} />
                  </div>
                )}
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="tipoEvento">Tipo de Evento *</label>
                  <div className={styles['ce-input-wrap']}>
                    <select
                      id="tipoEvento"
                      name="tipoEvento"
                      className={cn(styles['ce-input'], styles['no-icon'])}
                      value={form.tipoEvento}
                      onChange={handleChange}
                    >
                      {TIPOS_EVENTO.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
                    </select>
                  </div>
                </div>
              </div>

              {form.tipoEvento === 'musical' && (
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']}>Estilo Musical *</label>
                  <div className={styles['ce-row']}>
                    {ESTILOS_MUSICAIS.map((e) => (
                      <label
                        key={e.value}
                        className={cn(
                          styles['ce-vendor-item'],
                          form.estiloMusical === e.value && styles['ce-upload-area--filled'],
                        )}
                        style={{ cursor: 'pointer', justifyContent: 'flex-start', gap: '10px' }}
                      >
                        <input
                          type="radio"
                          name="estiloMusical"
                          value={e.value}
                          checked={form.estiloMusical === e.value}
                          onChange={handleChange}
                        />
                        {e.label}
                      </label>
                    ))}
                  </div>
                </div>
              )}

              <div className={styles['ce-field']}>
                <label className={styles['ce-field-label']} htmlFor="price">Ingresso / Entrada</label>
                <div className={styles['ce-input-wrap']}>
                  <input
                    id="price"
                    name="price"
                    type="text"
                    className={inputClass('price')}
                    placeholder="Ex: 20,00 ou Grátis"
                    value={form.price}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    inputMode="decimal"
                  />
                  <svg viewBox="0 0 24 24"><line x1="12" y1="1" x2="12" y2="23" /><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" /></svg>
                </div>
                <FieldHint message={showError('price')} />
              </div>
            </div>

            <div className={styles['ce-section']}>
              <div className={styles['ce-section-label']}>Data e Horários</div>

              <div className={styles['ce-row']}>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="dateStart">Data de Início *</label>
                  <div className={styles['ce-input-wrap']}>
                    <input
                      id="dateStart"
                      name="dateStart"
                      type="date"
                      className={inputClass('dateStart')}
                      value={form.dateStart}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      required
                    />
                    <svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></svg>
                  </div>
                  <FieldHint message={showError('dateStart')} />
                </div>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="dateEnd">Data de Término</label>
                  <div className={styles['ce-input-wrap']}>
                    <input
                      id="dateEnd"
                      name="dateEnd"
                      type="date"
                      className={inputClass('dateEnd')}
                      value={form.dateEnd}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      min={form.dateStart || undefined}
                    />
                    <svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></svg>
                  </div>
                  <FieldHint message={showError('dateEnd')} />
                </div>
              </div>

              <div className={styles['ce-row']}>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="timeStart">Horário de Início</label>
                  <div className={styles['ce-input-wrap']}>
                    <input
                      id="timeStart"
                      name="timeStart"
                      type="time"
                      className={inputClass('timeStart')}
                      value={form.timeStart}
                      onChange={handleChange}
                      onBlur={handleBlur}
                    />
                    <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>
                  </div>
                  <FieldHint message={showError('timeStart')} />
                </div>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="timeEnd">Horário de Término</label>
                  <div className={styles['ce-input-wrap']}>
                    <input
                      id="timeEnd"
                      name="timeEnd"
                      type="time"
                      className={inputClass('timeEnd')}
                      value={form.timeEnd}
                      onChange={handleChange}
                      onBlur={handleBlur}
                    />
                    <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>
                  </div>
                  <FieldHint message={showError('timeEnd')} />
                </div>
              </div>
            </div>

            <div className={styles['ce-section']}>
              <div className={styles['ce-section-label']}>Imagem de Capa</div>

              <div
                className={cn(
                  styles['ce-upload-area'],
                  imagemPreview && styles['ce-upload-area--filled'],
                  showError('image') && styles['ce-upload-area--error'],
                )}
                onClick={() => fileRef.current?.click()}
                onDrop={(e) => { e.preventDefault(); handleImagem(e.dataTransfer.files[0]) }}
                onDragOver={(e) => e.preventDefault()}
              >
                {imagemPreview ? (
                  <>
                    <img src={imagemPreview} alt="Prévia da capa" className={styles['ce-upload-preview']} />
                    <button
                      type="button"
                      className={styles['ce-upload-remove']}
                      onClick={(e) => {
                        e.stopPropagation()
                        setImagemFile(null)
                        setImagemPreview(null)
                        setErrors((prev) => ({ ...prev, image: '' }))
                      }}
                    >
                      ✕ Remover
                    </button>
                  </>
                ) : (
                  <div className={styles['ce-upload-placeholder']}>
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
              <FieldHint message={showError('image')} />
            </div>

            <div className={styles['ce-section']}>
              <div className={styles['ce-section-label']}>Vendedores</div>

              <div className={styles['ce-field']}>
                <label className={styles['ce-field-label']} htmlFor="vendorName">Nome do Vendedor</label>
                <div className={styles['ce-vendor-row']}>
                  <div className={styles['ce-input-wrap']} style={{ flex: 1 }}>
                    <input
                      id="vendorName"
                      type="text"
                      autoComplete="off"
                      className={cn(styles['ce-input'], vendorError && styles['ce-input--error'])}
                      placeholder="Ex: Bar do João"
                      value={vendorName}
                      onChange={handleVendorNameChange}
                      onFocus={() => vendorSugestoes.length > 0 && setVendorSugestoesOpen(true)}
                      onBlur={() => setTimeout(() => setVendorSugestoesOpen(false), 120)}
                      onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addVendor() } }}
                    />
                    <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /></svg>
                    {vendorSugestoesOpen && vendorSugestoes.length > 0 && (
                      <ul
                        className={styles['ce-vendor-list']}
                        style={{
                          position: 'absolute',
                          top: '100%',
                          left: 0,
                          right: 0,
                          zIndex: 20,
                          background: 'var(--surface)',
                          border: '1px solid var(--border)',
                          borderRadius: '10px',
                          boxShadow: '0 8px 24px rgba(0,0,0,0.1)',
                          marginTop: '4px',
                        }}
                      >
                        {vendorSugestoes.map((v) => (
                          <li
                            key={v.id}
                            className={styles['ce-vendor-item']}
                            style={{ cursor: 'pointer' }}
                            onMouseDown={() => selecionarVendor(v)}
                          >
                            <span>{v.nome}</span>
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>
                  <button type="button" className={styles['ce-btn-add']} onClick={addVendor}>+ Adicionar</button>
                </div>
                <FieldHint message={vendorError} />
              </div>

              {vendors.length > 0 && (
                <ul className={styles['ce-vendor-list']}>
                  {vendors.map((v) => (
                    <li key={v.id} className={styles['ce-vendor-item']}>
                      <span>{v.name}</span>
                      <button type="button" className={styles['ce-btn-remove']} onClick={() => removeVendor(v.id)}>Remover</button>
                    </li>
                  ))}
                </ul>
              )}
            </div>

            <div className={styles['ce-section']}>
              <div className={styles['ce-section-label']}>Localização</div>

              <div className={styles['ce-row']}>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="cep">CEP</label>
                  <div className={styles['ce-input-wrap']}>
                    <input
                      id="cep"
                      name="cep"
                      type="text"
                      className={inputClass('cep')}
                      placeholder="00000-000"
                      value={form.cep}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      inputMode="numeric"
                      maxLength={9}
                    />
                    <svg viewBox="0 0 24 24"><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>
                    {cepLoading && <span className={styles['ce-cep-loading']}>⟳</span>}
                  </div>
                  <FieldHint message={showError('cep')} />
                </div>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="city">Cidade *</label>
                  <div className={styles['ce-input-wrap']}>
                    <input
                      id="city"
                      name="city"
                      type="text"
                      className={inputClass('city', 'no-icon')}
                      placeholder="Ex: Florianópolis"
                      value={form.city}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      maxLength={60}
                      required
                    />
                  </div>
                  <FieldHint message={showError('city')} />
                </div>
              </div>

              <div className={styles['ce-row']}>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="bairro">Bairro</label>
                  <div className={styles['ce-input-wrap']}>
                    <input
                      id="bairro"
                      name="bairro"
                      type="text"
                      className={inputClass('bairro', 'no-icon')}
                      placeholder="Ex: Centro"
                      value={form.bairro}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      maxLength={60}
                    />
                  </div>
                  <FieldHint message={showError('bairro')} />
                </div>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="rua">Rua</label>
                  <div className={styles['ce-input-wrap']}>
                    <input
                      id="rua"
                      name="rua"
                      type="text"
                      className={inputClass('rua', 'no-icon')}
                      placeholder="Ex: Rua XV de Novembro, 200"
                      value={form.rua}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      maxLength={TEXT_LIMITS.rua}
                    />
                  </div>
                  <FieldHint message={showError('rua')} />
                </div>
              </div>

              <div className={styles['ce-field']}>
                <label className={styles['ce-field-label']} htmlFor="referencia">Referência</label>
                <div className={styles['ce-input-wrap']}>
                  <input
                    id="referencia"
                    name="referencia"
                    type="text"
                    className={inputClass('referencia')}
                    placeholder="Ex: Próximo à Praça Central"
                    value={form.referencia}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    maxLength={TEXT_LIMITS.referencia}
                  />
                  <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" /></svg>
                </div>
                <FieldHint message={showError('referencia')} />
              </div>

              <div className={styles['ce-mapa-container']} style={{ position: 'relative' }}>
                {mapLoading && (
                  <div style={{
                    position: 'absolute', inset: 0, display: 'flex',
                    alignItems: 'center', justifyContent: 'center',
                    background: 'rgba(0,0,0,0.35)', borderRadius: '10px',
                    zIndex: 2, color: '#fff', fontSize: '0.85rem', gap: '8px',
                  }}>
                    <span style={{ animation: 'spin 1s linear infinite', display: 'inline-block' }}>⟳</span>
                    Atualizando mapa…
                  </div>
                )}
                <iframe
                  key={mapSrc}
                  title="mapa-localizacao"
                  src={mapSrc}
                  className={styles['ce-mapa-iframe']}
                  loading="lazy"
                />
              </div>
            </div>

            <div className={styles['ce-form-actions']}>
              <Link to="/" className={styles['ce-btn-cancel']}>Cancelar</Link>
              <button type="submit" className={styles['ce-btn-submit']}>Salvar Evento</button>
            </div>

          </form>
        </div>
      </main>

      <footer className={styles['ce-footer']}>
        <div className={styles['ce-footer-inner']}>
          <div className={styles['ce-footer-brand']}>
            <Link to="/" aria-label="BaileSul">
              <img src="/imagens/BaileSul.png" alt="BaileSul" className={styles['ce-footer-logo']} />
            </Link>
          </div>
          <div className={styles['ce-footer-copy-block']}>
            <p className={styles['ce-footer-copy']}>© BaileSul – Todos os direitos reservados.</p>
          </div>
          <nav className={styles['ce-footer-nav-block']} aria-label="Navegação do rodapé">
            <h4 className={styles['ce-footer-heading']}>Navegação</h4>
            <div className={styles['ce-footer-nav']}>
              <div className={styles['ce-footer-nav-col']}>
                {footerLinks.slice(0, 3).map((item) => (
                  <Link key={item.to} to={item.to}>{item.label}</Link>
                ))}
              </div>
              <div className={styles['ce-footer-nav-col']}>
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
