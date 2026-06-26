import { useState, useRef } from 'react'
import { cn } from '../../utils/cn';
import { Link, useNavigate } from 'react-router-dom'
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

const ESTILOS = [
  { value: 'sertanejo', label: 'Sertanejo' },
  { value: 'forro',     label: 'Forró' },
  { value: 'pagode',    label: 'Pagode' },
  { value: 'rock',      label: 'Rock' },
  { value: 'gaucha',    label: 'Gaúcha' },
  { value: 'axe',       label: 'Axé' },
  { value: 'mpb',       label: 'MPB' },
  { value: 'outro',     label: 'Outro' },
]

const TEXT_LIMITS = {
  title: 120,
  band: 80,
  rua: 120,
  referencia: 150,
}

function FieldHint({ message }) {
  if (!message) return null
  return <p className={styles['ce-field-error']} role="alert">{message}</p>
}

export default function CriarEvento() {
  const { isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const fileRef = useRef(null)

  const [form, setForm] = useState({
    title:     '',
    band:      '',
    style:     'sertanejo',
    dateStart: '',
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

  const contaLink   = isAuthenticated ? '/perfil' : '/login'
  const footerLinks = [
    { to: '/eventos',      label: 'Eventos' },
    { to: '/calendario',   label: 'Calendário' },
    { to: '/mapa',         label: 'Mapa' },
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
    try {
      const res  = await fetch(`https://viacep.com.br/ws/${cep}/json/`)
      const data = await res.json()
      if (!data.erro) {
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
    } catch {}
    finally { setCepLoading(false) }
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
  }

  const removeVendor = (id) => setVendors((s) => s.filter((v) => v.id !== id))

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

    const descricaoParts = []
    if (normalizedForm.band?.trim()) {
      descricaoParts.push(`Banda/Artista: ${normalizedForm.band.trim()}`)
    }
    if (normalizedForm.style) {
      const estiloLabel = ESTILOS.find(e => e.value === normalizedForm.style)?.label || normalizedForm.style
      descricaoParts.push(`Estilo musical: ${estiloLabel}`)
    }
    const descricao = descricaoParts.join('\n')

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

      let imageUrl = databaseEvent.foto_capa_url || imagemPreview || fallbackImage;
      if (imageUrl && imageUrl.includes('/media/')) {
        const idx = imageUrl.indexOf('/media/');
        imageUrl = imageUrl.substring(idx);
      }

      const newEvent = {
        id:         databaseEvent.id || Date.now(),
        title:      normalizedForm.title,
        band:       normalizedForm.band,
        style:      normalizedForm.style,
        date:       normalizedForm.dateStart || new Date().toISOString().slice(0, 10),
        date_end:   normalizedForm.dateEnd,
        time_start: normalizedForm.timeStart,
        time_end:   normalizedForm.timeEnd,
        image:      imageUrl,
        price:      normalizedForm.price
          ? (/^(grátis|gratis)$/i.test(normalizedForm.price.trim())
              ? 'Grátis'
              : `R$ ${normalizedForm.price.replace(/^R\$\s*/i, '').trim()}`)
          : 'Grátis',
        city:       normalizedForm.city,
        cep:        normalizedForm.cep,
        bairro:     normalizedForm.bairro,
        rua:        normalizedForm.rua,
        referencia: normalizedForm.referencia,
        vendors,
        latitude:   databaseEvent.latitude,
        longitude:  databaseEvent.longitude,
        created_at: new Date().toISOString(),
      }

      const raw  = localStorage.getItem('bailesul_events')
      const list = raw ? JSON.parse(raw) : []
      list.unshift(newEvent)
      localStorage.setItem('bailesul_events', JSON.stringify(list))
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

              <div className={styles['ce-row']}>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="band">Banda / Artista *</label>
                  <div className={styles['ce-input-wrap']}>
                    <input
                      id="band"
                      name="band"
                      type="text"
                      className={inputClass('band')}
                      placeholder="Ex: Os Gauchões"
                      value={form.band}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      maxLength={TEXT_LIMITS.band}
                      required
                    />
                    <svg viewBox="0 0 24 24"><path d="M9 18V5l12-2v13" /><circle cx="6" cy="18" r="3" /><circle cx="18" cy="16" r="3" /></svg>
                  </div>
                  <FieldHint message={showError('band')} />
                </div>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="style">Estilo Musical *</label>
                  <div className={styles['ce-input-wrap']}>
                    <select id="style" name="style" className={cn(styles['ce-input'], styles['no-icon'])} value={form.style} onChange={handleChange}>
                      {ESTILOS.map((e) => <option key={e.value} value={e.value}>{e.label}</option>)}
                    </select>
                  </div>
                </div>
              </div>

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

              <div className={styles['ce-vendor-row']}>
                <div className={styles['ce-field']}>
                  <label className={styles['ce-field-label']} htmlFor="vendorName">Nome do Vendedor</label>
                  <div className={styles['ce-input-wrap']}>
                    <input
                      id="vendorName"
                      type="text"
                      className={cn(styles['ce-input'], vendorError && styles['ce-input--error'])}
                      placeholder="Ex: Bar do João"
                      value={vendorName}
                      onChange={(e) => {
                        setVendorName(e.target.value.slice(0, 80))
                        if (vendorError) setVendorError('')
                      }}
                      onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addVendor() } }}
                    />
                    <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /></svg>
                  </div>
                  <FieldHint message={vendorError} />
                </div>
                <button type="button" className={styles['ce-btn-add']} onClick={addVendor}>+ Adicionar</button>
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

              <div className={styles['ce-mapa-container']}>
                <iframe
                  title="mapa-localizacao"
                  src="https://www.openstreetmap.org/export/embed.html?bbox=-53.0,-29.5,-48.0,-26.0&layer=mapnik"
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
