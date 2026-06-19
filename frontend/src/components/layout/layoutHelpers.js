import { Calendar, MapPin, Music, ListMusic, Ticket, Users } from 'lucide-react';

export function getNavConfig(tipo) {
  const base = [
    { to: '/',        label: 'Início',      icon: Music },
    { to: '/eventos', label: 'Eventos',     icon: Calendar },
    { to: '/mapa',    label: 'Mapa',        icon: MapPin },
    { to: '/bandas',  label: 'Bandas',      icon: Music },
    { to: '/comunidades', label: 'Comunidades', icon: Users },
  ];

  if (tipo === 'pessoal') {
    base.push({ to: '/meus-ingressos', label: 'Meus Ingressos', icon: Ticket });
  } else if (tipo) {
    base.push({ to: '/meus-eventos', label: 'Meus Eventos', icon: ListMusic });
  }

  return {
    links: base,
    podeCriarEvento: tipo === 'comunidade',
  };
}
