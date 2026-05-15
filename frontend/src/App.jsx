import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import Cadastro from './paginas/login_cadastro/cadastro.jsx'
import Login from './paginas/login_cadastro/login.jsx'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/cadastro" element={<Cadastro />} />
        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
