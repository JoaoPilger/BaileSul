/**
 * Middleware de upload com Multer + Supabase Storage.
 *
 * Os arquivos são recebidos em memória (multer.memoryStorage) e enviados
 * direto para o bucket público "media" no Supabase Storage — nada é
 * gravado em disco local (o disco do Render é efêmero e some a cada deploy).
 *
 * Estrutura de "pastas" (prefixos de objeto) dentro do bucket:
 *   eventos/capas/        → foto_capa_url de eventos
 *   eventos/midias/        → evento_midias (imagens/vídeos)
 *   perfis/bandas/         → foto_perfil_url e perfil_midias de bandas
 *   perfis/comunidades/    → foto_perfil_url e perfil_midias de comunidades
 *
 * Após o upload, `req.file.path` já contém a URL pública final do arquivo
 * no Supabase (mesmo formato de valor que os controllers salvam no banco).
 */

const multer = require('multer');
const { supabase, BUCKET } = require('../config/supabaseStorage');

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
  // O único jeito de chegar aqui com um mime fora do mapa é a exceção de
  // application/octet-stream em filtroMime (alguns clientes mobile mandam
  // imagens assim). Fixar em ".jpg" garante um content-type de imagem
  // quando o arquivo for servido, evitando upload de tipo disfarçado.
  return mapa[mime] ?? '.jpg';
};

/**
 * Storage engine do Multer que envia o arquivo direto para o Supabase
 * Storage, sem tocar em disco local. `destPasta(req)` devolve o prefixo
 * (ex.: "eventos/capas") onde o objeto deve ser salvo dentro do bucket.
 */
class SupabaseStorageEngine {
  constructor(destPasta) {
    this.destPasta = destPasta;
  }

  _handleFile(req, file, cb) {
    const chunks = [];
    file.stream.on('data', (chunk) => chunks.push(chunk));
    file.stream.on('error', (err) => cb(err));
    file.stream.on('end', async () => {
      try {
        const buffer = Buffer.concat(chunks);
        const ts  = Date.now();
        const rnd = Math.random().toString(36).slice(2, 8);
        const ext = extDeMime(file.mimetype);
        const objectPath = `${this.destPasta(req)}/${ts}_${rnd}${ext}`;

        const { error } = await supabase.storage
          .from(BUCKET)
          .upload(objectPath, buffer, { contentType: file.mimetype, upsert: false });
        if (error) return cb(error);

        const { data } = supabase.storage.from(BUCKET).getPublicUrl(objectPath);
        cb(null, { path: data.publicUrl, objectPath, size: buffer.length });
      } catch (err) {
        cb(err);
      }
    });
  }

  _removeFile(req, file, cb) {
    if (!file.objectPath) return cb(null);
    supabase.storage.from(BUCKET).remove([file.objectPath]).then(() => cb(null), cb);
  }
}

const criarStorage = (destPasta) => new SupabaseStorageEngine(destPasta);

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
 * Salva em: eventos/capas/
 */
const uploadCapaEvento = multer({
  storage: criarStorage(() => 'eventos/capas'),
  fileFilter: filtroMime(MIME_IMAGENS),
  limits: { fileSize: 8 * 1024 * 1024 }, // 8 MB
}).single('foto_capa');

// Limite de tamanho de arquivo do plano gratuito do Supabase Storage: 50 MB
// por objeto. Usamos 49 MB para garantir que o erro amigável do multer
// dispare antes de um erro opaco vindo da API do Supabase.
const LIMITE_MIDIA = 49 * 1024 * 1024;

/**
 * Upload de mídia de evento (imagem ou vídeo).
 * Campo multipart: "arquivo"
 * Salva em: eventos/midias/
 */
const uploadMidiaEvento = multer({
  storage: criarStorage(() => 'eventos/midias'),
  fileFilter: filtroMime(MIME_MIDIA),
  limits: { fileSize: LIMITE_MIDIA },
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
    return `perfis/${sub}`;
  }),
  fileFilter: filtroMime(MIME_MIDIA),
  limits: { fileSize: LIMITE_MIDIA },
}).single('arquivo');

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
  if (err) {
    console.error('Erro no upload para o Supabase Storage:', err.message);
    return res.status(502).json({ error: 'Falha ao enviar arquivo para o armazenamento.' });
  }
  next(err);
};

module.exports = {
  uploadCapaEvento,
  uploadMidiaEvento,
  uploadMidiaPerfil,
  uploadErrorHandler,
};
