import { Calendar, Music, ListMusic, Ticket, Users, Wallet, FileText } from 'lucide-react';

export function getNavConfig(tipo, isVendedor = false) {
  const base = [
    { to: '/',        label: 'Início',      icon: Music },
    { to: '/eventos', label: 'Eventos',     icon: Calendar },
    { to: '/bandas',  label: 'Bandas',      icon: Music },
    { to: '/comunidades', label: 'Comunidades', icon: Users },
  ];

  if (tipo === 'pessoal') {
    base.push({ to: '/meus-ingressos', label: 'Meus Ingressos', icon: Ticket });
    if (isVendedor) {
      base.push({ to: '/pagamentos', label: 'Pagamentos', icon: Wallet });
    }
  } else if (tipo === 'banda') {
    base.push({ to: '/meus-eventos/banda', label: 'Meus Eventos', icon: ListMusic });
    base.push({ to: '/contratos',    label: 'Contratos',    icon: FileText });
  } else if (tipo === 'comunidade') {
    base.push({ to: '/meus-eventos', label: 'Meus Eventos', icon: ListMusic });
    base.push({ to: '/vendedores',   label: 'Vendedores',   icon: Users });
  }

  return {
    links: base,
    podeCriarEvento: tipo === 'comunidade',
  };
}