import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Menu, X, User, Plus } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { getNavConfig } from '../layout/layoutHelpers';
import './Header.css';

export default function Header() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const location = useLocation();
  const { usuario, isAuthenticated } = useAuth();
  const { links, podeCriarEvento } = getNavConfig(usuario?.tipo);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 10);
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const isActive = (path) => location.pathname === path;
  const contaLink = isAuthenticated ? '/perfil' : '/login';
  const contaLabel = isAuthenticated ? 'Minha conta' : 'Entrar';

  return (
    <nav className={`navbar ${scrolled ? 'navbar--scrolled' : ''}`}>
      <div className="navbar-shell">
        <div className="navbar-zone navbar-zone--logo">
          <Link to="/" className="navbar-logo" aria-label="BaileSul">
            <img
              src="/imagens/BaileSul.png"
              alt="BaileSul"
              className="navbar-logo-img"
              decoding="async"
            />
          </Link>
        </div>

        <div className="navbar-zone navbar-zone--nav">
          {links.map(({ to, label, icon: NavIcon }) => (
            <Link
              key={to}
              to={to}
              className={`navbar-link ${isActive(to) ? 'navbar-link--active' : ''}`}
            >
              <NavIcon size={17} strokeWidth={2} aria-hidden />
              <span className="navbar-link-text">{label}</span>
            </Link>
          ))}
        </div>

        <div className="navbar-zone navbar-zone--actions">
          <div className="navbar-actions-desktop">
            {podeCriarEvento && (
              <Link to="/criar-evento" className="btn-nav-create">
                <Plus size={15} strokeWidth={2} aria-hidden />
                <span>Criar Evento</span>
              </Link>
            )}
            <Link to={contaLink} className="navbar-icon-btn navbar-login-btn" aria-label={contaLabel}>
              <User size={20} strokeWidth={2} />
            </Link>
          </div>
          <button
            type="button"
            className="navbar-hamburger"
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label="Menu"
          >
            {mobileOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>
      </div>

      <div className={`navbar-mobile ${mobileOpen ? 'navbar-mobile--open' : ''}`}>
        {links.map(({ to, label, icon: NavIcon }) => (
          <Link
            key={to}
            to={to}
            className={`navbar-mobile-link ${isActive(to) ? 'navbar-mobile-link--active' : ''}`}
            onClick={() => setMobileOpen(false)}
          >
            <NavIcon size={18} strokeWidth={2} aria-hidden />
            <span className="navbar-link-text">{label}</span>
          </Link>
        ))}
        <div className="navbar-mobile-divider" />
        {podeCriarEvento && (
          <Link to="/criar-evento" className="btn-nav-create btn-nav-create--mobile" onClick={() => setMobileOpen(false)}>
            <Plus size={15} strokeWidth={2} aria-hidden />
            <span>Criar Evento</span>
          </Link>
        )}
        <Link to={contaLink} className="navbar-mobile-link" onClick={() => setMobileOpen(false)}>
          <User size={18} strokeWidth={2} aria-hidden />
          <span>{contaLabel}</span>
        </Link>
      </div>
    </nav>
  );
}
