import axios from 'axios'

const STORAGE_KEY = 'bailesul_auth'

const api = axios.create({
  baseURL: '/api',
})

api.interceptors.request.use((config) => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return config
    const { token } = JSON.parse(raw)
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
  } catch {
    /* ignore */
  }
  return config
})

// Se o backend responder 401 (token inválido/expirado/revogado), a sessão
// local não faz mais sentido: limpa o storage e manda pro login.
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      const tinhaSessao = Boolean(localStorage.getItem(STORAGE_KEY))
      localStorage.removeItem(STORAGE_KEY)

      // Evita loop/redirect desnecessário se a chamada 401 veio de uma rota
      // pública (ex.: usuário nunca esteve logado) ou se já está no login.
      if (tinhaSessao && window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  },
)

export default api