import { useEffect, useState, useRef } from 'react'
import { X, Upload, Trash2, Image as ImageIcon } from 'lucide-react'
import styles from '../configuracoes/configuracoes.module.css'
import editStyles from '../editar_perfil/editar_perfil.module.css'
import shared from '../../styles/shared.module.css'
import api from '../../services/api'
import { useAuth } from '../../contexts/AuthContext'

function normalizarMedia(url) {
  return url || ''
}

export default function GerenciadorMidiasModal({ open, onClose, onSuccess }) {
  const { usuario } = useAuth()
  const [midias, setMidias] = useState([])
  const [carregando, setCarregando] = useState(true)
  const [enviando, setEnviando] = useState(false)
  const [titulo, setTitulo] = useState('')
  const [erro, setErro] = useState('')
  const fileInputRef = useRef(null)

  const isBanda = usuario?.tipo === 'banda'

  const carregarMidias = async () => {
    if (!usuario?.id) return
    setCarregando(true)
    try {
      const endpoint = isBanda ? `/bandas/${usuario.id}` : `/comunidades/${usuario.id}`
      const { data } = await api.get(endpoint)
      setMidias((data.midias || []).map((m) => ({ ...m, url: normalizarMedia(m.url) })))
    } catch (err) {
      console.error('Erro ao carregar mídias:', err)
      setErro('Não foi possível carregar as mídias.')
    } finally {
      setCarregando(false)
    }
  }

  useEffect(() => {
    if (open) {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- reseta o formulário ao abrir o modal
      setErro('')
      setTitulo('')
      carregarMidias()
    }
  }, [open, usuario?.id])

  if (!open) return null

  const handleUpload = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return

    setErro('')
    setEnviando(true)
    const formData = new FormData()
    formData.append('arquivo', file)
    if (titulo.trim()) {
      formData.append('titulo', titulo.trim())
    }

    try {
      const endpoint = isBanda ? '/bandas/me/midias' : '/comunidades/me/midias'
      const { data } = await api.post(endpoint, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      setMidias((prev) => [...prev, { ...data, url: normalizarMedia(data.url) }])
      setTitulo('')
      if (onSuccess) onSuccess()
    } catch (err) {
      console.error('Erro ao enviar mídia:', err)
      setErro(err.response?.data?.error || 'Erro ao enviar mídia.')
    } finally {
      setEnviando(false)
      if (fileInputRef.current) fileInputRef.current.value = ''
    }
  }

  const handleRemover = async (midiaId) => {
    setErro('')
    try {
      const endpoint = isBanda ? `/bandas/me/midias/${midiaId}` : `/comunidades/me/midias/${midiaId}`
      await api.delete(endpoint)
      setMidias((prev) => prev.filter((m) => m.id !== midiaId))
      if (onSuccess) onSuccess()
    } catch (err) {
      console.error('Erro ao remover mídia:', err)
      setErro(err.response?.data?.error || 'Erro ao remover mídia.')
    }
  }

  return (
    <div className={styles.modalOverlay} role="presentation" onClick={onClose}>
      <div
        className={styles.modalCard}
        style={{ maxWidth: '640px' }}
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
      >
        <div className={styles.modalHeader}>
          <h2 className={styles.modalTitle} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <ImageIcon size={22} color="var(--accent)" /> Mídias da Vitrine
          </h2>
          <button type="button" className={styles.modalClose} onClick={onClose} aria-label="Fechar">
            <X size={20} />
          </button>
        </div>

        {erro && <p className={styles.modalErroGeral} style={{ marginBottom: '12px' }}>{erro}</p>}

        <div className={editStyles.mediaUploadBox} style={{ margin: '0 0 1rem 0' }}>
          <p style={{ fontWeight: 600, fontSize: '0.9rem', margin: 0 }}>
            Enviar nova foto ou vídeo
          </p>

          <input
            type="text"
            value={titulo}
            onChange={(e) => setTitulo(e.target.value)}
            placeholder="Legenda ou título (opcional)"
            className={editStyles.input}
            style={{ fontSize: '0.85rem', padding: '0.5rem 0.75rem' }}
          />

          <input
            type="file"
            ref={fileInputRef}
            onChange={handleUpload}
            accept="image/*,video/*"
            className={editStyles.hiddenInput}
          />

          <button
            type="button"
            className={`${shared.btn} ${shared.btnPrimary} ${shared.btnSm}`}
            onClick={() => fileInputRef.current?.click()}
            disabled={enviando}
          >
            <Upload size={16} /> {enviando ? 'Enviando...' : 'Selecionar Foto / Vídeo'}
          </button>
        </div>

        {carregando ? (
          <p style={{ textAlign: 'center', color: 'var(--muted)', padding: '1.5rem 0' }}>
            Carregando mídias...
          </p>
        ) : midias.length === 0 ? (
          <p style={{ textAlign: 'center', color: 'var(--muted)', padding: '1.5rem 0', fontSize: '0.9rem' }}>
            Nenhuma mídia cadastrada ainda.
          </p>
        ) : (
          <div className={editStyles.mediaGrid} style={{ maxHeight: '280px', overflowY: 'auto', paddingRight: '4px' }}>
            {midias.map((midia) => (
              <div key={midia.id} className={editStyles.mediaCard}>
                {midia.tipo === 'video' ? (
                  <video src={midia.url} className={editStyles.mediaVideo} controls />
                ) : (
                  <img src={midia.url} alt={midia.titulo || 'Mídia'} className={editStyles.mediaThumb} />
                )}
                <button
                  type="button"
                  className={editStyles.deleteMediaBtn}
                  onClick={() => handleRemover(midia.id)}
                  title="Remover Mídia"
                >
                  <Trash2 size={16} />
                </button>
                {midia.titulo && (
                  <div className={editStyles.mediaTitle} title={midia.titulo}>
                    {midia.titulo}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
