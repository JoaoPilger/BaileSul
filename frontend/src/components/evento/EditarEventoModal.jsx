import { useState, useEffect, useRef } from 'react'
import { cn } from '../../utils/cn'
import api from '../../services/api'
import styles from './EditarEventoModal.module.css'

const soData = (valor) => (valor ? String(valor).split('T')[0] : '')

function normalizarMedia(url) {
  if (url && url.includes('/media/')) {
    return url.substring(url.indexOf('/media/'))
  }
  return url || ''
}

export default function EditarEventoModal({ evento, onFechar, onSalvo }) {
  const [form, setForm] = useState({
    titulo: '',
    descricao: '',
    data_inicio: '',
    data_fim: '',
    local_nome: '',
    valor_ingresso: '',
    capacidade_maxima: '',
  })
  const [tipoEvento, setTipoEvento] = useState('')
  const [imagemFile, setImagemFile] = useState(null)
  const [imagemPreview, setImagemPreview] = useState('')
  const [erro, setErro] = useState('')
  const [salvando, setSalvando] = useState(false)

  const [bandaTexto, setBandaTexto] = useState('')
  const [bandaId, setBandaId] = useState(null)
  const [bandaOriginalId, setBandaOriginalId] = useState(null)
  const [contratoAtualId, setContratoAtualId] = useState(null)
  const [bandaSugestoes, setBandaSugestoes] = useState([])
  const [bandaSugestoesOpen, setBandaSugestoesOpen] = useState(false)

  const fileRef = useRef(null)

  useEffect(() => {
    let ativo = true
    api.get(`/eventos/${evento.id}`)
      .then(({ data }) => {
        if (!ativo) return
        setForm({
          titulo: data.titulo || '',
          descricao: data.descricao || '',
          data_inicio: soData(data.data_inicio),
          data_fim: soData(data.data_fim),
          local_nome: data.local_nome || '',
          valor_ingresso:
            data.valor_ingresso != null && data.valor_ingresso !== ''
              ? String(data.valor_ingresso).replace('.', ',')
              : '',
          capacidade_maxima:
            data.capacidade_maxima != null ? String(data.capacidade_maxima) : '',
        })
        setTipoEvento(data.tipo_evento || '')
        setImagemPreview(normalizarMedia(data.foto_capa_url))
        const banda = Array.isArray(data.bandas) ? data.bandas[0] : null
        if (banda) {
          setBandaTexto(banda.nome_artistico || '')
          setBandaId(banda.usuario_id ?? null)
          setBandaOriginalId(banda.usuario_id ?? null)
          setContratoAtualId(banda.contrato_id ?? null)
        }
      })
      .catch((err) => {
        console.error(err)
        if (ativo) setErro('Não foi possível carregar o evento.')
      })
    return () => { ativo = false }
  }, [evento.id])

  useEffect(() => {
    let cancelado = false
    const t = setTimeout(async () => {
      if (!tipoEvento.startsWith('musical_')) {
        if (!cancelado) { setBandaSugestoes([]); setBandaSugestoesOpen(false) }
        return
      }
      if (bandaId) {
        if (!cancelado) setBandaSugestoesOpen(false)
        return
      }
      const termo = bandaTexto.trim()
      if (termo.length < 2) {
        if (!cancelado) { setBandaSugestoes([]); setBandaSugestoesOpen(false) }
        return
      }
      try {
        const { data } = await api.get('/bandas/sugestoes', { params: { nome: termo } })
        if (!cancelado) {
          setBandaSugestoes(Array.isArray(data) ? data : [])
          setBandaSugestoesOpen(true)
        }
      } catch {
        if (!cancelado) setBandaSugestoes([])
      }
    }, 300)
    return () => { cancelado = true; clearTimeout(t) }
  }, [bandaTexto, tipoEvento, bandaId])

  const handleCampo = (campo, valor) => {
    setForm((prev) => ({ ...prev, [campo]: valor }))
  }

  const handleBandaTexto = (valor) => {
    setBandaTexto(valor)
    setBandaId(null)
  }

  const selecionarBanda = (banda) => {
    setBandaId(banda.usuario_id)
    setBandaTexto(banda.nome_artistico)
    setBandaSugestoesOpen(false)
    setBandaSugestoes([])
  }

  const handleImagem = (file) => {
    if (!file) return
    const tiposValidos = ['image/png', 'image/jpeg', 'image/webp']
    if (!tiposValidos.includes(file.type)) {
      setErro('Formato de imagem inválido. Use PNG, JPG ou WEBP.')
      return
    }
    if (file.size > 5 * 1024 * 1024) {
      setErro('A imagem deve ter no máximo 5 MB.')
      return
    }
    setImagemFile(file)
    setImagemPreview(URL.createObjectURL(file))
    setErro('')
  }

  const handleSalvar = async (e) => {
    e.preventDefault()

    if (!form.titulo.trim()) {
      setErro('O título é obrigatório.')
      return
    }
    if (!form.data_inicio) {
      setErro('A data de início é obrigatória.')
      return
    }
    const dataFim = form.data_fim || form.data_inicio
    if (new Date(dataFim) < new Date(form.data_inicio)) {
      setErro('A data de término não pode ser anterior à data de início.')
      return
    }

    let valorNum = null
    const valorTxt = String(form.valor_ingresso).replace(',', '.').trim()
    if (valorTxt !== '') {
      const n = parseFloat(valorTxt)
      if (Number.isNaN(n) || n < 0) {
        setErro('Informe um valor de ingresso válido.')
        return
      }
      valorNum = n
    }

    const capacidadeTxt = String(form.capacidade_maxima).trim()
    if (capacidadeTxt !== '' && (!/^\d+$/.test(capacidadeTxt) || parseInt(capacidadeTxt, 10) < 1)) {
      setErro('Informe uma capacidade máxima válida (número inteiro maior que zero).')
      return
    }

    const formData = new FormData()
    formData.append('titulo', form.titulo.trim())
    formData.append('descricao', form.descricao || '')
    formData.append('data_inicio', form.data_inicio)
    formData.append('data_fim', dataFim)
    formData.append('local_nome', form.local_nome || '')
    if (valorNum !== null) formData.append('valor_ingresso', String(valorNum))
    if (capacidadeTxt !== '') formData.append('capacidade_maxima', capacidadeTxt)
    if (imagemFile) formData.append('foto_capa', imagemFile)

    setSalvando(true)
    setErro('')
    try {
      await api.put(`/eventos/${evento.id}`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
    } catch (err) {
      console.error(err)
      setErro(err.response?.data?.error || 'Não foi possível salvar. Tente novamente.')
      setSalvando(false)
      return
    }

    if (tipoEvento.startsWith('musical_')) {
      const bandaLimpa = bandaTexto.trim() === '' && bandaId == null
      try {
        if (bandaId && bandaId !== bandaOriginalId) {
          if (contratoAtualId) {
            await api.delete(`/eventos/${evento.id}/contratos/${contratoAtualId}`)
          }
          await api.post(`/eventos/${evento.id}/contratos`, { banda_id: bandaId })
        } else if (bandaLimpa && contratoAtualId) {
          await api.delete(`/eventos/${evento.id}/contratos/${contratoAtualId}`)
        }
      } catch (bandaErr) {
        console.error(bandaErr)
        if (onSalvo) onSalvo()
        setErro('Evento salvo, mas não foi possível atualizar a banda. Tente novamente.')
        setSalvando(false)
        return
      }
    }

    if (onSalvo) onSalvo()
    onFechar()
  }

  const ehMusical = tipoEvento.startsWith('musical_')

  return (
    <div className={styles.overlay} onClick={onFechar}>
      <div
        className={styles.modal}
        role="dialog"
        aria-modal="true"
        aria-labelledby="ee-modal-title"
        onClick={(e) => e.stopPropagation()}
      >
        <div className={styles.header}>
          <h2 id="ee-modal-title" className={styles.title}>Editar evento</h2>
          <button type="button" className={styles.close} onClick={onFechar} aria-label="Fechar">
            <svg viewBox="0 0 24 24">
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        </div>

        <form className={styles.body} onSubmit={handleSalvar}>
          {erro && <div className={styles.alert} role="alert">{erro}</div>}

          <div className={styles.field}>
            <label className={styles.label} htmlFor="ee-titulo">Título do evento</label>
            <input
              id="ee-titulo"
              type="text"
              className={styles.input}
              value={form.titulo}
              onChange={(e) => handleCampo('titulo', e.target.value)}
              maxLength={120}
            />
          </div>

          {ehMusical && (
            <div className={styles.field}>
              <label className={styles.label} htmlFor="ee-banda">Banda / Artista</label>
              <input
                id="ee-banda"
                type="text"
                autoComplete="off"
                className={styles.input}
                placeholder="Digite para buscar uma banda cadastrada"
                value={bandaTexto}
                onChange={(e) => handleBandaTexto(e.target.value)}
                onFocus={() => bandaSugestoes.length > 0 && setBandaSugestoesOpen(true)}
                onBlur={() => setTimeout(() => setBandaSugestoesOpen(false), 120)}
                maxLength={80}
              />
              {bandaId && (
                <span className={styles.bandaLinked}>
                  ✓ Vinculada a uma banda cadastrada — receberá um convite ao salvar.
                </span>
              )}
              {bandaSugestoesOpen && bandaSugestoes.length > 0 && (
                <ul className={styles.sugestoes}>
                  {bandaSugestoes.map((b) => (
                    <li
                      key={b.usuario_id}
                      className={styles.sugestaoItem}
                      onMouseDown={() => selecionarBanda(b)}
                    >
                      <span>{b.nome_artistico}</span>
                      {b.estilo_musical && (
                        <span className={styles.sugestaoEstilo}>{b.estilo_musical}</span>
                      )}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}

          <div className={styles.field}>
            <label className={styles.label}>Imagem de capa</label>
            <div
              className={styles.uploadArea}
              onClick={() => fileRef.current?.click()}
              onDrop={(e) => { e.preventDefault(); handleImagem(e.dataTransfer.files[0]) }}
              onDragOver={(e) => e.preventDefault()}
            >
              {imagemPreview ? (
                <>
                  <img src={imagemPreview} alt="Prévia da capa" className={styles.uploadPreview} />
                  <span className={styles.uploadOverlay}>Clique para trocar a imagem</span>
                </>
              ) : (
                <div className={styles.uploadPlaceholder}>
                  <svg viewBox="0 0 24 24">
                    <rect x="3" y="3" width="18" height="18" rx="2" />
                    <circle cx="8.5" cy="8.5" r="1.5" />
                    <polyline points="21 15 16 10 5 21" />
                  </svg>
                  <span>Clique para enviar uma imagem</span>
                  <small>PNG, JPG ou WEBP · Máx 5 MB</small>
                </div>
              )}
              <input
                ref={fileRef}
                type="file"
                accept="image/png,image/jpeg,image/webp"
                style={{ display: 'none' }}
                onChange={(e) => handleImagem(e.target.files[0])}
              />
            </div>
            {imagemFile && (
              <span className={styles.hint}>Nova imagem selecionada: {imagemFile.name}</span>
            )}
          </div>

          <div className={styles.field}>
            <label className={styles.label} htmlFor="ee-valor">Valor do ingresso (R$)</label>
            <input
              id="ee-valor"
              type="text"
              inputMode="decimal"
              className={styles.input}
              placeholder="Ex: 20,00 — deixe em branco para não alterar"
              value={form.valor_ingresso}
              onChange={(e) => handleCampo('valor_ingresso', e.target.value.replace(/[^\d.,]/g, ''))}
            />
            <span className={styles.hint}>Deixe 0 para entrada gratuita.</span>
          </div>

          <div className={styles.field}>
            <label className={styles.label} htmlFor="ee-capacidade">Capacidade máxima de ingressos</label>
            <input
              id="ee-capacidade"
              type="text"
              inputMode="numeric"
              className={styles.input}
              placeholder="Ex: 300 — deixe em branco se não houver limite"
              value={form.capacidade_maxima}
              onChange={(e) => handleCampo('capacidade_maxima', e.target.value.replace(/\D/g, '').slice(0, 6))}
            />
          </div>

          <div className={styles.row}>
            <div className={styles.field}>
              <label className={styles.label} htmlFor="ee-inicio">Data de início</label>
              <input
                id="ee-inicio"
                type="date"
                className={styles.input}
                value={form.data_inicio}
                onChange={(e) => handleCampo('data_inicio', e.target.value)}
              />
            </div>
            <div className={styles.field}>
              <label className={styles.label} htmlFor="ee-fim">Data de término</label>
              <input
                id="ee-fim"
                type="date"
                className={styles.input}
                value={form.data_fim}
                min={form.data_inicio || undefined}
                onChange={(e) => handleCampo('data_fim', e.target.value)}
              />
            </div>
          </div>

          <div className={styles.field}>
            <label className={styles.label} htmlFor="ee-local">Local</label>
            <input
              id="ee-local"
              type="text"
              className={styles.input}
              placeholder="Ex: Concórdia, SC"
              value={form.local_nome}
              onChange={(e) => handleCampo('local_nome', e.target.value)}
              maxLength={120}
            />
          </div>

          <div className={styles.field}>
            <label className={styles.label} htmlFor="ee-descricao">Descrição</label>
            <textarea
              id="ee-descricao"
              className={cn(styles.input, styles.textarea)}
              value={form.descricao}
              onChange={(e) => handleCampo('descricao', e.target.value)}
              maxLength={1000}
              rows={4}
            />
          </div>

          <div className={styles.actions}>
            <button type="button" className={styles.btnCancelar} onClick={onFechar} disabled={salvando}>
              Cancelar
            </button>
            <button type="submit" className={styles.btnSalvar} disabled={salvando}>
              {salvando ? 'Salvando...' : 'Salvar alterações'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
