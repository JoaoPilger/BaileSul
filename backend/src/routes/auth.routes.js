const router = require('express').Router();
const { register, login, logout, alterarSenha, buscarPerfilPessoal, atualizarPerfilPessoal } = require('../controllers/auth.controller');
const { autenticar, autorizar } = require('../middlewares/auth.middleware');

// RF01 – Cadastro
router.post('/register', register);

// RF02 – Login
router.post('/login', login);

// RF03 – Logout / revogação de token (requer token válido)
router.post('/logout',     autenticar, logout);
router.post('/logout/:id', autenticar, logout);

// Alterar senha (requer senha atual + token válido)
router.put('/senha', autenticar, alterarSenha);

// Perfil pessoal (requer conta tipo pessoal)
router.get('/me/perfil', autenticar, autorizar('pessoal'), buscarPerfilPessoal);
router.put('/me/perfil', autenticar, autorizar('pessoal'), atualizarPerfilPessoal);

module.exports = router;