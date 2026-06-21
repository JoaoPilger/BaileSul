import { createContext, useCallback, useContext, useMemo, useState } from 'react'
import api from '../services/api'

const STORAGE_KEY = 'bailesul_auth'

const AuthContext = createContext(null)

function loadStoredAuth() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw)
    if (!parsed?.token || !parsed?.usuario?.tipo) return null
    return parsed
  } catch {
    return null
  }
}

/* Removed development auto-login helper to avoid permanent dev registrations.
   The provider now only loads stored auth from `localStorage` when present. */

function mapUsuario(data, fallbackEmail) {
  return {
    id: data.usuario_id ?? data.id,
    email: data.email ?? fallbackEmail ?? '',
    tipo: data.tipo,
  }
}

export function AuthProvider({ children }) {
  const [auth, setAuth] = useState(() => loadStoredAuth())

  const persistAuth = useCallback((next) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
    setAuth(next)
    return next.usuario
  }, [])

  const login = useCallback(async (email, senha) => {
    const { data } = await api.post('/auth/login', { email, senha })
    return persistAuth({
      token: data.token,
      usuario: mapUsuario(data, email),
    })
  }, [persistAuth])

  const register = useCallback(async ({ email, senha, tipo, perfil }) => {
    const { data } = await api.post('/auth/register', { email, senha, tipo, perfil })
    return persistAuth({
      token: data.token,
      usuario: mapUsuario(data, email),
    })
  }, [persistAuth])

  const logout = useCallback(async () => {
    try {
      if (auth?.token) {
        await api.post('/auth/logout')
      }
    } catch {
      /* revoga localmente mesmo se o servidor falhar */
    } finally {
      localStorage.removeItem(STORAGE_KEY)
      setAuth(null)
    }
  }, [auth?.token])

  const value = useMemo(
    () => ({
      usuario: auth?.usuario ?? null,
      token: auth?.token ?? null,
      isAuthenticated: Boolean(auth?.token),
      login,
      register,
      logout,
    }),
    [auth, login, register, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth deve ser usado dentro de AuthProvider')
  return ctx
}
