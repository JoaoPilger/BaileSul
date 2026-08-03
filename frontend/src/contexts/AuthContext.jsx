/* eslint-disable react-refresh/only-export-components */
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import api from '../services/api'

const STORAGE_KEY = 'bailesul_auth'

const AuthContext = createContext(null)

/**
 * Decodifica o payload de um JWT SEM validar assinatura (só pra ler
 * campos como `exp` no front). Nunca confie nisso pra autorizar nada —
 * é só leitura de conveniência, a validação de verdade é sempre no backend.
 */
function decodeJwtPayload(token) {
  try {
    const [, payloadB64] = token.split('.')
    const json = atob(payloadB64.replace(/-/g, '+').replace(/_/g, '/'))
    return JSON.parse(json)
  } catch {
    return null
  }
}

/** Retorna o timestamp (ms) de expiração do token, ou null se não der pra ler. */
function getTokenExpiryMs(token) {
  const payload = decodeJwtPayload(token)
  if (!payload?.exp) return null
  return payload.exp * 1000
}

/** true se o token já expirou (ou não pôde ser lido). */
export function isTokenExpired(token) {
  if (!token) return true
  const expiryMs = getTokenExpiryMs(token)
  if (!expiryMs) return true
  return Date.now() >= expiryMs
}

function loadStoredAuth() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw)
    if (!parsed?.token || !parsed?.usuario?.tipo) return null
    if (isTokenExpired(parsed.token)) return null
    return parsed
  } catch {
    return null
  }
}

function mapUsuario(data, fallbackEmail) {
  return {
    id: data.usuario_id ?? data.id,
    email: data.email ?? fallbackEmail ?? '',
    tipo: data.tipo,
  }
}

export function AuthProvider({ children }) {
  /* Restaura a sessão salva no localStorage ao carregar a página (F5) */
  const [auth, setAuth] = useState(loadStoredAuth)
  const [isVendedor, setIsVendedor] = useState(false)

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

  // eslint-disable-next-line react-hooks/preserve-manual-memoization
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

  // Agenda um logout automático (sem precisar de F5 ou de uma chamada de API
  // falhar) para o exato instante em que o token expirar, e já manda pro login.
  useEffect(() => {
    if (!auth?.token) return

    const expirarAgora = () => {
      localStorage.removeItem(STORAGE_KEY)
      setAuth(null)
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    }

    const expiryMs = getTokenExpiryMs(auth.token)
    if (!expiryMs) return

    const msRestantes = expiryMs - Date.now()
    if (msRestantes <= 0) {
      expirarAgora()
      return
    }

    const timer = setTimeout(expirarAgora, msRestantes)
    return () => clearTimeout(timer)
  }, [auth?.token])

  // Detecta token apagado/alterado manualmente (ex.: DevTools) na MESMA aba.
  // O evento nativo `storage` só dispara em outras abas, então aqui a gente
  // faz um polling leve comparando o localStorage com o estado em memória.
  useEffect(() => {
    if (!auth?.token) return

    const verificar = () => {
      const raw = localStorage.getItem(STORAGE_KEY)
      let tokenAtual
      try {
        tokenAtual = raw ? JSON.parse(raw)?.token : null
      } catch {
        tokenAtual = null
      }

      if (tokenAtual !== auth.token) {
        setAuth(null)
        if (window.location.pathname !== '/login') {
          window.location.href = '/login'
        }
      }
    }

    const intervalo = setInterval(verificar, 1500)
    return () => clearInterval(intervalo)
  }, [auth?.token])

  // Detecta logout/expiração feito em OUTRA aba (o storage event não dispara
  // na aba que fez a mudança, só nas demais).
  useEffect(() => {
    const onStorage = (e) => {
      if (e.key !== STORAGE_KEY) return
      if (!e.newValue) {
        setAuth(null)
        if (window.location.pathname !== '/login') {
          window.location.href = '/login'
        }
      }
    }
    window.addEventListener('storage', onStorage)
    return () => window.removeEventListener('storage', onStorage)
  }, [])

  // Usuários do tipo "pessoal" podem ou não ser vendedores de alguma
  // comunidade (é um vínculo na tabela `vendedores`, não um campo do
  // usuário). Checa isso uma vez, sempre que a sessão de um "pessoal" muda.
  useEffect(() => {
    if (auth?.usuario?.tipo !== 'pessoal' || !auth?.token) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setIsVendedor(false)
      return
    }

    let cancelado = false
    api
      .get('/vendedores/me', { headers: { Authorization: `Bearer ${auth.token}` } })
      .then(({ data }) => {
        if (!cancelado) setIsVendedor(Array.isArray(data) && data.length > 0)
      })
      .catch(() => {
        if (!cancelado) setIsVendedor(false)
      })

    return () => { cancelado = true }
  }, [auth?.usuario?.tipo, auth?.token])

  const value = useMemo(
    () => ({
      usuario: auth?.usuario ?? null,
      token: auth?.token ?? null,
      isAuthenticated: Boolean(auth?.token),
      isVendedor,
      tokenExpiryMs: auth?.token ? getTokenExpiryMs(auth.token) : null,
      isTokenExpired: () => isTokenExpired(auth?.token),
      login,
      register,
      logout,
    }),
    [auth, isVendedor, login, register, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth deve ser usado dentro de AuthProvider')
  return ctx
}
