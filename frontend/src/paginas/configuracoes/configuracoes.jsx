import React, { useState } from 'react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import shared from '../../styles/shared.module.css'
import styles from './configuracoes.module.css'
import { Music, Calendar, Lock, LogOut } from 'lucide-react'
import Snackbar from '../../components/ui/Snackbar'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'

export default function Configuracoes() {
  const { usuario, logout } = useAuth()
  const navigate = useNavigate()
  const [snackOpen, setSnackOpen] = useState(false)
  const [snackMsg, setSnackMsg] = useState('')

  return (
    <>
      <Header />
      <div className={`${shared.container} ${styles.page}`}>
        <h1 className={styles.title}>Configurações</h1>
        <p className={styles.subtitle}>Gerencie o perfil e as configurações da sua conta.</p>

        <div className={styles.grid}>
          <div className={styles.infoCard}>
            <strong>Conta {usuario?.tipo}</strong>
            <div style={{ marginTop: 8, color: 'var(--muted)' }}>{usuario?.email}</div>
            <div style={{ marginTop: 8 }}><a href="#" style={{ color: 'var(--accent)' }}>Sessão ativa</a></div>
          </div>

          <div className={styles.tilesGrid}>
            <button type="button" onClick={() => { setSnackMsg('Perfil da banda em breve.'); setSnackOpen(true); }} className={styles.tileButton}>
              <div className={styles.tileContent}>
                <Music className={styles.icon} size={18} />
                <div className={styles.textBlock}>
                  <div className={styles.tileTitle}>Perfil da banda</div>
                  <div className={styles.tileSubtitle}>Nome artístico, estilo e descrição</div>
                </div>
              </div>
              <div className={styles.arrow}>›</div>
            </button>

            <button type="button" onClick={() => { setSnackMsg('Agenda em breve.'); setSnackOpen(true); }} className={styles.tileButton}>
              <div className={styles.tileContent}>
                <Calendar className={styles.icon} size={18} />
                <div className={styles.textBlock}>
                  <div className={styles.tileTitle}>Agenda</div>
                  <div className={styles.tileSubtitle}>Datas e compromissos</div>
                </div>
              </div>
              <div className={styles.arrow}>›</div>
            </button>

            <button type="button" onClick={() => { setSnackMsg('Alterar senha em breve.'); setSnackOpen(true); }} className={styles.tileButton}>
              <div className={styles.tileContent}>
                <Lock className={styles.icon} size={18} />
                <div className={styles.textBlock}>
                  <div className={styles.tileTitle}>Alterar senha</div>
                  <div className={styles.tileSubtitle}>Atualize sua senha de acesso</div>
                </div>
              </div>
              <div className={styles.arrow}>›</div>
            </button>
          </div>

          <div className={styles.logoutWrap}>
            <button onClick={async () => { await logout(); navigate('/'); }} className={`${shared.btn} ${styles.logoutBtn}`}>
              <LogOut /> Sair da conta
            </button>
          </div>
        </div>
      </div>
      <Footer />
      <Snackbar message={snackMsg} open={snackOpen} onClose={() => setSnackOpen(false)} />
    </>
  )
}
