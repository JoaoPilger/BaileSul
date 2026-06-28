import { useState } from 'react';
import { Search, User, CheckCircle, XCircle } from 'lucide-react';
import Header from '../../components/header/Header';
import Footer from '../../components/footer/Footer';
import styles from './pagamentos.module.css';

const pagamentosIniciais = [
  { id: 1, nome: 'João Silva', email: 'joao.silva@email.com', evento: 'Festa Junina 2026', valor: 100.0, parcelas: 2, valorParcela: 50.0, status: 'pendente' },
  { id: 2, nome: 'Maria Souza', email: 'maria.souza@email.com', evento: 'Festa Junina 2026', valor: 100.0, parcelas: 2, valorParcela: 50.0, status: 'pendente' },
  { id: 3, nome: 'Carlos Lima', email: 'carlos.lima@email.com', evento: 'Baile do Sul 2026', valor: 150.0, parcelas: 3, valorParcela: 50.0, status: 'confirmado' },
  { id: 4, nome: 'Ana Paula', email: 'ana.paula@email.com', evento: 'Baile do Sul 2026', valor: 200.0, parcelas: 4, valorParcela: 50.0, status: 'rejeitado' },
  { id: 5, nome: 'Pedro Alves', email: 'pedro.alves@email.com', evento: 'Festa Junina 2026', valor: 100.0, parcelas: 2, valorParcela: 50.0, status: 'pendente' },
  { id: 6, nome: 'Fernanda Costa', email: 'fernanda.costa@email.com', evento: 'Baile do Sul 2026', valor: 250.0, parcelas: 5, valorParcela: 50.0, status: 'confirmado' },
];

const ABAS = [
  { key: 'pendente', label: 'Pendente' },
  { key: 'confirmado', label: 'Confirmados' },
  { key: 'rejeitado', label: 'Rejeitados' },
];

export default function ConfirmarPagamentos() {
  const [pagamentos, setPagamentos] = useState(pagamentosIniciais);
  const [abaAtiva, setAbaAtiva] = useState('pendente');
  const [busca, setBusca] = useState('');

  const totalConfirmado = pagamentos
    .filter((p) => p.status === 'confirmado')
    .reduce((acc, p) => acc + p.valor, 0);

  const contagem = {
    pendente: pagamentos.filter((p) => p.status === 'pendente').length,
    confirmado: pagamentos.filter((p) => p.status === 'confirmado').length,
    rejeitado: pagamentos.filter((p) => p.status === 'rejeitado').length,
  };

  const confirmar = (id) =>
    setPagamentos((prev) => prev.map((p) => (p.id === id ? { ...p, status: 'confirmado' } : p)));

  const rejeitar = (id) =>
    setPagamentos((prev) => prev.map((p) => (p.id === id ? { ...p, status: 'rejeitado' } : p)));

  const filtrados = pagamentos.filter((p) => {
    const q = busca.toLowerCase();
    return (
      p.status === abaAtiva &&
      (!busca ||
        p.nome.toLowerCase().includes(q) ||
        p.email.toLowerCase().includes(q) ||
        p.evento.toLowerCase().includes(q))
    );
  });

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
                <span className={styles.nome}>{p.nome}</span>
                <span className={styles.email}>{p.email}</span>
              </div>

              <div className={styles.eventoCol}>
                <span className={styles.fieldLabel}>Evento</span>
                <span className={styles.eventoNome}>{p.evento}</span>
              </div>

              <div className={styles.valorCol}>
                <span className={styles.fieldLabel}>Valor Total</span>
                <span className={styles.valorTotal}>
                  R$ {p.valor.toFixed(2).replace('.', ',')}
                </span>
                <span className={styles.valorParcelas}>
                  {p.parcelas}x R$ {p.valorParcela.toFixed(2).replace('.', ',')}
                </span>
              </div>

              <div className={styles.acoes}>
                {abaAtiva === 'pendente' && (
                  <>
                    <button type="button" className={styles.btnConfirmar} onClick={() => confirmar(p.id)}>
                      <CheckCircle size={15} />
                      Confirmar
                    </button>
                    <button type="button" className={styles.btnRejeitar} onClick={() => rejeitar(p.id)}>
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
      </main>

      <Footer />
    </div>
  );
}
