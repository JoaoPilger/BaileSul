import api from '../services/api'

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

  let image = row.foto_capa_url || 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80'
  if (image.includes('/media/')) {
    const idx = image.indexOf('/media/')
    image = image.substring(idx)
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
  try {
    const res = await api.get('/eventos?limite=100')
    const rows = res.data.dados || []
    return rows.map(mapDatabaseEvent)
  } catch (err) {
    console.error('Erro ao buscar eventos da API:', err)
    return []
  }
}

export async function loadEventById(id) {
  if (!id) return null

  try {
    const res = await api.get(`/eventos/${id}`)
    if (res.data) {
      return mapDatabaseEvent(res.data)
    }
  } catch (err) {
    console.error(`Erro ao buscar detalhe do evento ${id} da API:`, err)
  }

  return null
}