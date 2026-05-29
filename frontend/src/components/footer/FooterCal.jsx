import React from 'react';
import { Link } from 'react-router-dom';
import { MapPin } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import './FooterCal.css';

export default function FooterCal() {
  const { isAuthenticated } = useAuth();
  const contaLink = isAuthenticated ? '/perfil' : '/login';

  const footerLinks = [
    { to: '/eventos', label: 'Eventos' },
    { to: '/calendario', label: 'Calendário' },
    { to: '/mapa', label: 'Mapa' },
    { to: '/meus-eventos', label: 'Meus Eventos' },
    { to: '/criar-evento', label: 'Criar Evento' },
    { to: contaLink, label: 'Perfil' },
  ];

  return (
    <footer className="cal-footer">
      <div className="cal-footer-inner">
        <div className="cal-footer-brand">
          <Link to="/" aria-label="BaileSul">
            <img src="/imagens/BaileSul.png" alt="BaileSul" className="cal-footer-logo" />
          </Link>
        </div>

        <div className="cal-footer-copy-block">
          <p className="cal-footer-copy">© BaileSul – Todos os direitos reservados.</p>
        </div>

        <nav className="cal-footer-nav-block" aria-label="Navegação do rodapé">
          <h4 className="cal-footer-heading">Navegação</h4>
          <div className="cal-footer-nav">
            <div className="cal-footer-nav-col">
              {footerLinks.slice(0, 3).map((item) => (
                <Link key={item.to} to={item.to}>{item.label}</Link>
              ))}
            </div>
            <div className="cal-footer-nav-col">
              {footerLinks.slice(3).map((item) => (
                <Link key={item.to} to={item.to}>{item.label}</Link>
              ))}
            </div>
          </div>
        </nav>
      </div>
    </footer>
  );
}
