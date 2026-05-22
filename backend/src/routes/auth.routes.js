const router = require('express').Router();
const { register, login, logout } = require('../controllers/auth.controller');

// RF01 – Cadastro
router.post('/register', register);

// RF02 – Login
router.post('/login', login);

// RF03 – Logout / revogação de token
router.post('/logout', logout);
router.post('/logout/:id', logout);

module.exports = router;
