const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const { validarCNPJ, geocodificarEndereco } = require('../services/external.service');

const inserirTokenAtivo = async (client, usuario_id, token) => {
  const decoded = jwt.decode(token);
  if (!decoded?.exp) {
    throw new Error('Não foi possível extrair exp do token JWT');
  }

  const expiresAt = new Date(decoded.exp * 1000);
  await client.query(
    'INSERT INTO auth_tokens (usuario_id, token, expires_at) VALUES ($1, $2, $3)',
    [usuario_id, token, expiresAt]
  );
};

/**
 * Valida formato básico de e-mail.
 */
const emailValido = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

/**
 * Valida política mínima de senha: ao menos 8 caracteres,
 * uma letra e um número.
 */
const senhaValida = (senha) => senha.length >= 8 && /[a-zA-Z]/.test(senha) && /\d/.test(senha);

/**
 * POST /api/auth/register
 * RF01 – Cadastro de usuários: pessoal | banda | comunidade
 * RF04 – Valida CNPJ via OpenCNPJ para banda e comunidade
 */
const register = async (req, res) => {
  const { email, senha, tipo, perfil } = req.body;

  // --- Validações iniciais (antes de abrir transação) ---

  if (!email || !senha || !tipo || !perfil) {
    return res.status(400).json({ error: 'Campos obrigatórios: email, senha, tipo, perfil' });
  }

  // Normalização de e-mail
  const emailNorm = email.trim().toLowerCase();

  if (!emailValido(emailNorm)) {
    return res.status(400).json({ error: 'Formato de e-mail inválido' });
  }

  if (!senhaValida(senha)) {
    return res.status(400).json({
      error: 'A senha deve ter ao menos 8 caracteres, incluindo letras e números',
    });
  }

  const tiposValidos = ['pessoal', 'banda', 'comunidade'];
  if (!tiposValidos.includes(tipo)) {
    return res.status(400).json({ error: `Tipo inválido. Use: ${tiposValidos.join(', ')}` });
  }

  // RF04 – Banda e comunidade precisam de CNPJ
  if ((tipo === 'banda' || tipo === 'comunidade') && !perfil.cnpj) {
    return res.status(400).json({ error: 'CNPJ obrigatório para banda e comunidade' });
  }

  // --- Validação OpenCNPJ (assíncrona, antes da transação) ---
  let cnpjValidado = false;
  if (tipo === 'banda' || tipo === 'comunidade') {
    const resultado = await validarCNPJ(perfil.cnpj);
    cnpjValidado = resultado.valido;
    // Não bloqueamos o cadastro se a API externa falhar,
    // mas registramos o status de validação.
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Verificar e-mail duplicado
    const emailExiste = await client.query(
      'SELECT id FROM usuarios WHERE email = $1',
      [emailNorm]
    );
    if (emailExiste.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Email já cadastrado' });
    }

    // Hash da senha
    const senha_hash = await bcrypt.hash(senha, 10);

    // INSERT em usuarios
    const { rows } = await client.query(
      'INSERT INTO usuarios (email, senha_hash, tipo) VALUES ($1, $2, $3) RETURNING id',
      [emailNorm, senha_hash, tipo]
    );
    const usuario_id = rows[0].id;

    // INSERT no perfil correspondente
    if (tipo === 'pessoal') {
      const { nome, cidade, estado } = perfil;
      if (!nome || nome.trim().length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Campo obrigatório: perfil.nome' });
      }
      await client.query(
        'INSERT INTO perfis_pessoais (usuario_id, nome, cidade, estado) VALUES ($1, $2, $3, $4)',
        [usuario_id, nome.trim(), cidade || null, estado || null]
      );

    } else if (tipo === 'banda') {
      const { nome_artistico, estilo_musical, descricao, cnpj, whatsapp, video_url } = perfil;
      if (!nome_artistico || nome_artistico.trim().length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Campo obrigatório: perfil.nome_artistico' });
      }
      await client.query(
        `INSERT INTO perfis_bandas
           (usuario_id, nome_artistico, estilo_musical, descricao, cnpj, cnpj_validado, whatsapp, video_url)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          usuario_id,
          nome_artistico.trim(),
          estilo_musical || null,
          descricao || null,
          cnpj,
          cnpjValidado,
          whatsapp || null,
          video_url || null,
        ]
      );

    } else if (tipo === 'comunidade') {
      const { nome_entidade, descricao, cnpj, whatsapp, endereco, cidade, estado } = perfil;
      if (!nome_entidade || nome_entidade.trim().length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Campo obrigatório: perfil.nome_entidade' });
      }

      // Geocodificação do endereço da comunidade
      const enderecoCompleto = [endereco, cidade, estado, 'Brasil'].filter(Boolean).join(', ');
      const coords = await geocodificarEndereco(enderecoCompleto);

      await client.query(
        `INSERT INTO perfis_comunidades
           (usuario_id, nome_entidade, descricao, cnpj, cnpj_validado, whatsapp,
            endereco, cidade, estado, latitude, longitude)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
        [
          usuario_id,
          nome_entidade.trim(),
          descricao || null,
          cnpj,
          cnpjValidado,
          whatsapp || null,
          endereco || null,
          cidade || null,
          estado || null,
          coords?.latitude ?? null,
          coords?.longitude ?? null,
        ]
      );
    }

    const token = jwt.sign(
      { id: usuario_id, tipo },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    await inserirTokenAtivo(client, usuario_id, token);
    await client.query('COMMIT');

    return res.status(201).json({
      message: 'Usuário cadastrado com sucesso',
      token,
      tipo,
      usuario_id,
      email: emailNorm,
      cnpj_validado: cnpjValidado,
    });

  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') {
      return res.status(409).json({ error: 'CNPJ já cadastrado' });
    }
    console.error('Erro no register:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  } finally {
    client.release();
  }
};

/**
 * POST /api/auth/login
 * RF02 – Login com geração de token JWT
 */
const login = async (req, res) => {
  const { email, senha } = req.body;

  if (!email || !senha) {
    return res.status(400).json({ error: 'Campos obrigatórios: email, senha' });
  }

  const emailNorm = email.trim().toLowerCase();

  try {
    const { rows } = await pool.query(
      'SELECT id, senha_hash, tipo FROM usuarios WHERE email = $1',
      [emailNorm]
    );

    // Mensagem genérica para não vazar existência de e-mail
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Credenciais inválidas' });
    }

    const usuario = rows[0];
    const senhaCorreta = await bcrypt.compare(senha, usuario.senha_hash);

    if (!senhaCorreta) {
      return res.status(401).json({ error: 'Credenciais inválidas' });
    }

    // RF05 – Token JWT com id e tipo (RBAC)
    const token = jwt.sign(
      { id: usuario.id, tipo: usuario.tipo },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    await inserirTokenAtivo(pool, usuario.id, token);

    return res.json({
      token,
      tipo: usuario.tipo,
      usuario_id: usuario.id,
      email: emailNorm,
    });

  } catch (err) {
    console.error('Erro no login:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

const logout = async (req, res) => {
  const authHeader = req.headers.authorization;
  const tokenId = req.params.id ? parseInt(req.params.id, 10) : null;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(400).json({ error: 'Token não fornecido' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const query = tokenId
      ? 'UPDATE auth_tokens SET deleted_at = NOW() WHERE id = $1 AND token = $2 AND usuario_id = $3 AND deleted_at IS NULL RETURNING id'
      : 'UPDATE auth_tokens SET deleted_at = NOW() WHERE token = $1 AND usuario_id = $2 AND deleted_at IS NULL RETURNING id';

    const params = tokenId ? [tokenId, token, decoded.id] : [token, decoded.id];
    const { rows } = await pool.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Token não encontrado ou já revogado' });
    }

    return res.json({ message: 'Logout realizado com sucesso' });
  } catch (err) {
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token inválido ou expirado' });
    }
    console.error('Erro no logout:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = { register, login, logout };
