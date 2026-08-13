import { useEffect, useRef } from 'react'
import { BellOff } from 'lucide-react'
import styles from './NotificacoesPanel.module.css'

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

export default function NotificacoesPanel({
  open, notificacoes, loading, erro, onClose, onMarcarLida, onMarcarTodas, anchorRef,
}) {
  const panelRef = useRef(null)

  useEffect(() => {
    if (!open) return
    const onClickFora = (e) => {
      if (panelRef.current?.contains(e.target)) return
      if (anchorRef?.current?.contains(e.target)) return
      onClose()
    }
    const onEsc = (e) => { if (e.key === 'Escape') onClose() }
    document.addEventListener('mousedown', onClickFora)
    document.addEventListener('keydown', onEsc)
    return () => {
      document.removeEventListener('mousedown', onClickFora)
      document.removeEventListener('keydown', onEsc)
    }
  }, [open, onClose, anchorRef])

  if (!open) return null

  const naoLidas = notificacoes.some((n) => !n.lida)

  return (
    <div ref={panelRef} className={styles.panel} role="dialog" aria-label="Notificações">
      <div className={styles.header}>
        <span className={styles.title}>Notificações</span>
        {naoLidas && (
          <button type="button" className={styles.marcarTodas} onClick={onMarcarTodas}>
            Marcar todas como lidas
          </button>
        )}
      </div>

      <div className={styles.lista}>
        {loading && <div className={styles.estado}>Carregando…</div>}

        {!loading && erro && <div className={styles.estado}>{erro}</div>}

        {!loading && !erro && notificacoes.length === 0 && (
          <div className={styles.vazio}>
            <BellOff size={22} strokeWidth={1.6} aria-hidden />
            <span>Nenhuma notificação por aqui.</span>
          </div>
        )}

        {!loading && !erro && notificacoes.map((n) => (
          <button
            key={n.id}
            type="button"
            className={`${styles.item} ${n.lida ? '' : styles['item--naoLida']}`}
            onClick={() => !n.lida && onMarcarLida(n.id)}
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
    </div>
  )
}
