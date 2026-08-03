-- ============================================================
--  BaileSul – Migration v8: foto_perfil_url para bandas e comunidades
-- ============================================================

ALTER TABLE perfis_bandas
  ADD COLUMN IF NOT EXISTS foto_perfil_url VARCHAR(500);

ALTER TABLE perfis_comunidades
  ADD COLUMN IF NOT EXISTS foto_perfil_url VARCHAR(500);
