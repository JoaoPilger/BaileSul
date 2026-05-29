import React from 'react';
import { Link } from 'react-router-dom';
import { User } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import './HeaderCal.css';

export default function HeaderCal() {
  const { isAuthenticated } = useAuth();
  const contaLink = isAuthenticated ? '/perfil' : '/login';
  const ariaLabel = isAuthenticated ? 'Minha conta' : 'Entrar';

  return (
    <header className="cal-header">
      <div className="cal-header-inner">
        <Link to="/" className="cal-logo-link" aria-label="BaileSul">
          <img src="/imagens/BaileSul.png" alt="BaileSul" className="cal-logo-img" />
        </Link>
        <Link to={contaLink} className="cal-user-btn" aria-label={ariaLabel}>
          <User size={20} strokeWidth={1.8} />
        </Link>
      </div>
    </header>
  );
}
