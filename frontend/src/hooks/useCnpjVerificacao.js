import { useEffect, useState } from 'react'
import api from '../services/api'
import { isValidCnpj } from '../utils/authFormValidation'

/**
 * Verifica um CNPJ (já válido no formato/dígitos) contra a Receita Federal,
 * com debounce, assim que o usuário termina de digitar.
 * status: 'idle' | 'checking' | 'valido' | 'invalido'
 */
export function useCnpjVerificacao(cnpj, { debounceMs = 600 } = {}) {
  const [status, setStatus] = useState('idle')
  const [razaoSocial, setRazaoSocial] = useState(null)

  useEffect(() => {
    if (!isValidCnpj(cnpj)) {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- reseta o status quando o CNPJ digitado fica inválido
      setStatus('idle')
      setRazaoSocial(null)
      return
    }

    let ativo = true
    setStatus('checking')

    const timer = setTimeout(() => {
      api.get('/cnpj/verificar', { params: { cnpj } })
        .then(({ data }) => {
          if (!ativo) return
          if (!data.api_disponivel) {
            setStatus('idle')
            setRazaoSocial(null)
            return
          }
          setStatus(data.valido ? 'valido' : 'invalido')
          setRazaoSocial(data.razao_social || null)
        })
        .catch(() => {
          if (ativo) {
            setStatus('idle')
            setRazaoSocial(null)
          }
        })
    }, debounceMs)

    return () => {
      ativo = false
      clearTimeout(timer)
    }
  }, [cnpj, debounceMs])

  return { status, razaoSocial }
}
