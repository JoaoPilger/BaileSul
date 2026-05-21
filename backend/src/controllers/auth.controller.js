const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

/**
 * POST /api/auth/login
 * Body: { email, senha }
 */
const login = async (req, res) => {
  const { email, senha } = req.body;

  if (!email || !senha) {
    return res.status(400).json({ error: 'E-mail e senha são obrigatórios.' });
  }

  try {
    const { rows } = await pool.query(
      'SELECT id, email, senha_hash, tipo FROM usuarios WHERE email = $1',
      [email.trim().toLowerCase()],
    );

    if (rows.length === 0) {
      return res.status(401).json({ error: 'E-mail ou senha incorretos.' });
    }

    const usuario = rows[0];
    const senhaValida = await bcrypt.compare(senha, usuario.senha_hash);

    if (!senhaValida) {
      return res.status(401).json({ error: 'E-mail ou senha incorretos.' });
    }

    const token = jwt.sign(
      { id: usuario.id, tipo: usuario.tipo },
      process.env.JWT_SECRET,
      { expiresIn: '7d' },
    );

    return res.json({
      token,
      id: usuario.id,
      email: usuario.email,
      tipo: usuario.tipo,
    });
  } catch (err) {
    console.error('Erro no login:', err.message);
    return res.status(500).json({ error: 'Erro ao realizar login.' });
  }
};

module.exports = { login };
