import api from '../services/api'

const STORAGE_KEY = 'bailesul_events'
const HIDDEN_KEY = 'bailesul_deleted_event_ids'

const MOCK_EVENTS = [
  {
    id: 1,
    title: 'Baile do Rancho' ,
    date: '2025-06-14',
    city: 'Concórdia',
    style: 'sertanejo',
    image: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80',
    price: 'R$ 30',
  },
  {
    id: 2,
    title: 'Forró na Praça',
    date: '2025-06-21',
    city: 'Seara',
    style: 'forro',
    image: 'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=600&q=80',
    price: 'Grátis',
  },
  {
    id: 3,
    title: 'Noite Gaúcha',
    date: '2025-06-28',
    city: 'Peritiba',
    style: 'gaucha',
    image: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=600&q=80',
    price: 'R$ 20',
  },
]

function getHiddenIds() {
  try {
    const raw = localStorage.getItem(HIDDEN_KEY)
    return raw ? new Set(JSON.parse(raw).map(String)) : new Set()
  } catch {
    return new Set()
  }
}

function parseDescricao(descricao) {
  const info = { band: '', style: '' }
  if (!descricao) return info
  
  const bandMatch = descricao.match(/Banda\/Artista:\s*(.*)/i)
  if (bandMatch) info.band = bandMatch[1].trim()
  
  const styleMatch = descricao.match(/Estilo musical:\s*(.*)/i)
  if (styleMatch) info.style = styleMatch[1].trim().toLowerCase()
  
  return info
}

function mapDatabaseEvent(row) {
  const { band, style } = parseDescricao(row.descricao)
  
  let eventDate = ''
  if (row.data_inicio) {
    eventDate = row.data_inicio.split('T')[0]
  }
  
  let eventDateEnd = ''
  if (row.data_fim) {
    eventDateEnd = row.data_fim.split('T')[0]
  }

  let priceDisplay = 'Grátis'
  if (row.valor_ingresso !== null && row.valor_ingresso !== undefined) {
    const val = parseFloat(row.valor_ingresso)
    if (!isNaN(val) && val > 0) {
      priceDisplay = `R$ ${val.toFixed(2).replace('.', ',')}`
    }
  }

  let rua = ''
  let bairro = ''
  let referencia = ''
  let city = ''
  let cep = ''

  if (row.local_endereco) {
    if (row.local_endereco.includes(';')) {
      const addressParts = row.local_endereco.split(';')
      rua = addressParts[0] || ''
      bairro = addressParts[1] || ''
      referencia = addressParts[2] || ''
      city = addressParts[3] || row.cidade || row.local_nome || ''
      cep = addressParts[4] || ''
    } else {
      const addressParts = row.local_endereco.split(', ')
      rua = addressParts[0] || ''
      bairro = addressParts[1] || ''
      referencia = addressParts[2] || ''
      city = row.cidade || row.local_nome || addressParts[3] || ''
      cep = addressParts[4] || ''
    }
  } else {
    city = row.cidade || row.local_nome || ''
  }

  let image = row.foto_capa_url || 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80';
  if (image.includes('/media/')) {
    const idx = image.indexOf('/media/');
    image = image.substring(idx);
  }

  return {
    id: row.id,
    title: row.titulo,
    description: row.descricao || '',
    band: band || row.comunidade || 'Organização',
    style: style || 'gaucha',
    date: eventDate,
    date_end: eventDateEnd,
    image: image,
    price: priceDisplay,
    city: city,
    cep: cep,
    bairro: bairro,
    rua: rua,
    referencia: referencia,
    local: row.local_nome || city,
    time_start: row.dias?.[0]?.hora_inicio || '',
    time_end: row.dias?.[0]?.hora_fim || '',
    vendors: row.vendors || [],
    latitude: row.latitude,
    longitude: row.longitude,
  }
}

export async function loadEvents() {
  const hiddenIds = getHiddenIds()

  let apiEvents = []
  try {
    const res = await api.get('/eventos?limite=100')
    const rows = res.data.dados || []
    apiEvents = rows.map(mapDatabaseEvent)
  } catch (err) {
    console.error('Erro ao buscar eventos da API:', err)
  }

  const raw = localStorage.getItem(STORAGE_KEY)
  const savedEvents = raw ? JSON.parse(raw) : []

  const byId = new Map()

  apiEvents.forEach((event) => {
    const id = String(event.id)
    if (!hiddenIds.has(id)) byId.set(id, event)
  })

  savedEvents.forEach((event) => {
    const id = String(event.id)
    if (!hiddenIds.has(id) && !byId.has(id)) byId.set(id, event)
  })

  MOCK_EVENTS.forEach((event) => {
    const id = String(event.id)
    if (!hiddenIds.has(id) && !byId.has(id)) {
      byId.set(id, event)
    }
  })

  return Array.from(byId.values())
}

export async function loadEventById(id) {
  if (!id) return null
  const target = String(id)

  try {
    const res = await api.get(`/eventos/${id}`)
    if (res.data) {
      return mapDatabaseEvent(res.data)
    }
  } catch (err) {
    console.error(`Erro ao buscar detalhe do evento ${id} da API:`, err)
  }

  const list = await loadEvents()
  return list.find((event) => String(event.id) === target) || null
}

export async function deleteEventById(id) {
  if (!id) return
  const target = String(id)

  try {
    await api.delete(`/eventos/${id}`)
  } catch (err) {
    console.error('Erro ao deletar evento na API:', err)
  }

  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw) {
      const savedEvents = JSON.parse(raw).filter((event) => String(event.id) !== target)
      localStorage.setItem(STORAGE_KEY, JSON.stringify(savedEvents))
    }

    const hiddenIds = getHiddenIds()
    hiddenIds.add(target)
    localStorage.setItem(HIDDEN_KEY, JSON.stringify(Array.from(hiddenIds)))
  } catch (err) {
    console.error('Erro ao excluir evento localmente:', err)
  }
}
