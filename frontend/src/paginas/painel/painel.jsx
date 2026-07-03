import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import PainelComunidade from './painel_comunidade.jsx'
import PainelBanda from './painel_banda.jsx'

export default function Painel() {
  const { usuario, isAuthenticated } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login')
    } else if (usuario?.tipo !== 'comunidade' && usuario?.tipo !== 'banda') {
      // Pessoal não tem dashboard próprio — a home pública já serve pra ele.
      navigate('/')
    }
  }, [isAuthenticated, usuario, navigate])

  if (usuario?.tipo === 'comunidade') return <PainelComunidade />
  if (usuario?.tipo === 'banda') return <PainelBanda />
  return null
}
