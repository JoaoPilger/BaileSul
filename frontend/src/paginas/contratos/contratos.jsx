import { useEffect, useMemo, useState } from 'react';
import { Search, CheckCircle, XCircle, FileText, MapPin, Calendar } from 'lucide-react';
import Header from '../../components/header/Header';
import Footer from '../../components/footer/Footer';
import { useAuth } from '../../contexts/AuthContext';
import api from '../../services/api';
import styles from './contratos.module.css';

const ABAS = [
  { key: 'pendente',  label: 'Pendentes'  },
  { key: 'aceito',    label: 'Aceitos'    },
  { key: 'recusado',  label: 'Recusados'  },
];

function useDebouncedValue(value, delay = 300) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(t);
  }, [value, delay]);
  return debounced;
}

/** Formata data YYYY-MM-DD ou ISO timestamp → DD/MM/AAAA */
function formatarData(str) {
  if (!str) return '—';
  const s = str.slice(0, 10);
  const [y, m, d] = s.split('-');
  return `${d}/${m}/${y}`;
}

export default function ContratosPage() {
  const { usuario, token } = useAuth();

  const [contratos, setContratos]     = useState([]);
  const [isLoading, setIsLoading]     = useState(true);
  const [erro, setErro]               = useState('');
  const [processandoId, setProcessandoId] = useState(null);
  const [feedback, setFeedback]       = useState({ id: null, tipo: null }); // tipo: 'aceito' | 'recusado'

  const [abaAtiva, setAbaAtiva]       = useState('pendente');
  const [busca, setBusca]             = useState('');
  const buscaDebounced                = useDebouncedValue(busca, 300);

  const ehBanda = usuario?.tipo === 'banda';

  // ── carregar agenda ─────────────────────────────────────────
  useEffect(() => {
    if (!ehBanda) { setIsLoading(false); return; }
    let cancelado = false;
    setIsLoading(true);
    setErro('');

    api
      .get('/bandas/me/agenda', { headers: { Authorization: `Bearer ${token}` } })
      .then(({ data }) => {
        if (!cancelado) setContratos(Array.isArray(data) ? data : []);
      })
      .catch(() => {
        if (!cancelado) setErro('Não foi possível carregar seus contratos.');
      })
      .finally(() => {
        if (!cancelado) setIsLoading(false);
      });

    return () => { cancelado = true; };
  }, [ehBanda, token]);

  // ── responder contrato ──────────────────────────────────────
  const responder = async (contrato_id, evento_id, aceitar) => {
    setProcessandoId(contrato_id);
    try {
      await api.patch(
        `/eventos/${evento_id}/contratos/${contrato_id}`,
        { status_aceite: aceitar ? 'aceito' : 'recusado' },
        { headers: { Authorization: `Bearer ${token}` } },
      );
      const novoStatus = aceitar ? 'aceito' : 'recusado';
      setContratos((prev) =>
        prev.map((c) =>
          c.contrato_id === contrato_id ? { ...c, status_aceite: novoStatus } : c,
        ),
      );
      setFeedback({ id: contrato_id, tipo: novoStatus });
      setTimeout(() => setFeedback({ id: null, tipo: null }), 2000);
    } catch {
      setErro('Não foi possível processar essa resposta.');
    } finally {
      setProcessandoId(null);
    }
  };

  // ── contagens e filtros ─────────────────────────────────────
  const contagem = useMemo(() => ({
    pendente: contratos.filter((c) => c.status_aceite === 'pendente').length,
    aceito:   contratos.filter((c) => c.status_aceite === 'aceito').length,
    recusado: contratos.filter((c) => c.status_aceite === 'recusado').length,
  }), [contratos]);

  const filtrados = useMemo(() => {
    const q = buscaDebounced.trim().toLowerCase();
    return contratos.filter((c) => {
      if (c.status_aceite !== abaAtiva) return false;
      if (!q) return true;
      return (
        (c.titulo      || '').toLowerCase().includes(q) ||
        (c.comunidade  || '').toLowerCase().includes(q) ||
        (c.cidade      || '').toLowerCase().includes(q)
      );
    });
  }, [contratos, abaAtiva, buscaDebounced]);

  // ── acesso negado ───────────────────────────────────────────
  if (!ehBanda) {
    return (
      <div className={styles.page}>
        <Header />
        <main className={styles.main}>
          <div className={styles.vazio}>
            Esta página é exclusiva para bandas. Faça login com uma conta de banda.
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>

        {/* ── Hero ── */}
        <div className={styles.hero}>
          <div className={styles.heroLeft}>
            <div className={styles.heroIconWrap}>
              <FileText size={22} strokeWidth={1.8} />
            </div>
            <div>
              <h1 className={styles.heroTitle}>Contratos</h1>
              <p className={styles.heroSub}>Aceite ou recuse os convites das comunidades</p>
            </div>
          </div>
          <div className={styles.heroStats}>
            <div className={styles.heroStat}>
              <span className={styles.heroStatValue}>{contagem.pendente}</span>
              <span className={styles.heroStatLabel}>Pendentes</span>
            </div>
            <div className={styles.heroStatDivider} />
            <div className={styles.heroStat}>
              <span className={styles.heroStatValue + ' ' + styles.heroStatValueGreen}>{contagem.aceito}</span>
              <span className={styles.heroStatLabel}>Aceitos</span>
            </div>
            <div className={styles.heroStatDivider} />
            <div className={styles.heroStat}>
              <span className={styles.heroStatValue + ' ' + styles.heroStatValueRed}>{contagem.recusado}</span>
              <span className={styles.heroStatLabel}>Recusados</span>
            </div>
          </div>
        </div>

        {/* ── Abas ── */}
        <div className={styles.abas}>
          {ABAS.map(({ key, label }) => (
            <button
              key={key}
              type="button"
              className={`${styles.aba} ${abaAtiva === key ? styles.abaAtiva : ''}`}
              onClick={() => setAbaAtiva(key)}
            >
              <span className={styles.abaLabel}>{label}</span>
              <span className={styles.abaCount}>{contagem[key]}</span>
            </button>
          ))}
        </div>

        {/* ── Busca ── */}
        <div className={styles.buscaWrap}>
          <Search size={16} className={styles.buscaIcon} />
          <input
            className={styles.buscaInput}
            value={busca}
            onChange={(e) => setBusca(e.target.value)}
            placeholder="Buscar por evento, comunidade ou cidade..."
          />
        </div>

        {/* ── Erro de carregamento ── */}
        {isLoading && <div className={styles.vazio}>Carregando contratos...</div>}
        {!isLoading && erro && <div className={styles.vazioDanger}>{erro}</div>}

        {/* ── Lista ── */}
        {!isLoading && !erro && (
          <div className={styles.lista}>
            {filtrados.length === 0 && (
              <div className={styles.vazio}>
                {abaAtiva === 'pendente'
                  ? 'Nenhum convite pendente no momento.'
                  : abaAtiva === 'aceito'
                  ? 'Nenhum contrato aceito ainda.'
                  : 'Nenhum contrato recusado.'}
              </div>
            )}

            {filtrados.map((c) => {
              const isFeedback = feedback.id === c.contrato_id;
              return (
                <div
                  key={c.contrato_id}
                  className={`${styles.card} ${isFeedback ? styles['card--flash'] : ''}`}
                >
                  {/* Ícone */}
                  <div className={styles.avatar}>
                    <FileText size={18} strokeWidth={1.8} />
                  </div>

                  {/* Evento */}
                  <div className={styles.infoEvento}>
                    <span className={styles.eventoTitulo}>{c.titulo}</span>
                    <span className={styles.eventoComunidade}>{c.comunidade}</span>
                  </div>

                  {/* Data */}
                  <div className={styles.infoCol}>
                    <span className={styles.fieldLabel}>
                      <Calendar size={11} strokeWidth={2} style={{ verticalAlign: 'middle', marginRight: 3 }} />
                      Data
                    </span>
                    <span className={styles.fieldValue}>{formatarData(c.data_inicio)}</span>
                  </div>

                  {/* Local */}
                  <div className={styles.infoCol}>
                    <span className={styles.fieldLabel}>
                      <MapPin size={11} strokeWidth={2} style={{ verticalAlign: 'middle', marginRight: 3 }} />
                      Local
                    </span>
                    <span className={styles.fieldValue}>
                      {c.local_nome || '—'}
                      {c.cidade ? ` · ${c.cidade}` : ''}
                    </span>
                  </div>

                  {/* Ações */}
                  <div className={styles.acoes}>
                    {abaAtiva === 'pendente' && (
                      <>
                        <button
                          type="button"
                          className={styles.btnAceitar}
                          disabled={processandoId === c.contrato_id}
                          onClick={() => responder(c.contrato_id, c.id, true)}
                        >
                          <CheckCircle size={15} />
                          Aceitar
                        </button>
                        <button
                          type="button"
                          className={styles.btnRecusar}
                          disabled={processandoId === c.contrato_id}
                          onClick={() => responder(c.contrato_id, c.id, false)}
                        >
                          <XCircle size={15} />
                          Recusar
                        </button>
                      </>
                    )}
                    {abaAtiva === 'aceito' && (
                      <span className={styles.badgeAceito}>✓ Aceito</span>
                    )}
                    {abaAtiva === 'recusado' && (
                      <span className={styles.badgeRecusado}>✕ Recusado</span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>
      <Footer />
    </div>
  );
}
