import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
})

api.interceptors.request.use((config) => {
  try {
    const raw = localStorage.getItem('bailesul_auth')
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

export default api
