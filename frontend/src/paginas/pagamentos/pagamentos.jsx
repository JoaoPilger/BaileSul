import { useEffect, useMemo, useState } from 'react';
import { Search, User, CheckCircle, XCircle } from 'lucide-react';
import Header from '../../components/header/Header';
import Footer from '../../components/footer/Footer';
import { useAuth } from '../../contexts/AuthContext';
import api from '../../services/api';
import styles from './pagamentos.module.css';

const ABAS = [
  { key: 'pendente', label: 'Pendente' },
  { key: 'confirmado', label: 'Confirmados' },
  { key: 'rejeitado', label: 'Rejeitados' },
];

function useDebouncedValue(value, delay = 300) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(t);
  }, [value, delay]);
  return debounced;
}

export default function ConfirmarPagamentos() {
  const { usuario, token } = useAuth();

  const [pagamentos, setPagamentos] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [erro, setErro] = useState('');
  const [processandoId, setProcessandoId] = useState(null);

  const [abaAtiva, setAbaAtiva] = useState('pendente');
  const [busca, setBusca] = useState('');
  const buscaDebounced = useDebouncedValue(busca, 300);

  // Só vendedores (usuário do tipo "pessoal" vinculado a uma comunidade)
  // podem confirmar/rejeitar pagamento — trava também no front, além do backend.
  const podeGerenciar = usuario?.tipo === 'pessoal';

  useEffect(() => {
    if (!podeGerenciar) return;

    let cancelado = false;

    api
      .get('/vendedores/reservas', { headers: { Authorization: `Bearer ${token}` } })
      .then(({ data }) => {
        if (!cancelado) setPagamentos(Array.isArray(data) ? data : []);
      })
      .catch(() => {
        if (!cancelado) setErro('Não foi possível carregar os pagamentos.');
      })
      .finally(() => {
        if (!cancelado) setIsLoading(false);
      });

    return () => { cancelado = true };
  }, [podeGerenciar, token]);

  const confirmar = async (id) => {
    setProcessandoId(id);
    try {
      await api.patch(
        `/vendedores/reservas/${id}/confirmar`,
        {},
        { headers: { Authorization: `Bearer ${token}` } },
      );
      setPagamentos((prev) => prev.map((p) => (p.id === id ? { ...p, status_pagamento: 'confirmado' } : p)));
    } catch {
      setErro('Não foi possível confirmar esse pagamento.');
    } finally {
      setProcessandoId(null);
    }
  };

  const rejeitar = async (id) => {
    setProcessandoId(id);
    try {
      await api.patch(
        `/vendedores/reservas/${id}/rejeitar`,
        {},
        { headers: { Authorization: `Bearer ${token}` } },
      );
      setPagamentos((prev) => prev.map((p) => (p.id === id ? { ...p, status_pagamento: 'rejeitado' } : p)));
    } catch {
      setErro('Não foi possível rejeitar esse pagamento.');
    } finally {
      setProcessandoId(null);
    }
  };

  const totalConfirmado = useMemo(
    () => pagamentos
      .filter((p) => p.status_pagamento === 'confirmado')
      .reduce((acc, p) => acc + Number(p.valor_total || 0), 0),
    [pagamentos],
  );

  const contagem = useMemo(() => ({
    pendente: pagamentos.filter((p) => p.status_pagamento === 'pendente').length,
    confirmado: pagamentos.filter((p) => p.status_pagamento === 'confirmado').length,
    rejeitado: pagamentos.filter((p) => p.status_pagamento === 'rejeitado').length,
  }), [pagamentos]);

  const filtrados = useMemo(() => {
    const q = buscaDebounced.trim().toLowerCase();
    return pagamentos.filter((p) => {
      if (p.status_pagamento !== abaAtiva) return false;
      if (!q) return true;
      return (
        (p.comprador_nome || '').toLowerCase().includes(q) ||
        (p.comprador_email || '').toLowerCase().includes(q) ||
        (p.evento || '').toLowerCase().includes(q)
      );
    });
  }, [pagamentos, abaAtiva, buscaDebounced]);

  if (!podeGerenciar) {
    return (
      <div className={styles.page}>
        <Header />
        <main className={styles.main}>
          <div className={styles.vazio}>
            Essa página é exclusiva para vendedores. Se você é vendedor de alguma
            comunidade, entre com a conta pessoal vinculada.
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
        <div className={styles.hero}>
          <div>
            <h1 className={styles.heroTitle}>Confirmar Pagamentos</h1>
            <p className={styles.heroSub}>Gerencie as confirmações de pagamento</p>
          </div>
          <div className={styles.totalBox}>
            <span className={styles.totalLabel}>Total Confirmado</span>
            <span className={styles.totalValue}>
              R$ {totalConfirmado.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
            </span>
          </div>
        </div>

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

        <div className={styles.buscaWrap}>
          <Search size={16} className={styles.buscaIcon} />
          <input
            className={styles.buscaInput}
            value={busca}
            onChange={(e) => setBusca(e.target.value)}
            placeholder="Busca por nome, email ou evento"
          />
        </div>

        {isLoading && <div className={styles.vazio}>Carregando pagamentos...</div>}

        {!isLoading && erro && <div className={styles.vazio}>{erro}</div>}

        {!isLoading && !erro && (
          <div className={styles.lista}>
            {filtrados.length === 0 && (
              <div className={styles.vazio}>Nenhum pagamento encontrado.</div>
            )}

            {filtrados.map((p) => (
              <div key={p.id} className={styles.card}>
                <div className={styles.avatar}>
                  <User size={18} strokeWidth={1.8} />
                </div>

                <div className={styles.info}>
                  <span className={styles.nome}>{p.comprador_nome || 'Usuário sem nome'}</span>
                  <span className={styles.email}>{p.comprador_email}</span>
                </div>

                <div className={styles.eventoCol}>
                  <span className={styles.fieldLabel}>Evento</span>
                  <span className={styles.eventoNome}>{p.evento}</span>
                </div>

                <div className={styles.valorCol}>
                  <span className={styles.fieldLabel}>Valor Total</span>
                  <span className={styles.valorTotal}>
                    R$ {Number(p.valor_total || 0).toFixed(2).replace('.', ',')}
                  </span>
                  <span className={styles.valorParcelas}>
                    {p.quantidade}x ingresso{p.quantidade > 1 ? 's' : ''}
                  </span>
                </div>

                <div className={styles.acoes}>
                  {abaAtiva === 'pendente' && (
                    <>
                      <button
                        type="button"
                        className={styles.btnConfirmar}
                        disabled={processandoId === p.id}
                        onClick={() => confirmar(p.id)}
                      >
                        <CheckCircle size={15} />
                        Confirmar
                      </button>
                      <button
                        type="button"
                        className={styles.btnRejeitar}
                        disabled={processandoId === p.id}
                        onClick={() => rejeitar(p.id)}
                      >
                        <XCircle size={15} />
                        Rejeitar
                      </button>
                    </>
                  )}
                  {abaAtiva === 'confirmado' && (
                    <span className={styles.badgeConfirmado}>✓ Confirmado</span>
                  )}
                  {abaAtiva === 'rejeitado' && (
                    <span className={styles.badgeRejeitado}>✕ Rejeitado</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </main>

      <Footer />
    </div>
  );
}
