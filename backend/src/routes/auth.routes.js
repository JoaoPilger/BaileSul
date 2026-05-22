const router = require('express').Router();
const { register, login } = require('../controllers/auth.controller');

// RF01 – Cadastro
router.post('/register', register);

// RF02 – Login
router.post('/login', login);

module.exports = router;