import React from 'react';
import { Link } from 'react-router-dom';
import { MapPin } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { getNavConfig } from './layoutHelpers';
import './Footer.css';

export default function Footer() {
  const { usuario } = useAuth();
  const { links, podeCriarEvento } = getNavConfig(usuario?.tipo);
  const contaLink = usuario ? '/perfil' : '/login';

  const navItems = [
    { to: '/eventos', label: 'Eventos' },
    { to: '/calendario', label: 'Calendário' },
    { to: '/mapa', label: 'Mapa' },
    ...links
      .filter((l) => l.to.startsWith('/meus-'))
      .map((l) => ({ to: l.to, label: l.label })),
    ...(podeCriarEvento ? [{ to: '/criar-evento', label: 'Criar Evento' }] : []),
    { to: contaLink, label: 'Perfil' },
  ];

  const leftItems = navItems.slice(0, 3);
  const rightItems = navItems.slice(3, 6);

  return (
    <footer className="footer">
      <div className="container footer-grid">
        <div className="footer-brand">
          <Link to="/" className="footer-logo-link" aria-label="BaileSul">
            <img
              src="/imagens/BaileSul.png"
              alt="BaileSul"
              className="footer-logo-img"
              decoding="async"
            />
          </Link>
          <p className="footer-tagline">
            A plataforma de eventos da região AMAUC. Conectando bandas, comunidades e público.
          </p>
        </div>

        <div className="footer-nav-block">
          <h4 className="footer-heading">Navegação</h4>
          <nav className="footer-nav">
            <div className="footer-nav-col">
              {leftItems.map((item) => (
                <Link key={item.to} to={item.to}>{item.label}</Link>
              ))}
            </div>
            <div className="footer-nav-col">
              {rightItems.map((item) => (
                <Link key={item.to} to={item.to}>{item.label}</Link>
              ))}
            </div>
          </nav>
        </div>

        <div className="footer-region-block">
          <h4 className="footer-heading">Região AMAUC</h4>
          <p className="footer-region">
            <MapPin size={13} />
            13 municípios · Santa Catarina
          </p>
        </div>
      </div>

      <div className="footer-bottom">
        <span>© BaileSul – Todos os direitos reservados.</span>
      </div>
    </footer>
  );
}
