import { useEffect, useState, useRef } from 'react'
import { Link } from 'react-router-dom'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import shared from '../../styles/shared.module.css'
import styles from './editar_perfil.module.css'
import Snackbar from '../../components/ui/Snackbar'
import { useAuth } from '../../contexts/AuthContext'
import api from '../../services/api'
import { formatPhone, validatePhone, validateName } from '../../utils/authFormValidation'
import { formatCep } from '../../utils/inputMasks'
import {
  Camera,
  Image as ImageIcon,
  Trash2,
  Save,
  ArrowLeft,
  Upload,
  Building2,
  Music,
} from 'lucide-react'

function FieldHint({ message }) {
  if (!message) return null
  return <p className={styles.errorHint}>{message}</p>
}

function normalizarMedia(url) {
  return url || ''
}

export default function EditarPerfil() {
  const { usuario } = useAuth()

  const [carregando, setCarregando] = useState(true)
  const [salvando, setSalvando] = useState(false)
  const [enviandoFoto, setEnviandoFoto] = useState(false)
  const [enviandoMidia, setEnviandoMidia] = useState(false)
  
  const [snackOpen, setSnackOpen] = useState(false)
  const [snackMsg, setSnackMsg] = useState('')

  // Referência para os inputs de arquivo
  const fotoInputRef = useRef(null)
  const midiaInputRef = useRef(null)

  // Estado do perfil (unificado)
  const [perfil, setPerfil] = useState({
    nome: '',
    estilo_musical: '',
    descricao: '',
    whatsapp: '',
    video_url: '',
    cep: '',
    endereco: '',
    cidade: '',
    estado: '',
    latitude: '',
    longitude: '',
    foto_perfil_url: '',
  })

  // Lista de mídias da galeria
  const [midias, setMidias] = useState([])
  const [tituloNovaMidia, setTituloNovaMidia] = useState('')
  const [errors, setErrors] = useState({})
  const [cepCarregando, setCepCarregando] = useState(false)

  const isBanda = usuario?.tipo === 'banda'
  const isComunidade = usuario?.tipo === 'comunidade'

  const showMsg = (msg) => {
    setSnackMsg(msg)
    setSnackOpen(true)
  }

  // Carregar dados iniciais do perfil
  const carregarPerfil = async () => {
    if (!usuario?.id || (!isBanda && !isComunidade)) {
      setCarregando(false)
      return
    }

    try {
      setCarregando(true)
      const endpoint = isBanda ? `/bandas/${usuario.id}` : `/comunidades/${usuario.id}`
      const { data } = await api.get(endpoint)

      if (isBanda) {
        setPerfil({
          nome: data.nome_artistico || data.title || '',
          estilo_musical: data.estilo_musical || data.style || '',
          descricao: data.descricao || data.description || '',
          whatsapp: data.whatsapp || '',
          video_url: data.video_url || '',
          foto_perfil_url: normalizarMedia(data.foto_perfil_url),
        })
      } else {
        setPerfil({
          nome: data.nome_entidade || data.nome || '',
          descricao: data.descricao || data.description || '',
          whatsapp: data.whatsapp || '',
          cep: data.cep || '',
          endereco: data.endereco || '',
          cidade: data.cidade || '',
          estado: data.estado || '',
          latitude: data.latitude || '',
          longitude: data.longitude || '',
          foto_perfil_url: normalizarMedia(data.foto_perfil_url),
        })
      }

      setMidias((data.midias || []).map((m) => ({ ...m, url: normalizarMedia(m.url) })))
    } catch (err) {
      console.error('Erro ao carregar perfil:', err)
      showMsg('Não foi possível carregar as informações do perfil.')
    } finally {
      setCarregando(false)
    }
  }

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- carrega o perfil ao montar/trocar de usuário
    carregarPerfil()
  }, [usuario?.id, usuario?.tipo])

  // Tratar alteração dos campos de texto
  const handleChange = (e) => {
    const { name, value } = e.target
    let next = value
    if (name === 'whatsapp') next = formatPhone(value)
    if (name === 'cep') next = formatCep(value)
    if (name === 'estado') next = value.toUpperCase().slice(0, 2)
    setPerfil((prev) => ({ ...prev, [name]: next }))
    setErrors((prev) => ({ ...prev, [name]: '' }))
  }

  // Busca automática de endereço a partir do CEP (ViaCEP)
  const buscarCep = async () => {
    const cepDigits = perfil.cep.replace(/\D/g, '')
    if (cepDigits.length !== 8) return

    setCepCarregando(true)
    try {
      const res = await fetch(`https://viacep.com.br/ws/${cepDigits}/json/`)
      const data = await res.json().catch(() => null)
      if (data && !data.erro) {
        const ruaBairro = [data.logradouro, data.bairro].filter(Boolean).join(', ')
        setPerfil((prev) => ({
          ...prev,
          cidade: data.localidade || prev.cidade,
          estado: data.uf || prev.estado,
          endereco: ruaBairro || prev.endereco,
        }))
      }
    } catch {
      // Falha silenciosa: usuário pode preencher manualmente
    } finally {
      setCepCarregando(false)
    }
  }

  // Validação imediata ao sair do campo
  const handleBlur = (e) => {
    const { name, value } = e.target
    let msg = ''
    if (name === 'nome') msg = validateName(value, isBanda ? 'o nome artístico' : 'o nome da entidade', true, 2)
    if (name === 'whatsapp' && value.trim()) msg = validatePhone(value, false)
    setErrors((prev) => ({ ...prev, [name]: msg }))
  }

  // Enviar alteração de foto de perfil
  const handleFotoChange = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return

    const formData = new FormData()
    formData.append('arquivo', file)

    try {
      setEnviandoFoto(true)
      const endpoint = isBanda ? '/bandas/me/foto-perfil' : '/comunidades/me/foto-perfil'
      const { data } = await api.post(endpoint, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })

      if (data.foto_perfil_url) {
        setPerfil((prev) => ({ ...prev, foto_perfil_url: normalizarMedia(data.foto_perfil_url) }))
        showMsg('Foto de perfil atualizada com sucesso!')
      }
    } catch (err) {
      console.error('Erro ao enviar foto de perfil:', err)
      showMsg(err.response?.data?.error || 'Erro ao enviar foto de perfil.')
    } finally {
      setEnviandoFoto(false)
    }
  }

  // Enviar nova mídia (foto ou vídeo) para a galeria
  const handleAddMidia = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return

    const formData = new FormData()
    formData.append('arquivo', file)
    if (tituloNovaMidia.trim()) {
      formData.append('titulo', tituloNovaMidia.trim())
    }

    try {
      setEnviandoMidia(true)
      const endpoint = isBanda ? '/bandas/me/midias' : '/comunidades/me/midias'
      const { data } = await api.post(endpoint, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })

      setMidias((prev) => [...prev, { ...data, url: normalizarMedia(data.url) }])
      setTituloNovaMidia('')
      showMsg('Mídia adicionada com sucesso!')
    } catch (err) {
      console.error('Erro ao adicionar mídia:', err)
      showMsg(err.response?.data?.error || 'Erro ao enviar mídia.')
    } finally {
      setEnviandoMidia(false)
      if (midiaInputRef.current) midiaInputRef.current.value = ''
    }
  }

  // Remover mídia da galeria
  const handleRemoveMidia = async (midiaId) => {
    if (!window.confirm('Deseja realmente remover esta mídia?')) return

    try {
      const endpoint = isBanda ? `/bandas/me/midias/${midiaId}` : `/comunidades/me/midias/${midiaId}`
      await api.delete(endpoint)
      setMidias((prev) => prev.filter((m) => m.id !== midiaId))
      showMsg('Mídia removida com sucesso.')
    } catch (err) {
      console.error('Erro ao remover mídia:', err)
      showMsg(err.response?.data?.error || 'Erro ao remover mídia.')
    }
  }

  // Salvar formulário principal do perfil
  const handleSubmit = async (e) => {
    e.preventDefault()
    const nomeErro = validateName(perfil.nome, isBanda ? 'o nome artístico' : 'o nome da entidade', true, 2)
    const whatsappErro = perfil.whatsapp.trim() ? validatePhone(perfil.whatsapp, false) : ''
    if (nomeErro || whatsappErro) {
      setErrors({ nome: nomeErro, whatsapp: whatsappErro })
      return
    }

    setSalvando(true)

    try {
      if (isBanda) {
        await api.put('/bandas/me/perfil', {
          nome_artistico: perfil.nome,
          estilo_musical: perfil.estilo_musical,
          descricao: perfil.descricao,
          whatsapp: perfil.whatsapp,
          video_url: perfil.video_url,
        })
      } else if (isComunidade) {
        await api.put('/comunidades/me/perfil', {
          nome_entidade: perfil.nome,
          descricao: perfil.descricao,
          whatsapp: perfil.whatsapp,
          cep: perfil.cep,
          endereco: perfil.endereco,
          cidade: perfil.cidade,
          estado: perfil.estado,
          latitude: perfil.latitude ? parseFloat(perfil.latitude) : undefined,
          longitude: perfil.longitude ? parseFloat(perfil.longitude) : undefined,
        })
      }

      showMsg('Perfil atualizado com sucesso!')
    } catch (err) {
      console.error('Erro ao atualizar perfil:', err)
      showMsg(err.response?.data?.error || 'Erro ao salvar alterações no perfil.')
    } finally {
      setSalvando(false)
    }
  }

  if (!isBanda && !isComunidade) {
    return (
      <>
        <Header />
        <div className={`${shared.container} ${styles.page}`}>
          <div className={styles.wrapper}>
            <p>Você precisa estar logado como Banda ou Comunidade para acessar esta página.</p>
            <Link to="/login" className={`${shared.btn} ${shared.btnPrimary}`} style={{ marginTop: '1rem' }}>
              Ir para o Login
            </Link>
          </div>
        </div>
        <Footer />
      </>
    )
  }

  return (
    <>
      <Header />
      <div className={`${shared.container} ${styles.page}`}>
        <div className={styles.wrapper}>
          {/* Cabeçalho da página */}
          <div className={styles.headerRow}>
            <div>
              <h1 className={styles.title}>
                Editar Perfil da {isBanda ? 'Banda' : 'Comunidade'}
              </h1>
              <p className={styles.subtitle}>
                Atualize as informações públicas da sua vitrine e sua galeria de mídias.
              </p>
            </div>
            <Link to="/configuracoes" className={`${shared.btn} ${shared.btnOutline}`}>
              <ArrowLeft size={18} /> Voltar para Configurações
            </Link>
          </div>

          {carregando ? (
            <div className={styles.card}>
              <p style={{ color: 'var(--muted)', textAlign: 'center' }}>Carregando dados do perfil...</p>
            </div>
          ) : (
            <form onSubmit={handleSubmit}>
              {/* Card de Foto de Perfil */}
              <div className={styles.card}>
                <div className={styles.cardTitle}>
                  <Camera size={22} color="var(--accent)" /> Foto de Perfil (Avatar)
                </div>
                <div className={styles.avatarSection}>
                  {perfil.foto_perfil_url ? (
                    <img
                      src={perfil.foto_perfil_url}
                      alt="Avatar"
                      className={styles.avatarPreview}
                    />
                  ) : (
                    <div className={styles.avatarPlaceholder}>
                      {perfil.nome ? perfil.nome.charAt(0).toUpperCase() : '?'}
                    </div>
                  )}

                  <div className={styles.avatarActions}>
                    <input
                      type="file"
                      ref={fotoInputRef}
                      onChange={handleFotoChange}
                      accept="image/*"
                      className={styles.hiddenInput}
                    />
                    <button
                      type="button"
                      className={`${shared.btn} ${shared.btnOutline}`}
                      onClick={() => fotoInputRef.current?.click()}
                      disabled={enviandoFoto}
                    >
                      <Upload size={16} /> {enviandoFoto ? 'Enviando foto...' : 'Alterar Foto'}
                    </button>
                    <span className={styles.hint}>
                      Formatos recomendados: JPG, PNG ou WEBP (Max 5MB).
                    </span>
                  </div>
                </div>
              </div>

              {/* Card de Informações Gerais */}
              <div className={styles.card}>
                <div className={styles.cardTitle}>
                  {isBanda ? <Music size={22} color="var(--accent)" /> : <Building2 size={22} color="var(--accent)" />}
                  Informações Gerais
                </div>

                <div className={styles.formGrid}>
                  {/* Nome */}
                  <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                    <label className={styles.label}>
                      {isBanda ? 'Nome Artístico da Banda' : 'Nome da Entidade / Comunidade'} *
                    </label>
                    <input
                      type="text"
                      name="nome"
                      value={perfil.nome}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      placeholder={isBanda ? 'Ex: Banda Sul Som' : 'Ex: CTG Lanceiros do Sul'}
                      className={errors.nome ? `${styles.input} ${styles.inputError}` : styles.input}
                      required
                    />
                    <FieldHint message={errors.nome} />
                  </div>

                  {/* Estilo Musical (Banda) */}
                  {isBanda && (
                    <div className={styles.fieldGroup}>
                      <label className={styles.label}>Estilo Musical</label>
                      <input
                        type="text"
                        name="estilo_musical"
                        value={perfil.estilo_musical}
                        onChange={handleChange}
                        placeholder="Ex: Gaúcha, Bandinha, Sertanejo"
                        className={styles.input}
                      />
                    </div>
                  )}

                  {/* WhatsApp */}
                  <div className={isBanda ? styles.fieldGroup : `${styles.fieldGroup} ${styles.fullWidth}`}>
                    <label className={styles.label}>WhatsApp de Contato</label>
                    <input
                      type="text"
                      name="whatsapp"
                      value={perfil.whatsapp}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      placeholder="(48) 9 0000-0000"
                      className={errors.whatsapp ? `${styles.input} ${styles.inputError}` : styles.input}
                    />
                    <span className={styles.hint}>Utilizado para direcionar mensagens dos clientes/contratantes.</span>
                    <FieldHint message={errors.whatsapp} />
                  </div>

                  {/* Endereço, Cidade e Estado (Comunidade) */}
                  {isComunidade && (
                    <>
                      <div className={styles.fieldGroup}>
                        <label className={styles.label}>CEP</label>
                        <input
                          type="text"
                          name="cep"
                          value={perfil.cep}
                          onChange={handleChange}
                          onBlur={buscarCep}
                          placeholder="00000-000"
                          className={styles.input}
                        />
                        <span className={styles.hint}>
                          {cepCarregando ? 'Buscando endereço...' : 'Preenche cidade e estado automaticamente.'}
                        </span>
                      </div>

                      <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                        <label className={styles.label}>Endereço Completo</label>
                        <input
                          type="text"
                          name="endereco"
                          value={perfil.endereco}
                          onChange={handleChange}
                          placeholder="Ex: Av. das Tradições, 1500 - Bairro Centro"
                          className={styles.input}
                        />
                      </div>

                      <div className={styles.fieldGroup}>
                        <label className={styles.label}>Cidade</label>
                        <input
                          type="text"
                          name="cidade"
                          value={perfil.cidade}
                          onChange={handleChange}
                          placeholder="Ex: Porto Alegre"
                          className={styles.input}
                        />
                      </div>

                      <div className={styles.fieldGroup}>
                        <label className={styles.label}>Estado (UF)</label>
                        <input
                          type="text"
                          name="estado"
                          value={perfil.estado}
                          onChange={handleChange}
                          placeholder="Ex: RS"
                          maxLength={2}
                          className={styles.input}
                        />
                      </div>
                    </>
                  )}

                  {/* Vídeo em Destaque URL (Banda) */}
                  {isBanda && (
                    <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                      <label className={styles.label}>Link do Vídeo em Destaque (YouTube/Vimeo)</label>
                      <input
                        type="url"
                        name="video_url"
                        value={perfil.video_url}
                        onChange={handleChange}
                        placeholder="Ex: https://www.youtube.com/watch?v=..."
                        className={styles.input}
                      />
                    </div>
                  )}

                  {/* Descrição */}
                  <div className={`${styles.fieldGroup} ${styles.fullWidth}`}>
                    <label className={styles.label}>Descrição / Biografia</label>
                    <textarea
                      name="descricao"
                      value={perfil.descricao}
                      onChange={handleChange}
                      placeholder={
                        isBanda
                          ? 'Conte a história da banda, anos de estrada, estrutura de som, repertório...'
                          : 'Conte sobre o CTG/Comunidade, capacidade de público, infraestrutura, tradição...'
                      }
                      className={styles.textarea}
                    />
                  </div>
                </div>
              </div>

              {/* Card de Mídias e Galeria */}
              <div className={styles.card}>
                <div className={styles.cardTitle}>
                  <ImageIcon size={22} color="var(--accent)" /> Galeria de Fotos e Vídeos
                </div>

                <div className={styles.mediaUploadBox}>
                  <p style={{ fontWeight: 600, fontSize: '0.95rem' }}>Adicionar foto ou vídeo à sua vitrine</p>
                  
                  <div style={{ width: '100%', maxWidth: '400px' }}>
                    <input
                      type="text"
                      value={tituloNovaMidia}
                      onChange={(e) => setTituloNovaMidia(e.target.value)}
                      placeholder="Título ou legenda da mídia (opcional)"
                      className={styles.input}
                      style={{ marginBottom: '0.75rem' }}
                    />
                  </div>

                  <input
                    type="file"
                    ref={midiaInputRef}
                    onChange={handleAddMidia}
                    accept="image/*,video/*"
                    className={styles.hiddenInput}
                  />

                  <button
                    type="button"
                    className={`${shared.btn} ${shared.btnPrimary}`}
                    onClick={() => midiaInputRef.current?.click()}
                    disabled={enviandoMidia}
                  >
                    <Upload size={18} /> {enviandoMidia ? 'Enviando mídia...' : 'Selecionar Arquivo'}
                  </button>
                </div>

                {/* Grid de mídias existentes */}
                {midias.length === 0 ? (
                  <p style={{ color: 'var(--muted)', textAlign: 'center', fontSize: '0.9rem' }}>
                    Nenhuma mídia adicionada à galeria ainda.
                  </p>
                ) : (
                  <div className={styles.mediaGrid}>
                    {midias.map((midia) => (
                      <div key={midia.id} className={styles.mediaCard}>
                        {midia.tipo === 'video' ? (
                          <video src={midia.url} className={styles.mediaVideo} controls />
                        ) : (
                          <img src={midia.url} alt={midia.titulo || 'Mídia'} className={styles.mediaThumb} />
                        )}

                        <button
                          type="button"
                          className={styles.deleteMediaBtn}
                          onClick={() => handleRemoveMidia(midia.id)}
                          title="Remover Mídia"
                        >
                          <Trash2 size={16} />
                        </button>

                        {midia.titulo && (
                          <div className={styles.mediaTitle} title={midia.titulo}>
                            {midia.titulo}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Botões de Ação */}
              <div className={styles.actionsRow}>
                <Link to="/configuracoes" className={`${shared.btn} ${shared.btnOutline}`}>
                  Cancelar
                </Link>
                <button
                  type="submit"
                  className={`${shared.btn} ${shared.btnPrimary}`}
                  disabled={salvando}
                >
                  <Save size={18} /> {salvando ? 'Salvando...' : 'Salvar Alterações'}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>

      <Footer />
      <Snackbar
        message={snackMsg}
        open={snackOpen}
        onClose={() => setSnackOpen(false)}
      />
    </>
  )
}
