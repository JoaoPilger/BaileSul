import { useEffect } from 'react'
import { X, Building2, Phone } from 'lucide-react'
import styles from './ComunidadesVinculadasModal.module.css'

function formatarWhatsapp(numero) {
  const digitos = String(numero || '').replace(/\D/g, '')
  if (!digitos) return null
  const semDdi = digitos.startsWith('55') && digitos.length > 11 ? digitos.slice(2) : digitos
  if (semDdi.length === 11) return `(${semDdi.slice(0, 2)}) ${semDdi.slice(2, 7)}-${semDdi.slice(7)}`
  if (semDdi.length === 10) return `(${semDdi.slice(0, 2)}) ${semDdi.slice(2, 6)}-${semDdi.slice(6)}`
  return digitos
}

export default function ComunidadesVinculadasModal({ open, onClose, comunidades = [] }) {
  useEffect(() => {
    if (!open) return
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [open, onClose])

  if (!open) return null

  return (
    <div className={styles.overlay} role="presentation" onClick={onClose}>
      <div
        className={styles.modal}
        role="dialog"
        aria-modal="true"
        aria-labelledby="comunidades-vinculadas-titulo"
        onClick={(e) => e.stopPropagation()}
      >
        <div className={styles.header}>
          <h2 id="comunidades-vinculadas-titulo" className={styles.title}>Comunidades vinculadas</h2>
          <button type="button" className={styles.close} onClick={onClose} aria-label="Fechar">
            <X size={20} />
          </button>
        </div>

        <div className={styles.body}>
          <p className={styles.subtitle}>
            CTGs que você representa como vendedor. Para deixar de representar uma comunidade,
            peça para ela remover seu vínculo.
          </p>

          {comunidades.length === 0 ? (
            <div className={styles.vazio}>Você ainda não está vinculado a nenhuma comunidade.</div>
          ) : (
            <ul className={styles.lista}>
              {comunidades.map((c) => {
                const whatsapp = formatarWhatsapp(c.whatsapp)
                return (
                  <li key={c.vendedor_id ?? c.comunidade_id} className={styles.item}>
                    <div className={styles.itemIcon}>
                      <Building2 size={20} strokeWidth={2} />
                    </div>
                    <div className={styles.itemInfo}>
                      <span className={styles.itemNome}>
                        {c.comunidade_nome || 'Comunidade sem nome'}
                      </span>
                      {whatsapp && (
                        <span className={styles.itemMeta}>
                          <Phone size={13} strokeWidth={2} />
                          {whatsapp}
                        </span>
                      )}
                    </div>
                  </li>
                )
              })}
            </ul>
          )}
        </div>
      </div>
    </div>
  )
}
