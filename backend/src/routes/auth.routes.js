const router = require('express').Router();
const { register, login, logout } = require('../controllers/auth.controller');
const { autenticar } = require('../middlewares/auth.middleware');

// RF01 – Cadastro
router.post('/register', register);

// RF02 – Login
router.post('/login', login);

// RF03 – Logout / revogação de token (requer token válido)
router.post('/logout',     autenticar, logout);
router.post('/logout/:id', autenticar, logout);

module.exports = router;