import { useCallback, useEffect, useState } from 'react'
import { useAuth } from '../contexts/AuthContext'
import api from '../services/api'

const POLL_MS = 60000

/**
 * Contagem de notificações não lidas do usuário autenticado, usada pelo
 * badge do sino no Header (desktop e mobile). O histórico completo com
 * filtros e ações de marcar como lida vive na página /notificacoes.
 */
export function useNotificacoes() {
  const { isAuthenticated } = useAuth()
  const [contagem, setContagem] = useState(0)

  const atualizarContagem = useCallback(() => {
    if (!isAuthenticated) return
    api.get('/notificacoes/contagem')
      .then(({ data }) => setContagem(data?.nao_lidas || 0))
      .catch(() => {})
  }, [isAuthenticated])

  useEffect(() => {
    if (!isAuthenticated) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setContagem(0)
      return
    }
    atualizarContagem()
    const intervalo = setInterval(atualizarContagem, POLL_MS)
    return () => clearInterval(intervalo)
  }, [isAuthenticated, atualizarContagem])

  return { contagem, atualizarContagem }
}
