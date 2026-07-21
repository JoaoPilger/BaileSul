-- Migration: adiciona foto_perfil_url à tabela perfis_bandas
-- Execute este script UMA VEZ no banco de dados PostgreSQL.

ALTER TABLE perfis_bandas
  ADD COLUMN IF NOT EXISTS foto_perfil_url VARCHAR(500);

ALTER TABLE perfis_bandas DROP CONSTRAINT IF EXISTS chk_banda_foto_perfil_url;
ALTER TABLE perfis_bandas ADD CONSTRAINT chk_banda_foto_perfil_url CHECK (
  foto_perfil_url IS NULL
  OR foto_perfil_url ~ '^https?://'
  OR foto_perfil_url ~ '^/media/'
);
