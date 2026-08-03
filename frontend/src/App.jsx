import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider, useAuth } from './contexts/AuthContext'
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
import EventoDashboard from './paginas/evento/dashboard_evento.jsx'
import Bandas from './paginas/bandas/bandas.jsx'
import Comunidades from './paginas/comunidades/comunidades.jsx'
import VitrineComunidade from './paginas/vitrine_comunidade/vitrine_comunidade.jsx'
import VitrineBanda from './paginas/vitrine_banda/vitrine_banda.jsx'
import Vendedores from './paginas/vendedores/vendedores.jsx'
import Configuracoes from './paginas/configuracoes/configuracoes.jsx'
import Pagamentos from './paginas/pagamentos/pagamentos.jsx'
import MeusIngressosPage from './paginas/meus_ingressos/meusIngressos.jsx'
import MeusEventosComunidade from './paginas/meus_eventos_comunidade/meus_eventos_comunidade.jsx'
import Painel from './paginas/painel/painel.jsx'
import ContratosPage from './paginas/contratos/contratos.jsx'
import MeusEventosBanda from './paginas/meus_eventos_banda/meus_eventos_banda.jsx'

import EditarPerfil from './paginas/editar_perfil/editar_perfil.jsx'

// "/" mostra a home pública normalmente para visitantes e usuários "pessoal".
// Banda e comunidade logam pra trabalhar, não pra navegar a vitrine pública
// — então são direcionados direto pro dashboard deles.
function RootGate() {
  const { usuario } = useAuth()
  if (usuario?.tipo === 'banda' || usuario?.tipo === 'comunidade') {
    return <Navigate to="/painel" replace />
  }
  return <Home />
}

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<RootGate />} />
          <Route path="/login" element={<Login />} />
          <Route path="/cadastro" element={<CadastroSelecao />} />
          <Route path="/cadastro/pessoal" element={<CadastroPessoal />} />
          <Route path="/cadastro/banda" element={<CadastroBanda />} />
          <Route path="/cadastro/comunidade" element={<CadastroComunidade />} />
          <Route path="/calendario" element={<Calendario />} />
          <Route path="/painel" element={<Painel />} />
          <Route path="/contratos" element={<ContratosPage />} />
          <Route path="/criar-evento" element={<CriarEvento />} />
          <Route path="/eventos" element={<Eventos />} />
          <Route path="/eventos/:id" element={<Evento />} />
          <Route path="/eventos/:id/dashboard" element={<EventoDashboard />} />
          <Route path="/bandas" element={<Bandas />} />
          <Route path="/comunidades" element={<Comunidades />} />
          <Route path="/comunidades/:id" element={<VitrineComunidade />} />
          <Route path="/bandas/:id" element={<VitrineBanda />} />
          <Route path="/vendedores" element={<Vendedores />} />
          <Route path="/configuracoes" element={<Configuracoes />} />
          <Route path="/editar-perfil" element={<EditarPerfil />} />
          <Route path="/pagamentos" element={<Pagamentos />} />
          <Route path="/meus-ingressos" element={<MeusIngressosPage />} />
          <Route path="/meus-eventos" element={<MeusEventosComunidade />} />
          <Route path="/meus-eventos/banda" element={<MeusEventosBanda />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}

export default App
