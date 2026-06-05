import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import Calendario from './paginas/calendario/calendario.jsx'
import CadastroSelecao from './paginas/cadastro/cadastroSelecao.jsx'
import CadastroPessoal from './paginas/cadastro/cadastroPessoal.jsx'
import CadastroBanda from './paginas/cadastro/cadastroBanda.jsx'
import CadastroComunidade from './paginas/cadastro/cadastroComunidade.jsx'
import Home from './paginas/home/home.jsx'
import Login from './paginas/login/login.jsx'
import CriarEvento from './paginas/criar_evento/criar_evento.jsx'
import Eventos from './paginas/eventos/eventos.jsx'
import Evento from './paginas/evento/evento.jsx'

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/cadastro" element={<CadastroSelecao />} />
          <Route path="/cadastro/pessoal" element={<CadastroPessoal />} />
          <Route path="/cadastro/banda" element={<CadastroBanda />} />
          <Route path="/cadastro/comunidade" element={<CadastroComunidade />} />
          <Route path="/calendario" element={<Calendario />} />
          <Route path="/criar-evento" element={<CriarEvento />} />
          <Route path="/eventos" element={<Eventos />} />
          <Route path="/eventos/:id" element={<Evento />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}

export default App
