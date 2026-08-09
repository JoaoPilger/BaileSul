import { useState, useEffect } from 'react'
import { X, Eye, EyeOff } from 'lucide-react'
import styles from './AlterarSenhaModal.module.css'
import api from '../../services/api'
import { validatePassword, validateConfirmPassword } from '../../utils/authFormValidation'

export default function AlterarSenhaModal({ open, onClose, onSuccess }) {
  const [senhaAtual, setSenhaAtual] = useState('')
  const [novaSenha, setNovaSenha] = useState('')
  const [confirmarSenha, setConfirmarSenha] = useState('')

  const [mostrarAtual, setMostrarAtual] = useState(false)
  const [mostrarNova, setMostrarNova] = useState(false)
  const [mostrarConfirmar, setMostrarConfirmar] = useState(false)

  const [errors, setErrors] = useState({})
  const [erroGeral, setErroGeral] = useState('')
  const [salvando, setSalvando] = useState(false)

  const resetar = () => {
    setSenhaAtual('')
    setNovaSenha('')
    setConfirmarSenha('')
    setMostrarAtual(false)
    setMostrarNova(false)
    setMostrarConfirmar(false)
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

  const campo = (id, label, valor, setValor, chaveErro, mostrar, setMostrar, autoComplete, info) => (
    <div className={styles.field}>
      <label htmlFor={id}>{label}</label>
      <div className={styles.inputWrap}>
        <input
          id={id}
          type={mostrar ? 'text' : 'password'}
          autoComplete={autoComplete}
          value={valor}
          onChange={(e) => { setValor(e.target.value); setErrors((p) => ({ ...p, [chaveErro]: '' })) }}
          className={errors[chaveErro] ? `${styles.input} ${styles.inputError}` : styles.input}
        />
        <button
          type="button"
          className={styles.toggle}
          onClick={() => setMostrar((v) => !v)}
          aria-label={mostrar ? 'Ocultar senha' : 'Mostrar senha'}
        >
          {mostrar ? <EyeOff size={18} /> : <Eye size={18} />}
        </button>
      </div>
      {info && <p className={styles.info}>{info}</p>}
      {errors[chaveErro] && <p className={styles.hint}>{errors[chaveErro]}</p>}
    </div>
  )

  return (
    <div className={styles.overlay} role="presentation" onClick={fechar}>
      <div
        className={styles.modal}
        role="dialog"
        aria-modal="true"
        aria-labelledby="alterar-senha-titulo"
        onClick={(e) => e.stopPropagation()}
      >
        <div className={styles.header}>
          <h2 id="alterar-senha-titulo" className={styles.title}>Alterar senha</h2>
          <button type="button" className={styles.close} onClick={fechar} aria-label="Fechar">
            <X size={20} />
          </button>
        </div>

        <form className={styles.form} onSubmit={handleSubmit}>
          {campo('senha-atual', 'Senha atual', senhaAtual, setSenhaAtual, 'senhaAtual', mostrarAtual, setMostrarAtual, 'current-password')}
          {campo('nova-senha', 'Nova senha', novaSenha, setNovaSenha, 'novaSenha', mostrarNova, setMostrarNova, 'new-password', 'A senha deve ter ao menos 8 caracteres, incluindo letras e números.')}
          {campo('confirmar-senha', 'Confirmar nova senha', confirmarSenha, setConfirmarSenha, 'confirmarSenha', mostrarConfirmar, setMostrarConfirmar, 'new-password')}

          {erroGeral && <p className={styles.erroGeral}>{erroGeral}</p>}

          <div className={styles.actions}>
            <button type="button" className={styles.btnCancelar} onClick={fechar} disabled={salvando}>
              Cancelar
            </button>
            <button type="submit" className={styles.btnSalvar} disabled={salvando}>
              {salvando ? 'Salvando...' : 'Salvar'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
