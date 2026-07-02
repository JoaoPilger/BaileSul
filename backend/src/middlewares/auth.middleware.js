const jwt = require('jsonwebtoken');
const pool = require('../config/database');

/**
 * Verifica se o token JWT é válido e injeta req.usuario = { id, tipo }
 */
const autenticar = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token não fornecido' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const { rows } = await pool.query(
      'SELECT id FROM auth_tokens WHERE token = $1 AND usuario_id = $2 AND expires_at > NOW() AND deleted_at IS NULL',
      [token, decoded.id]
    );

    if (rows.length === 0) {
      return res.status(401).json({ error: 'Token inválido ou expirado' });
    }

    req.usuario = decoded; // { id, tipo }
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Token inválido ou expirado' });
  }
};

/**
 * Restringe acesso por tipo de usuário (RBAC).
 * Uso: autorizar('comunidade', 'vendedor')
 */
const autorizar = (...tipos) => {
  return (req, res, next) => {
    if (!tipos.includes(req.usuario.tipo)) {
      return res.status(403).json({ error: 'Acesso não autorizado para este perfil' });
    }
    next();
  };
};

/**
 * Igual a `autenticar`, mas não bloqueia a requisição se não houver token
 * (ou se o token for inválido). Se o token for válido, injeta req.usuario;
 * caso contrário, req.usuario fica undefined e a rota segue como acesso público.
 * Uso: rotas públicas que precisam saber "quem é" o usuário quando logado
 * (ex.: dono do recurso vendo uma pré-visualização).
 */
const autenticarOpcional = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const { rows } = await pool.query(
      'SELECT id FROM auth_tokens WHERE token = $1 AND usuario_id = $2 AND expires_at > NOW() AND deleted_at IS NULL',
      [token, decoded.id]
    );

    if (rows.length > 0) {
      req.usuario = decoded; // { id, tipo }
    }
  } catch (err) {
    // token inválido/expirado: segue como acesso público, sem req.usuario
  }

  next();
};

module.exports = { autenticar, autorizar, autenticarOpcional };