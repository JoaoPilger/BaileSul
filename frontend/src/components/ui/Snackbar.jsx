import { useEffect } from 'react'

export default function Snackbar({ message, open, onClose }) {
  useEffect(() => {
    if (!open) return
    const t = setTimeout(() => onClose(), 3000)
    return () => clearTimeout(t)
  }, [open, onClose])

  if (!open) return null

  return (
    <div style={{
      position: 'fixed',
      left: 0,
      right: 0,
      bottom: 0,
      display: 'flex',
      justifyContent: 'center',
      pointerEvents: 'none',
    }}>
      <div style={{
        margin: '12px',
        background: 'var(--overlay-dark)',
        color: 'var(--white)',
        padding: '14px 18px',
        borderRadius: 6,
        maxWidth: '100%',
        width: 'min(980px, calc(100% - 48px))',
        boxShadow: '0 6px 22px rgba(0,0,0,0.4)',
        pointerEvents: 'auto',
      }}>
        {message}
      </div>
    </div>
  )
}
