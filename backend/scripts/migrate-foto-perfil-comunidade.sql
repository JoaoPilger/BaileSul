-- Migration: adiciona foto_perfil_url à tabela perfis_comunidades
-- Execute este script UMA VEZ no banco de dados PostgreSQL.

ALTER TABLE perfis_comunidades
  ADD COLUMN IF NOT EXISTS foto_perfil_url VARCHAR(500);

ALTER TABLE perfis_comunidades DROP CONSTRAINT IF EXISTS chk_comunidade_foto_perfil_url;
ALTER TABLE perfis_comunidades ADD CONSTRAINT chk_comunidade_foto_perfil_url CHECK (
  foto_perfil_url IS NULL
  OR foto_perfil_url ~ '^https?://'
  OR foto_perfil_url ~ '^/media/'
);
