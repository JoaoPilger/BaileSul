import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import Calendario from './paginas/calendario/calendario.jsx'
import Cadastro from './paginas/login_cadastro/cadastro.jsx'
import Home from './paginas/home/home.jsx'
import Login from './paginas/login_cadastro/login.jsx'
import CriarEvento from './paginas/criar_evento/criar_evento.jsx'

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/cadastro" element={<Cadastro />} />
          <Route path="/calendario" element={<Calendario />} />
          <Route path="/criar-evento" element={<CriarEvento />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}

export default App
