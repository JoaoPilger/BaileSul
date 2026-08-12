import { Link } from 'react-router-dom';
import { MapPin } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { getNavConfig } from '../layout/layoutHelpers';
import { cn } from '../../utils/cn';
import shared from '../../styles/shared.module.css';
import styles from './Footer.module.css';

export default function Footer() {
  const { usuario } = useAuth();
  const { links, podeCriarEvento } = getNavConfig(usuario?.tipo);
  const contaLink = usuario ? '/configuracoes' : '/login';

  const navItems = [
    { to: '/eventos', label: 'Eventos' },
    ...links
      .filter((l) => l.to.startsWith('/meus-'))
      .map((l) => ({ to: l.to, label: l.label })),
    ...(podeCriarEvento ? [{ to: '/criar-evento', label: 'Criar Evento' }] : []),
    { to: contaLink, label: 'Perfil' },
  ];

  const leftItems = navItems.slice(0, 3);
  const rightItems = navItems.slice(3, 6);

  return (
    <footer className={styles.footer}>
      <div className={cn(shared.container, styles['footer-grid'])}>
        <div className={styles['footer-brand']}>
          <Link to="/" className={styles['footer-logo-link']} aria-label="BaileSul">
            <img
              src="/imagens/BaileSul.png"
              alt="BaileSul"
              className={styles['footer-logo-img']}
              decoding="async"
            />
          </Link>
          <p className={styles['footer-tagline']}>
            A plataforma de eventos da região AMAUC. Conectando bandas, comunidades e público.
          </p>
        </div>

        <div className={styles['footer-nav-block']}>
          <h4 className={styles['footer-heading']}>Navegação</h4>
          <nav className={styles['footer-nav']}>
            <div className={styles['footer-nav-col']}>
              {leftItems.map((item) => (
                <Link key={item.to} to={item.to}>{item.label}</Link>
              ))}
            </div>
            <div className={styles['footer-nav-col']}>
              {rightItems.map((item) => (
                <Link key={item.to} to={item.to}>{item.label}</Link>
              ))}
            </div>
          </nav>
        </div>

        <div className={styles['footer-region-block']}>
          <h4 className={styles['footer-heading']}>Região AMAUC</h4>
          <p className={styles['footer-region']}>
            <MapPin size={13} />
            13 municípios · Santa Catarina
          </p>
        </div>
      </div>

      <div className={styles['footer-bottom']}>
        <span>© BaileSul – Todos os direitos reservados.</span>
      </div>
    </footer>
  );
}
