-- ============================================================
--  Migration v11 — Unifica os tipos de evento musicais
--  (musical_gaucha / musical_bandinha viram um único "musical";
--  o estilo musical continua existindo, mas só como campo da
--  banda em perfis_bandas.estilo_musical — não mais como
--  subcategoria do evento)
-- ============================================================

-- A constraint antiga não permite o valor 'musical' sozinho, então precisa
-- cair ANTES do UPDATE (senão o próprio UPDATE de migração seria rejeitado).
ALTER TABLE eventos DROP CONSTRAINT IF EXISTS chk_eventos_tipo_evento;

UPDATE eventos SET tipo_evento = 'musical'
WHERE tipo_evento IN ('musical_gaucha', 'musical_bandinha');

ALTER TABLE eventos ALTER COLUMN tipo_evento SET DEFAULT 'musical';

ALTER TABLE eventos ADD CONSTRAINT chk_eventos_tipo_evento CHECK (
  tipo_evento IN ('musical', 'almoco', 'bingo', 'expos', 'futebol')
);
