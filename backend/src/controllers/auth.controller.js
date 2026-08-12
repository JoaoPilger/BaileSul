const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const { validarCNPJ, geocodificarEndereco } = require('../services/external.service');
const { limparTokensExpirados } = require('../services/token.service');
const { whatsappValido, cnpjFormatoValido } = require('../utils/validators');

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

  if ((tipo === 'banda' || tipo === 'comunidade') && !cnpjFormatoValido(perfil.cnpj)) {
    return res.status(400).json({ error: 'CNPJ deve estar no formato XX.XXX.XXX/XXXX-XX' });
  }

  if (perfil.whatsapp && !whatsappValido(perfil.whatsapp)) {
    return res.status(400).json({
      error: 'WhatsApp inválido. Use 10 a 15 dígitos (ex.: 5547999999999)',
    });
  }

  // --- Validação OpenCNPJ (assíncrona, antes da transação) ---
  let cnpjValidado = false;
  if (tipo === 'banda' || tipo === 'comunidade') {
    const resultado = await validarCNPJ(perfil.cnpj);
    cnpjValidado = resultado.valido;

    // Bloqueia quando a API respondeu e o CNPJ é inválido/inativo
    if (resultado.apiDisponivel && !resultado.valido) {
      return res.status(400).json({
        error: 'CNPJ inválido ou inativo na Receita Federal',
      });
    }
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
      const { nome_entidade, descricao, cnpj, whatsapp, endereco, cidade, estado, latitude, longitude } = perfil;
      if (!nome_entidade || nome_entidade.trim().length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Campo obrigatório: perfil.nome_entidade' });
      }

      const latManual = latitude !== undefined && latitude !== null ? Number(latitude) : null;
      const lonManual = longitude !== undefined && longitude !== null ? Number(longitude) : null;
      const coordsManuaisValidas =
        latManual !== null &&
        lonManual !== null &&
        Number.isFinite(latManual) &&
        Number.isFinite(lonManual) &&
        latManual >= -90 &&
        latManual <= 90 &&
        lonManual >= -180 &&
        lonManual <= 180;

      // Geocodificação do endereço da comunidade
      const enderecoCompleto = [endereco, cidade, estado, 'Brasil'].filter(Boolean).join(', ');
      const coords = coordsManuaisValidas ? null : await geocodificarEndereco(enderecoCompleto);

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
          coordsManuaisValidas ? latManual : coords?.latitude ?? null,
          coordsManuaisValidas ? lonManual : coords?.longitude ?? null,
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

  // Busca o usuário antes de abrir transação (operação somente-leitura)
  let usuario;
  try {
    const { rows } = await pool.query(
      'SELECT id, senha_hash, tipo FROM usuarios WHERE email = $1',
      [emailNorm]
    );

    // Mensagem genérica para não vazar existência de e-mail
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Credenciais inválidas' });
    }

    usuario = rows[0];
  } catch (err) {
    console.error('Erro no login (busca):', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }

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

  // Registra o token em transação: se o INSERT falhar o token não é retornado
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await inserirTokenAtivo(client, usuario.id, token);
    await client.query('COMMIT');

    return res.json({ token, tipo: usuario.tipo, usuario_id: usuario.id });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erro no login (token):', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  } finally {
    client.release();
  }
};

/**
 * POST /api/auth/logout
 * POST /api/auth/logout/:id
 * RF03 – Revoga o token atual (ou um token específico por id).
 * Requer middleware autenticar — req.usuario e o token já foram validados.
 */
const logout = async (req, res) => {
  const token = req.headers.authorization.split(' ')[1]; // garantido pelo middleware
  const usuario_id = req.usuario.id;
  const tokenId = req.params.id ? parseInt(req.params.id, 10) : null;

  if (tokenId && isNaN(tokenId)) {
    return res.status(400).json({ error: 'Parâmetro :id inválido' });
  }

  try {
    const query = tokenId
      ? 'UPDATE auth_tokens SET deleted_at = NOW() WHERE id = $1 AND token = $2 AND usuario_id = $3 AND deleted_at IS NULL RETURNING id'
      : 'UPDATE auth_tokens SET deleted_at = NOW() WHERE token = $1 AND usuario_id = $2 AND deleted_at IS NULL RETURNING id';

    const params = tokenId ? [tokenId, token, usuario_id] : [token, usuario_id];
    const { rows } = await pool.query(query, params);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Token não encontrado ou já revogado' });
    }

    // Limpeza assíncrona de tokens expirados/revogados antigos
    limparTokensExpirados().catch(() => {});

    return res.json({ message: 'Logout realizado com sucesso' });
  } catch (err) {
    console.error('Erro no logout:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PUT /api/auth/senha
 * Altera a senha do usuário autenticado (requer confirmação da senha atual).
 */
const alterarSenha = async (req, res) => {
  const { senha_atual, nova_senha } = req.body;
  const usuario_id = req.usuario.id;

  if (!senha_atual || !nova_senha) {
    return res.status(400).json({ error: 'Campos obrigatórios: senha_atual, nova_senha' });
  }

  if (!senhaValida(nova_senha)) {
    return res.status(400).json({
      error: 'A nova senha deve ter ao menos 8 caracteres, incluindo letras e números',
    });
  }

  try {
    const { rows } = await pool.query(
      'SELECT senha_hash FROM usuarios WHERE id = $1',
      [usuario_id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    const senhaCorreta = await bcrypt.compare(senha_atual, rows[0].senha_hash);
    if (!senhaCorreta) {
      return res.status(401).json({ error: 'Senha atual incorreta' });
    }

    const novaSenhaHash = await bcrypt.hash(nova_senha, 10);
    await pool.query(
      'UPDATE usuarios SET senha_hash = $1 WHERE id = $2',
      [novaSenhaHash, usuario_id]
    );

    return res.json({ message: 'Senha alterada com sucesso' });
  } catch (err) {
    console.error('Erro ao alterar senha:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * GET /api/auth/me/perfil
 * Retorna os dados do perfil pessoal do usuário autenticado.
 */
const buscarPerfilPessoal = async (req, res) => {
  const usuario_id = req.usuario.id;

  try {
    const { rows } = await pool.query(
      'SELECT nome, cidade, estado FROM perfis_pessoais WHERE usuario_id = $1',
      [usuario_id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Perfil não encontrado' });
    }

    return res.json(rows[0]);
  } catch (err) {
    console.error('Erro ao buscar perfil pessoal:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

/**
 * PUT /api/auth/me/perfil
 * Atualiza os dados do perfil pessoal do usuário autenticado.
 */
const atualizarPerfilPessoal = async (req, res) => {
  const usuario_id = req.usuario.id;
  const { nome, cidade, estado } = req.body;

  if (!nome || nome.trim().length === 0) {
    return res.status(400).json({ error: 'Campo obrigatório: nome' });
  }

  try {
    const { rowCount } = await pool.query(
      `UPDATE perfis_pessoais SET
         nome   = $1,
         cidade = $2,
         estado = $3
       WHERE usuario_id = $4`,
      [nome.trim(), cidade || null, estado || null, usuario_id]
    );

    if (rowCount === 0) {
      return res.status(404).json({ error: 'Perfil não encontrado' });
    }

    return res.json({ message: 'Perfil atualizado com sucesso' });
  } catch (err) {
    console.error('Erro ao atualizar perfil pessoal:', err.message);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

module.exports = { register, login, logout, alterarSenha, buscarPerfilPessoal, atualizarPerfilPessoal };
