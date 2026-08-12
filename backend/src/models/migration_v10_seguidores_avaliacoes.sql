-- ============================================================
--  Migration v10 — Seguidores e avaliações reais de perfil
--  (substitui o antigo "seguir"/"avaliar" que vivia só no
--  localStorage do frontend)
-- ============================================================

DO $$ BEGIN
  CREATE TYPE dono_perfil AS ENUM ('banda', 'comunidade');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS perfil_seguidores (
  id          BIGSERIAL PRIMARY KEY,
  usuario_id  BIGINT      NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  dono_tipo   dono_perfil NOT NULL,
  dono_id     BIGINT      NOT NULL,
  criado_em   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (usuario_id, dono_tipo, dono_id)
);

CREATE INDEX IF NOT EXISTS idx_perfil_seguidores_dono ON perfil_seguidores (dono_tipo, dono_id);

CREATE TABLE IF NOT EXISTS perfil_avaliacoes (
  id            BIGSERIAL PRIMARY KEY,
  usuario_id    BIGINT      NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  dono_tipo     dono_perfil NOT NULL,
  dono_id       BIGINT      NOT NULL,
  nota          SMALLINT    NOT NULL,
  criado_em     TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (usuario_id, dono_tipo, dono_id),
  CONSTRAINT chk_perfil_avaliacao_nota CHECK (nota BETWEEN 1 AND 5)
);

CREATE INDEX IF NOT EXISTS idx_perfil_avaliacoes_dono ON perfil_avaliacoes (dono_tipo, dono_id);

DO $$ BEGIN
  CREATE TRIGGER trg_perfil_avaliacoes_atualizado_em
    BEFORE UPDATE ON perfil_avaliacoes
    FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
