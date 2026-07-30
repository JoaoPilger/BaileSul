import { Link } from 'react-router-dom';
import { User } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import styles from './HeaderCal.module.css';

export default function HeaderCal() {
  const { isAuthenticated } = useAuth();
  const contaLink = isAuthenticated ? '/perfil' : '/login';
  const ariaLabel = isAuthenticated ? 'Minha conta' : 'Entrar';

  return (
    <header className={styles['cal-header']}>
      <div className={styles['cal-header-inner']}>
        <Link to="/" className={styles['cal-logo-link']} aria-label="BaileSul">
          <img src="/imagens/BaileSul.png" alt="BaileSul" className={styles['cal-logo-img']} />
        </Link>
        <Link to={contaLink} className={styles['cal-user-btn']} aria-label={ariaLabel}>
          <User size={20} strokeWidth={1.8} />
        </Link>
      </div>
    </header>
  );
}
