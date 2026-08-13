import { useCallback, useEffect, useRef, useState } from 'react'
import { useAuth } from '../contexts/AuthContext'
import api from '../services/api'

const POLL_MS = 60000

/** Estado + ações da central de notificações, compartilhado entre o sino desktop e o item mobile do Header. */
export function useNotificacoes() {
  const { isAuthenticated } = useAuth()
  const [open, setOpen] = useState(false)
  const [contagem, setContagem] = useState(0)
  const [notificacoes, setNotificacoes] = useState([])
  const [loading, setLoading] = useState(false)
  const [erro, setErro] = useState('')
  const carregouLista = useRef(false)

  const buscarContagem = useCallback(() => {
    if (!isAuthenticated) return
    api.get('/notificacoes/contagem')
      .then(({ data }) => setContagem(data?.nao_lidas || 0))
      .catch(() => {})
  }, [isAuthenticated])

  const buscarLista = useCallback(() => {
    if (!isAuthenticated) return
    setLoading(true)
    setErro('')
    api.get('/notificacoes')
      .then(({ data }) => {
        setNotificacoes(Array.isArray(data) ? data : [])
        carregouLista.current = true
      })
      .catch(() => setErro('Não foi possível carregar as notificações.'))
      .finally(() => setLoading(false))
  }, [isAuthenticated])

  useEffect(() => {
    if (!isAuthenticated) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setContagem(0)
      setNotificacoes([])
      carregouLista.current = false
      return
    }
    buscarContagem()
    const intervalo = setInterval(buscarContagem, POLL_MS)
    return () => clearInterval(intervalo)
  }, [isAuthenticated, buscarContagem])

  const toggleOpen = useCallback(() => {
    setOpen((prev) => {
      const next = !prev
      if (next && !carregouLista.current) buscarLista()
      return next
    })
  }, [buscarLista])

  const close = useCallback(() => setOpen(false), [])

  const marcarLida = useCallback((id) => {
    setNotificacoes((prev) => prev.map((n) => (n.id === id ? { ...n, lida: true } : n)))
    setContagem((prev) => Math.max(0, prev - 1))
    api.patch(`/notificacoes/${id}/lida`).catch(() => {})
  }, [])

  const marcarTodas = useCallback(() => {
    setNotificacoes((prev) => prev.map((n) => ({ ...n, lida: true })))
    setContagem(0)
    api.patch('/notificacoes/lidas').catch(() => {})
  }, [])

  return {
    open,
    contagem,
    notificacoes,
    loading,
    erro,
    toggleOpen,
    close,
    marcarLida,
    marcarTodas,
  }
}
