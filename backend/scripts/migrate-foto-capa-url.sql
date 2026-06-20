-- Permite armazenar URLs relativas de upload (/media/...) em foto_capa_url.
ALTER TABLE eventos DROP CONSTRAINT IF EXISTS chk_foto_capa_url;
ALTER TABLE eventos ADD CONSTRAINT chk_foto_capa_url CHECK (
  foto_capa_url IS NULL
  OR foto_capa_url ~ '^https?://'
  OR foto_capa_url ~ '^/media/'
);
