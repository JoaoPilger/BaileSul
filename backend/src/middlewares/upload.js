/**
 * Middleware de upload local com Multer.
 *
 * Estrutura de pastas criada automaticamente dentro de src/media/:
 *   src/media/eventos/capas/        → foto_capa_url de eventos
 *   src/media/eventos/midias/       → evento_midias (imagens/vídeos)
 *   src/media/perfis/bandas/        → video_url e perfil_midias de bandas
 *   src/media/perfis/comunidades/   → perfil_midias de comunidades
 *
 * O campo `url` salvo no banco segue o padrão:
 *   /media/<subpasta>/<filename>
 * e é servido estaticamente pelo Express (configurar app.use('/media', ...)).
 */

const path = require('path');
const fs   = require('fs');
const multer = require('multer');

// Raiz da pasta media — resolve para src/media independente de onde o processo roda
const MEDIA_ROOT = path.resolve(__dirname, '..', 'media');

/**
 * Garante que o diretório exista antes de o multer tentar escrever nele.
 */
const garantirDir = (dir) => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
};

/**
 * Tipos MIME aceitos e extensões correspondentes.
 */
const MIME_IMAGENS = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const MIME_VIDEOS  = ['video/mp4', 'video/webm', 'video/ogg', 'video/quicktime'];
const MIME_MIDIA   = [...MIME_IMAGENS, ...MIME_VIDEOS];

const extDeMime = (mime) => {
  const mapa = {
    'image/jpeg':    '.jpg',
    'image/png':     '.png',
    'image/webp':    '.webp',
    'image/gif':     '.gif',
    'video/mp4':     '.mp4',
    'video/webm':    '.webm',
    'video/ogg':     '.ogv',
    'video/quicktime': '.mov',
  };
  return mapa[mime] ?? path.extname(mime);
};

/**
 * Fábrica de storage: recebe uma função `destDir(req)` que devolve o
 * caminho absoluto da subpasta onde o arquivo será salvo.
 */
const criarStorage = (destDir) =>
  multer.diskStorage({
    destination(req, file, cb) {
      const dir = destDir(req);
      garantirDir(dir);
      cb(null, dir);
    },
    filename(req, file, cb) {
      const ts  = Date.now();
      const rnd = Math.random().toString(36).slice(2, 8);
      const ext = extDeMime(file.mimetype);
      cb(null, `${ts}_${rnd}${ext}`);
    },
  });

/**
 * Filtro de tipo MIME genérico.
 */
const filtroMime = (mimesAceitos) => (req, file, cb) => {
  if (mimesAceitos.includes(file.mimetype)) {
    cb(null, true);
    return;
  }

  // Alguns clientes mobile enviam imagens como application/octet-stream.
  if (
    file.mimetype === 'application/octet-stream'
    && mimesAceitos === MIME_IMAGENS
  ) {
    cb(null, true);
    return;
  }

  cb(
    Object.assign(new Error(`Tipo de arquivo não permitido: ${file.mimetype}`), {
      status: 415,
    }),
    false
  );
};

// ─────────────────────────────────────────────────────────────
//  Instâncias exportadas
// ─────────────────────────────────────────────────────────────

/**
 * Upload de foto de capa de evento.
 * Campo multipart: "foto_capa"
 * Salva em: src/media/eventos/capas/
 */
const uploadCapaEvento = multer({
  storage: criarStorage(() => path.join(MEDIA_ROOT, 'eventos', 'capas')),
  fileFilter: filtroMime(MIME_IMAGENS),
  limits: { fileSize: 8 * 1024 * 1024 }, // 8 MB
}).single('foto_capa');

/**
 * Upload de mídia de evento (imagem ou vídeo).
 * Campo multipart: "arquivo"
 * Salva em: src/media/eventos/midias/
 */
const uploadMidiaEvento = multer({
  storage: criarStorage(() => path.join(MEDIA_ROOT, 'eventos', 'midias')),
  fileFilter: filtroMime(MIME_MIDIA),
  limits: { fileSize: 200 * 1024 * 1024 }, // 200 MB
}).single('arquivo');

/**
 * Upload de mídia de perfil (banda ou comunidade).
 * Campo multipart: "arquivo"
 * A subpasta é determinada pelo parâmetro de rota :dono_tipo
 * (banda → perfis/bandas, comunidade → perfis/comunidades).
 */
const uploadMidiaPerfil = multer({
  storage: criarStorage((req) => {
    const tipo = req.params?.dono_tipo ?? req.usuario?.tipo ?? 'bandas';
    const sub  = tipo === 'comunidade' ? 'comunidades' : 'bandas';
    return path.join(MEDIA_ROOT, 'perfis', sub);
  }),
  fileFilter: filtroMime(MIME_MIDIA),
  limits: { fileSize: 200 * 1024 * 1024 }, // 200 MB
}).single('arquivo');

// ─────────────────────────────────────────────────────────────
//  Helper: converte caminho absoluto → URL relativa /media/...
// ─────────────────────────────────────────────────────────────

/**
 * Recebe o caminho absoluto gerado pelo multer e devolve a URL
 * persistida no banco (http(s) absoluta quando possível).
 */
const caminhoParaUrl = (filePath, req) => {
  const rel = path.relative(MEDIA_ROOT, filePath);
  const pathUrl = '/media/' + rel.split(path.sep).join('/');

  if (req) {
    const proto = req.headers['x-forwarded-proto'] || req.protocol || 'http';
    const host = req.headers['x-forwarded-host'] || req.get('host');
    if (host) {
      return `${proto}://${host}${pathUrl}`;
    }
  }

  const base = process.env.API_PUBLIC_URL
    || process.env.CLIENT_URL?.split(',')[0]?.trim();
  if (base) {
    return `${base.replace(/\/$/, '')}${pathUrl}`;
  }

  return pathUrl;
};

// ─────────────────────────────────────────────────────────────
//  Middleware de tratamento de erros do Multer
// ─────────────────────────────────────────────────────────────

/**
 * Deve ser registrado logo após as rotas que usam upload para
 * converter erros do Multer em respostas JSON padronizadas.
 *
 * Uso no router:
 *   router.use(uploadErrorHandler);
 */
const uploadErrorHandler = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    const mensagens = {
      LIMIT_FILE_SIZE: 'Arquivo muito grande. Verifique o limite permitido.',
      LIMIT_UNEXPECTED_FILE: 'Campo de arquivo inesperado.',
    };
    return res
      .status(413)
      .json({ error: mensagens[err.code] ?? `Erro no upload: ${err.message}` });
  }
  if (err?.status === 415) {
    return res.status(415).json({ error: err.message });
  }
  next(err);
};

module.exports = {
  uploadCapaEvento,
  uploadMidiaEvento,
  uploadMidiaPerfil,
  caminhoParaUrl,
  uploadErrorHandler,
};