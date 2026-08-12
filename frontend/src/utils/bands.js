import api from '../services/api'

/**
 * Carrega bandas da API real (/api/bandas).
 * Mapeia os campos do backend para o formato do frontend.
 */
export async function loadBands() {
  try {
    const res = await api.get('/bandas?limite=100')
    const rows = res.data.dados || []
    return rows.map(mapBandaRow)
  } catch (err) {
    console.error('Erro ao buscar bandas da API:', err)
    return []
  }
}

/**
 * Carrega o detalhe de uma banda pelo id.
 */
export async function loadBandById(id) {
  if (!id) return null
  try {
    const res = await api.get(`/bandas/${id}`)
    if (res.data) {
      return mapBandaDetail(res.data)
    }
  } catch (err) {
    console.error(`Erro ao buscar banda ${id}:`, err)
  }
  return null
}

function normalizarMedia(url) {
  if (url && url.includes('/media/')) {
    return url.substring(url.indexOf('/media/'))
  }
  return url || ''
}

function mapBandaRow(row) {
  return {
    id: row.usuario_id,
    title: row.nome_artistico || 'Banda',
    style: row.estilo_musical || '',
    description: row.descricao || '',
    whatsapp: row.whatsapp || '',
    cnpj_validado: row.cnpj_validado || false,
    foto_perfil_url: normalizarMedia(row.foto_perfil_url),
  }
}

function mapBandaDetail(row) {
  return {
    ...mapBandaRow(row),
    video_url: row.video_url || '',
    eventos: (row.eventos || []).map((e) => ({
      id: e.id,
      titulo: e.titulo,
      data_inicio: e.data_inicio,
      data_fim: e.data_fim,
      local: e.local_nome,
      comunidade: e.comunidade,
      cidade: e.cidade,
      estado: e.estado,
    })),
    midias: (row.midias || []).map((m) => ({ ...m, url: normalizarMedia(m.url) })),
    seguidores: row.seguidores || 0,
    media_avaliacao: row.media_avaliacao || 0,
    total_avaliacoes: row.total_avaliacoes || 0,
    seguindo: row.seguindo || false,
    minha_avaliacao: row.minha_avaliacao || 0,
  }
}
