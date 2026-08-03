import { Link } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import styles from './FooterCal.module.css';

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
    <footer className={styles['cal-footer']}>
      <div className={styles['cal-footer-inner']}>
        <div className={styles['cal-footer-brand']}>
          <Link to="/" aria-label="BaileSul">
            <img src="/imagens/BaileSul.png" alt="BaileSul" className={styles['cal-footer-logo']} />
          </Link>
        </div>

        <div className={styles['cal-footer-copy-block']}>
          <p className={styles['cal-footer-copy']}>© BaileSul – Todos os direitos reservados.</p>
        </div>

        <nav className={styles['cal-footer-nav-block']} aria-label="Navegação do rodapé">
          <h4 className={styles['cal-footer-heading']}>Navegação</h4>
          <div className={styles['cal-footer-nav']}>
            <div className={styles['cal-footer-nav-col']}>
              {footerLinks.slice(0, 3).map((item) => (
                <Link key={item.to} to={item.to}>{item.label}</Link>
              ))}
            </div>
            <div className={styles['cal-footer-nav-col']}>
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
