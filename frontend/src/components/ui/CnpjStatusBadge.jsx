const estilos = {
  checking: { color: 'var(--muted)', background: 'rgba(17,17,17,0.06)', border: '1px solid rgba(17,17,17,0.15)' },
  valido:   { color: 'var(--success)', background: 'var(--success-soft)', border: '1px solid rgba(15,110,86,0.2)' },
  invalido: { color: 'var(--danger)', background: 'var(--danger-soft)', border: '1px solid rgba(194,69,69,0.2)' },
}

const textos = {
  checking: 'Verificando CNPJ...',
  valido: 'CNPJ ativo na Receita Federal',
  invalido: 'CNPJ não encontrado ou inativo na Receita Federal',
}

const icones = {
  checking: '⏳',
  valido: '✅',
  invalido: '⚠️',
}

/**
 * Badge de status de verificação de CNPJ (consulta em tempo real à Receita).
 * status: 'idle' | 'checking' | 'valido' | 'invalido'
 */
export default function CnpjStatusBadge({ status, razaoSocial }) {
  if (status === 'idle' || !status) return null

  return (
    <span
      role="status"
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 6,
        marginTop: 6,
        padding: '4px 10px',
        borderRadius: 999,
        fontSize: '0.76rem',
        fontWeight: 600,
        ...estilos[status],
      }}
    >
      <span aria-hidden="true">{icones[status]}</span>
      {textos[status]}{status === 'valido' && razaoSocial ? ` — ${razaoSocial}` : ''}
    </span>
  )
}
