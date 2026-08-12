import { useEffect, useState } from 'react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import shared from '../../styles/shared.module.css'
import styles from './configuracoes.module.css'
import { Music, Lock, LogOut, Building2 } from 'lucide-react'
import Snackbar from '../../components/ui/Snackbar'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import api from '../../services/api'
import AlterarSenhaModal from './AlterarSenhaModal'
import EditarPerfilPessoalModal from './EditarPerfilPessoalModal'

export default function Configuracoes() {
  const { usuario, logout } = useAuth()
  const navigate = useNavigate()
  const [snackOpen, setSnackOpen] = useState(false)
  const [snackMsg, setSnackMsg] = useState('')
  const [comunidadesVinculadas, setComunidadesVinculadas] = useState([])
  const [, setCarregandoVendedor] = useState(usuario?.tipo === 'pessoal')
  const [senhaModalOpen, setSenhaModalOpen] = useState(false)
  const [perfilPessoalModalOpen, setPerfilPessoalModalOpen] = useState(false)

  useEffect(() => {
    if (usuario?.tipo !== 'pessoal') return

    let ativo = true

    api.get('/vendedores/me')
      .then(({ data }) => { if (ativo) setComunidadesVinculadas(data ?? []) })
      .catch(() => { if (ativo) setComunidadesVinculadas([]) })
      .finally(() => { if (ativo) setCarregandoVendedor(false) })

    return () => { ativo = false }
  }, [usuario?.tipo])

  const showEmBreve = (msg) => { setSnackMsg(msg); setSnackOpen(true) }

  const isVendedor = usuario?.tipo === 'pessoal' && comunidadesVinculadas.length > 0

  const getTiles = () => {
    // Vendedor: extensão de "pessoal", mantém Perfil + card especial + senha
    if (usuario?.tipo === 'pessoal' && isVendedor) {
      return [
        {
          key: 'perfil-pessoal',
          icon: Music,
          title: 'Perfil',
          subtitle: 'Nome, email e senha',
          onClick: () => setPerfilPessoalModalOpen(true),
        },
        {
          key: 'comunidades-vinculadas',
          icon: Building2,
          title: 'Comunidades vinculadas',
          subtitle: 'CTGs que você representa como vendedor',
          onClick: () => showEmBreve('Comunidades vinculadas em breve.'),
        },
        {
          key: 'senha',
          icon: Lock,
          title: 'Alterar senha',
          subtitle: 'Atualize sua senha de acesso',
          onClick: () => setSenhaModalOpen(true),
        },
      ]
    }

    if (usuario?.tipo === 'comunidade') {
      return [
        {
          key: 'perfil-comunidade',
          icon: Music,
          title: 'Perfil da Comunidade',
          subtitle: 'Editar dados, foto de perfil e galeria de mídias',
          onClick: () => navigate('/editar-perfil'),
        },
        {
          key: 'senha',
          icon: Lock,
          title: 'Alterar senha',
          subtitle: 'Atualize sua senha de acesso',
          onClick: () => setSenhaModalOpen(true),
        },
      ]
    }

    if (usuario?.tipo === 'pessoal') {
      return [
        {
          key: 'perfil-pessoal',
          icon: Music,
          title: 'Perfil',
          subtitle: 'Nome, email e senha',
          onClick: () => setPerfilPessoalModalOpen(true),
        },
        {
          key: 'senha',
          icon: Lock,
          title: 'Alterar senha',
          subtitle: 'Atualize sua senha de acesso',
          onClick: () => setSenhaModalOpen(true),
        },
      ]
    }

    // banda (padrão): mantém igual
    return [
      {
        key: 'perfil-banda',
        icon: Music,
        title: 'Perfil da banda',
        subtitle: 'Nome artístico, estilo, foto e mídias',
        onClick: () => navigate('/editar-perfil'),
      },
      {
        key: 'senha',
        icon: Lock,
        title: 'Alterar senha',
        subtitle: 'Atualize sua senha de acesso',
        onClick: () => setSenhaModalOpen(true),
      },
    ]
  }

  const tiles = getTiles()

  return (
    <>
      <Header />
      <div className={`${shared.container} ${styles.page}`}>
        <div className={styles.wrapper}>
          <h1 className={styles.title}>Configurações</h1>
          <p className={styles.subtitle}>Gerencie o perfil e as configurações da sua conta.</p>

          <div className={styles.grid}>
            <div className={styles.infoCard}>
              <strong>Conta {usuario?.tipo}</strong>
              <div style={{ marginTop: 8, color: 'var(--muted)' }}>{usuario?.email}</div>
              <div style={{ marginTop: 8 }}><a href="#" style={{ color: 'var(--accent)' }}>Sessão ativa</a></div>
            </div>

            <div className={styles.tilesGrid}>
              {tiles.map(({ key, icon: Icon, title, subtitle, onClick }) => (
                <button key={key} type="button" onClick={onClick} className={styles.tileButton}>
                  <div className={styles.tileContent}>
                    <Icon className={styles.icon} size={24} />
                    <div className={styles.textBlock}>
                      <div className={styles.tileTitle}>{title}</div>
                      <div className={styles.tileSubtitle}>{subtitle}</div>
                    </div>
                  </div>
                </button>
              ))}
            </div>

            <div className={styles.logoutWrap}>
              <button onClick={async () => { await logout(); navigate('/'); }} className={`${shared.btn} ${styles.logoutBtn}`}>
                <LogOut /> Sair da conta
              </button>
            </div>
          </div>
        </div>
      </div>
      <Footer />
      <Snackbar message={snackMsg} open={snackOpen} onClose={() => setSnackOpen(false)} />
      <AlterarSenhaModal
        open={senhaModalOpen}
        onClose={() => setSenhaModalOpen(false)}
        onSuccess={() => {
          setSenhaModalOpen(false)
          setSnackMsg('Senha alterada com sucesso!')
          setSnackOpen(true)
        }}
      />
      <EditarPerfilPessoalModal
        open={perfilPessoalModalOpen}
        onClose={() => setPerfilPessoalModalOpen(false)}
        onSuccess={() => {
          setPerfilPessoalModalOpen(false)
          setSnackMsg('Perfil atualizado com sucesso!')
          setSnackOpen(true)
        }}
      />
    </>
  )
}