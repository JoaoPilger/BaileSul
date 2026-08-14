import { useState, useEffect } from 'react'
import { X } from 'lucide-react'
import styles from './AlterarSenhaModal.module.css'
import api from '../../services/api'

export default function EditarPerfilPessoalModal({ open, onClose, onSuccess }) {
  const [nome, setNome] = useState('')
  const [email, setEmail] = useState('')

  const [errors, setErrors] = useState({})
  const [erroGeral, setErroGeral] = useState('')
  const [carregando, setCarregando] = useState(false)
  const [salvando, setSalvando] = useState(false)

  useEffect(() => {
    if (!open) return

    let ativo = true
    // eslint-disable-next-line react-hooks/set-state-in-effect -- inicia o carregamento ao abrir o modal
    setCarregando(true)
    setErroGeral('')

    api.get('/auth/me/perfil')
      .then(({ data }) => {
        if (!ativo) return
        setNome(data.nome || '')
        setEmail(data.email || '')
      })
      .catch(() => {
        if (ativo) setErroGeral('Não foi possível carregar seu perfil. Tente novamente.')
      })
      .finally(() => { if (ativo) setCarregando(false) })

    return () => { ativo = false }
  }, [open])

  const resetar = () => {
    setNome('')
    setEmail('')
    setErrors({})
    setErroGeral('')
    setSalvando(false)
  }

  const fechar = () => {
    resetar()
    onClose()
  }

  useEffect(() => {
    if (!open) return
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') fechar()
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [open])

  if (!open) return null

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErroGeral('')

    const novosErros = {}
    if (!nome.trim()) novosErros.nome = 'Informe seu nome.'

    if (Object.keys(novosErros).length > 0) {
      setErrors(novosErros)
      return
    }

    setSalvando(true)
    try {
      await api.put('/auth/me/perfil', { nome: nome.trim() })
      onSuccess()
    } catch (err) {
      setErroGeral(err.response?.data?.error || 'Não foi possível salvar o perfil. Tente novamente.')
    } finally {
      setSalvando(false)
    }
  }

  return (
    <div className={styles.overlay} role="presentation" onClick={fechar}>
      <div
        className={styles.modal}
        role="dialog"
        aria-modal="true"
        aria-labelledby="editar-perfil-pessoal-titulo"
        onClick={(e) => e.stopPropagation()}
      >
        <div className={styles.header}>
          <h2 id="editar-perfil-pessoal-titulo" className={styles.title}>Editar perfil</h2>
          <button type="button" className={styles.close} onClick={fechar} aria-label="Fechar">
            <X size={20} />
          </button>
        </div>

        <form className={styles.form} onSubmit={handleSubmit}>
          <div className={styles.field}>
            <label htmlFor="perfil-nome">Nome *</label>
            <div className={styles.inputWrap}>
              <input
                id="perfil-nome"
                type="text"
                value={nome}
                disabled={carregando}
                onChange={(e) => { setNome(e.target.value); setErrors((p) => ({ ...p, nome: '' })) }}
                className={errors.nome ? `${styles.input} ${styles.inputError}` : styles.input}
              />
            </div>
            {errors.nome && <p className={styles.hint}>{errors.nome}</p>}
          </div>

          <div className={styles.field}>
            <label htmlFor="perfil-email">E-mail</label>
            <div className={styles.inputWrap}>
              <input
                id="perfil-email"
                type="email"
                value={email}
                disabled
                className={styles.input}
              />
            </div>
          </div>

          {erroGeral && <p className={styles.erroGeral}>{erroGeral}</p>}

          <div className={styles.actions}>
            <button type="button" className={styles.btnCancelar} onClick={fechar} disabled={salvando}>
              Cancelar
            </button>
            <button type="submit" className={styles.btnSalvar} disabled={salvando || carregando}>
              {salvando ? 'Salvando...' : 'Salvar'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
