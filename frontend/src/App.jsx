import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import Cadastro from './paginas/login_cadastro/cadastro.jsx'
import Home from './paginas/home/home.jsx'
import Login from './paginas/login_cadastro/login.jsx'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/login" element={<Login />} />
        <Route path="/cadastro" element={<Cadastro />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
