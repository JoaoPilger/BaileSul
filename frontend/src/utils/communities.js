import api from '../services/api'

/**
 * Carrega comunidades da API real (/api/comunidades).
 * Mapeia os campos do backend para o formato do frontend.
 */
export async function loadCommunities() {
  try {
    const res = await api.get('/comunidades?limite=100')
    const rows = res.data.dados || []
    return rows.map(mapComunidadeRow)
  } catch (err) {
    console.error('Erro ao buscar comunidades da API:', err)
    return []
  }
}

/**
 * Carrega o detalhe de uma comunidade pelo id.
 */
export async function loadCommunityById(id) {
  if (!id) return null
  try {
    const res = await api.get(`/comunidades/${id}`)
    if (res.data) {
      return mapComunidadeDetail(res.data)
    }
  } catch (err) {
    console.error(`Erro ao buscar comunidade ${id}:`, err)
  }
  return null
}

function normalizarMedia(url) {
  if (url && url.includes('/media/')) {
    return url.substring(url.indexOf('/media/'))
  }
  return url || ''
}

function mapComunidadeRow(row) {
  return {
    id: row.usuario_id,
    title: row.nome_entidade || 'Comunidade',
    description: row.descricao || '',
    whatsapp: row.whatsapp || '',
    city: row.cidade || '',
    state: row.estado || '',
    address: row.endereco || '',
    latitude: row.latitude,
    longitude: row.longitude,
    cnpj_validado: row.cnpj_validado || false,
    foto_perfil_url: normalizarMedia(row.foto_perfil_url),
  }
}

function mapComunidadeDetail(row) {
  return {
    ...mapComunidadeRow(row),
    eventos: (row.eventos || []).map((e) => ({
      id: e.id,
      titulo: e.titulo,
      data_inicio: e.data_inicio,
      data_fim: e.data_fim,
      local: e.local_nome,
      valor_ingresso: e.valor_ingresso,
      foto_capa_url: e.foto_capa_url,
      status: e.status,
    })),
    midias: (row.midias || []).map((m) => ({ ...m, url: normalizarMedia(m.url) })),
    seguidores: row.seguidores || 0,
    media_avaliacao: row.media_avaliacao || 0,
    total_avaliacoes: row.total_avaliacoes || 0,
    seguindo: row.seguindo || false,
    minha_avaliacao: row.minha_avaliacao || 0,
  }
}
