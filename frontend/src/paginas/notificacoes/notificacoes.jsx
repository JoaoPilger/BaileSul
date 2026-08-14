import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Bell, BellOff, CheckCheck } from 'lucide-react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { useAuth } from '../../contexts/AuthContext'
import { useNotificacoes } from '../../hooks/useNotificacoes'
import api from '../../services/api'
import styles from './notificacoes.module.css'

const ABAS = [
  { key: 'todas',      label: 'Todas' },
  { key: 'nao_lidas',  label: 'Não vistas' },
  { key: 'lidas',      label: 'Vistas' },
]

const LIMITE = 10

function formatQuando(dataStr) {
  if (!dataStr) return ''
  const data = new Date(dataStr)
  if (Number.isNaN(data.getTime())) return ''
  const diffMs = Date.now() - data.getTime()
  const diffMin = Math.floor(diffMs / 60000)
  if (diffMin < 1) return 'agora'
  if (diffMin < 60) return `há ${diffMin} min`
  const diffH = Math.floor(diffMin / 60)
  if (diffH < 24) return `há ${diffH}h`
  const diffDias = Math.floor(diffH / 24)
  if (diffDias < 7) return `há ${diffDias}d`
  return data.toLocaleDateString('pt-BR')
}

export default function Notificacoes() {
  const { isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const { contagem, atualizarContagem } = useNotificacoes()

  const [abaAtiva, setAbaAtiva] = useState('todas')
  const [pagina, setPagina] = useState(1)
  const [notificacoes, setNotificacoes] = useState([])
  const [paginacao, setPaginacao] = useState({ total: 0, total_paginas: 0 })
  const [loading, setLoading] = useState(true)
  const [erro, setErro] = useState('')
  const [marcandoTodas, setMarcandoTodas] = useState(false)

  useEffect(() => {
    if (!isAuthenticated) navigate('/login')
  }, [isAuthenticated, navigate])

  const carregar = useCallback(() => {
    if (!isAuthenticated) return
    setLoading(true)
    setErro('')
    api.get('/notificacoes', { params: { status: abaAtiva, pagina, limite: LIMITE } })
      .then(({ data }) => {
        setNotificacoes(Array.isArray(data?.dados) ? data.dados : [])
        setPaginacao(data?.paginacao || { total: 0, total_paginas: 0 })
      })
      .catch(() => setErro('Não foi possível carregar as notificações.'))
      .finally(() => setLoading(false))
  }, [isAuthenticated, abaAtiva, pagina])

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- busca a lista ao montar e sempre que aba/página mudam
    carregar()
  }, [carregar])

  const mudarAba = (key) => {
    setAbaAtiva(key)
    setPagina(1)
  }

  const marcarLida = (id) => {
    const alvo = notificacoes.find((n) => n.id === id)
    if (!alvo || alvo.lida) return

    setNotificacoes((prev) => {
      const atualizado = prev.map((n) => (n.id === id ? { ...n, lida: true } : n))
      // Na aba "Não vistas" o item some assim que deixa de ser não-lido.
      return abaAtiva === 'nao_lidas' ? atualizado.filter((n) => n.id !== id) : atualizado
    })
    if (abaAtiva === 'nao_lidas') {
      setPaginacao((p) => ({ ...p, total: Math.max(0, p.total - 1) }))
    }

    api.patch(`/notificacoes/${id}/lida`)
      .then(() => atualizarContagem())
      .catch(() => {
        // Falhou no servidor: refaz a busca pra voltar ao estado real.
        carregar()
      })
  }

  const marcarTodas = () => {
    setMarcandoTodas(true)
    api.patch('/notificacoes/lidas')
      .then(() => {
        carregar()
        atualizarContagem()
      })
      .catch(() => {})
      .finally(() => setMarcandoTodas(false))
  }

  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>

        <div className={styles.hero}>
          <div className={styles.heroLeft}>
            <div className={styles.heroIconWrap}>
              <Bell size={22} strokeWidth={1.8} />
            </div>
            <div>
              <h1 className={styles.heroTitle}>Notificações</h1>
              <p className={styles.heroSub}>Tudo que aconteceu por aqui, em um só lugar</p>
            </div>
          </div>
          {(abaAtiva !== 'lidas' && contagem > 0) && (
            <button
              type="button"
              className={styles.btnMarcarTodas}
              onClick={marcarTodas}
              disabled={marcandoTodas}
            >
              <CheckCheck size={15} />
              {marcandoTodas ? 'Marcando...' : 'Marcar todas como lidas'}
            </button>
          )}
        </div>

        <div className={styles.toolbar}>
          <div className={styles.abas}>
            {ABAS.map(({ key, label }) => (
              <button
                key={key}
                type="button"
                className={`${styles.aba} ${abaAtiva === key ? styles.abaAtiva : ''}`}
                onClick={() => mudarAba(key)}
              >
                {label}
              </button>
            ))}
          </div>
          <span className={styles.contagem}>
            {paginacao.total} notificaç{paginacao.total === 1 ? 'ão' : 'ões'}
          </span>
        </div>

        {loading && <div className={styles.vazio}>Carregando...</div>}
        {!loading && erro && <div className={styles.vazioDanger}>{erro}</div>}

        {!loading && !erro && notificacoes.length === 0 && (
          <div className={styles.vazio}>
            <BellOff size={32} strokeWidth={1.5} aria-hidden />
            <p>
              {abaAtiva === 'nao_lidas'
                ? 'Nenhuma notificação não vista.'
                : abaAtiva === 'lidas'
                ? 'Nenhuma notificação vista ainda.'
                : 'Nenhuma notificação por aqui ainda.'}
            </p>
          </div>
        )}

        {!loading && !erro && notificacoes.length > 0 && (
          <div className={styles.lista}>
            {notificacoes.map((n) => (
              <button
                key={n.id}
                type="button"
                className={`${styles.item} ${n.lida ? '' : styles['item--naoLida']}`}
                onClick={() => marcarLida(n.id)}
              >
                <span className={styles.itemDot} aria-hidden />
                <span className={styles.itemBody}>
                  <span className={styles.itemTitulo}>{n.titulo}</span>
                  {n.mensagem && <span className={styles.itemMensagem}>{n.mensagem}</span>}
                  <span className={styles.itemQuando}>{formatQuando(n.criado_em)}</span>
                </span>
              </button>
            ))}
          </div>
        )}

        {!loading && paginacao.total_paginas > 1 && (
          <div className={styles.paginacao}>
            <button
              type="button"
              className={styles.pageArrow}
              onClick={() => setPagina((p) => Math.max(1, p - 1))}
              disabled={pagina === 1}
            >
              <svg viewBox="0 0 24 24"><polyline points="15 18 9 12 15 6" /></svg>
            </button>
            {Array.from({ length: paginacao.total_paginas }, (_, i) => i + 1).map((n) => (
              <button
                key={n}
                type="button"
                className={`${styles.pageNum} ${pagina === n ? styles.pageNumAtiva : ''}`}
                onClick={() => setPagina(n)}
              >
                {n}
              </button>
            ))}
            <button
              type="button"
              className={styles.pageArrow}
              onClick={() => setPagina((p) => Math.min(paginacao.total_paginas, p + 1))}
              disabled={pagina === paginacao.total_paginas}
            >
              <svg viewBox="0 0 24 24"><polyline points="9 18 15 12 9 6" /></svg>
            </button>
          </div>
        )}
      </main>
      <Footer />
    </div>
  )
}
