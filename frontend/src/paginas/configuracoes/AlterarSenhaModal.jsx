import { useState } from 'react'
import { X } from 'lucide-react'
import styles from './configuracoes.module.css'
import api from '../../services/api'
import { validatePassword, validateConfirmPassword } from '../../utils/authFormValidation'

export default function AlterarSenhaModal({ open, onClose, onSuccess }) {
  const [senhaAtual, setSenhaAtual] = useState('')
  const [novaSenha, setNovaSenha] = useState('')
  const [confirmarSenha, setConfirmarSenha] = useState('')
  const [errors, setErrors] = useState({})
  const [erroGeral, setErroGeral] = useState('')
  const [salvando, setSalvando] = useState(false)

  if (!open) return null

  const resetar = () => {
    setSenhaAtual('')
    setNovaSenha('')
    setConfirmarSenha('')
    setErrors({})
    setErroGeral('')
    setSalvando(false)
  }

  const fechar = () => {
    resetar()
    onClose()
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErroGeral('')

    const novosErros = {}
    if (!senhaAtual) novosErros.senhaAtual = 'Informe a senha atual.'
    const novaSenhaErro = validatePassword(novaSenha)
    if (novaSenhaErro) novosErros.novaSenha = novaSenhaErro
    const confirmarErro = validateConfirmPassword(confirmarSenha, novaSenha)
    if (confirmarErro) novosErros.confirmarSenha = confirmarErro

    if (Object.keys(novosErros).length > 0) {
      setErrors(novosErros)
      return
    }

    setSalvando(true)
    try {
      await api.put('/auth/senha', { senha_atual: senhaAtual, nova_senha: novaSenha })
      resetar()
      onSuccess()
    } catch (err) {
      if (err.response?.status === 401) {
        setErrors({ senhaAtual: 'Senha atual incorreta.' })
      } else {
        setErroGeral(err.response?.data?.error || 'Não foi possível alterar a senha. Tente novamente.')
      }
    } finally {
      setSalvando(false)
    }
  }

  return (
    <div className={styles.modalOverlay} role="presentation" onClick={fechar}>
      <div
        className={styles.modalCard}
        role="dialog"
        aria-modal="true"
        aria-labelledby="alterar-senha-titulo"
        onClick={(e) => e.stopPropagation()}
      >
        <div className={styles.modalHeader}>
          <h2 id="alterar-senha-titulo" className={styles.modalTitle}>Alterar senha</h2>
          <button type="button" className={styles.modalClose} onClick={fechar} aria-label="Fechar">
            <X size={20} />
          </button>
        </div>

        <form className={styles.modalForm} onSubmit={handleSubmit}>
          <div className={styles.modalField}>
            <label htmlFor="senha-atual">Senha atual</label>
            <input
              id="senha-atual"
              type="password"
              autoComplete="current-password"
              value={senhaAtual}
              onChange={(e) => { setSenhaAtual(e.target.value); setErrors((p) => ({ ...p, senhaAtual: '' })) }}
              className={errors.senhaAtual ? styles.modalInputError : styles.modalInput}
            />
            {errors.senhaAtual && <p className={styles.modalFieldHint}>{errors.senhaAtual}</p>}
          </div>

          <div className={styles.modalField}>
            <label htmlFor="nova-senha">Nova senha</label>
            <input
              id="nova-senha"
              type="password"
              autoComplete="new-password"
              value={novaSenha}
              onChange={(e) => { setNovaSenha(e.target.value); setErrors((p) => ({ ...p, novaSenha: '' })) }}
              className={errors.novaSenha ? styles.modalInputError : styles.modalInput}
            />
            {errors.novaSenha && <p className={styles.modalFieldHint}>{errors.novaSenha}</p>}
          </div>

          <div className={styles.modalField}>
            <label htmlFor="confirmar-senha">Confirmar nova senha</label>
            <input
              id="confirmar-senha"
              type="password"
              autoComplete="new-password"
              value={confirmarSenha}
              onChange={(e) => { setConfirmarSenha(e.target.value); setErrors((p) => ({ ...p, confirmarSenha: '' })) }}
              className={errors.confirmarSenha ? styles.modalInputError : styles.modalInput}
            />
            {errors.confirmarSenha && <p className={styles.modalFieldHint}>{errors.confirmarSenha}</p>}
          </div>

          {erroGeral && <p className={styles.modalErroGeral}>{erroGeral}</p>}

          <button type="submit" className={styles.modalSubmit} disabled={salvando}>
            {salvando ? 'Salvando...' : 'Salvar'}
          </button>
        </form>
      </div>
    </div>
  )
}
