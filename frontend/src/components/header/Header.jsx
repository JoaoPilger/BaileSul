import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Menu, X, User, Plus, Settings } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { getNavConfig } from '../layout/layoutHelpers';
import { cn } from '../../utils/cn';
import styles from './Header.module.css';

export default function Header() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const location = useLocation();
  const { usuario, isAuthenticated, isVendedor } = useAuth();
  const { links, podeCriarEvento } = getNavConfig(usuario?.tipo, isVendedor);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 10);
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const isActive = (path) => location.pathname === path;
  const contaLink = isAuthenticated ? '/perfil' : '/login';
  const contaLabel = isAuthenticated ? 'Minha conta' : 'Entrar';
  const isEventDetail = location.pathname.startsWith('/eventos/') && location.pathname !== '/eventos';
  const forceSolidPaths = ['/bandas', '/comunidades'];
  const isSolidPage = isEventDetail || forceSolidPaths.includes(location.pathname);

  return (
    <nav className={cn(
      styles.navbar,
      isSolidPage && styles['navbar--solid'],
      !isSolidPage && scrolled && styles['navbar--scrolled'],
    )}>
      <div className={styles['navbar-shell']}>
        <div className={cn(styles['navbar-zone'], styles['navbar-zone--logo'])}>
          <Link to="/" className={styles['navbar-logo']} aria-label="BaileSul">
            <img
              src="/imagens/BaileSul.png"
              alt="BaileSul"
              className={styles['navbar-logo-img']}
              decoding="async"
            />
          </Link>
        </div>

        <div className={cn(styles['navbar-zone'], styles['navbar-zone--nav'])}>
          {links.map(({ to, label, icon: NavIcon }) => (
            <Link
              key={to}
              to={to}
              className={cn(styles['navbar-link'], isActive(to) && styles['navbar-link--active'])}
            >
              <NavIcon size={17} strokeWidth={2} aria-hidden />
              <span className={styles['navbar-link-text']}>{label}</span>
            </Link>
          ))}
        </div>

        <div className={cn(styles['navbar-zone'], styles['navbar-zone--actions'])}>
          <div className={styles['navbar-actions-desktop']}>
            {podeCriarEvento && (
              <Link to="/criar-evento" className={styles['btn-nav-create']}>
                <Plus size={15} strokeWidth={2} aria-hidden />
                <span>Criar Evento</span>
              </Link>
            )}
            {isAuthenticated && (
              <Link to="/configuracoes" className={styles['navbar-icon-btn']} aria-label="Configurações">
                <Settings size={18} strokeWidth={2} />
              </Link>
            )}
            <Link to={contaLink} className={cn(styles['navbar-icon-btn'], styles['navbar-login-btn'])} aria-label={contaLabel}>
              <User size={20} strokeWidth={2} />
            </Link>
          </div>
          <button
            type="button"
            className={styles['navbar-hamburger']}
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label="Menu"
          >
            {mobileOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>
      </div>

      <div className={cn(styles['navbar-mobile'], mobileOpen && styles['navbar-mobile--open'])}>
        {links.map(({ to, label, icon: NavIcon }) => (
          <Link
            key={to}
            to={to}
            className={cn(styles['navbar-mobile-link'], isActive(to) && styles['navbar-mobile-link--active'])}
            onClick={() => setMobileOpen(false)}
          >
            <NavIcon size={18} strokeWidth={2} aria-hidden />
            <span className={styles['navbar-link-text']}>{label}</span>
          </Link>
        ))}
        <div className={styles['navbar-mobile-divider']} />
        {podeCriarEvento && (
          <Link to="/criar-evento" className={cn(styles['btn-nav-create'], styles['btn-nav-create--mobile'])} onClick={() => setMobileOpen(false)}>
            <Plus size={15} strokeWidth={2} aria-hidden />
            <span>Criar Evento</span>
          </Link>
        )}
        <Link to={contaLink} className={styles['navbar-mobile-link']} onClick={() => setMobileOpen(false)}>
          <User size={18} strokeWidth={2} aria-hidden />
          <span>{contaLabel}</span>
        </Link>
      </div>
    </nav>
  );
}
