-- ============================================================
--  BaileSul – Migration v9: sistema de notificações
-- ============================================================

CREATE TABLE IF NOT EXISTS notificacoes (
  id          BIGSERIAL PRIMARY KEY,
  usuario_id  BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  tipo        VARCHAR(40)  NOT NULL,
  titulo      VARCHAR(150) NOT NULL,
  mensagem    VARCHAR(500),
  lida        BOOLEAN NOT NULL DEFAULT FALSE,
  payload     JSONB,
  criado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notificacoes_usuario
  ON notificacoes (usuario_id, criado_em DESC);

CREATE INDEX IF NOT EXISTS idx_notificacoes_usuario_nao_lidas
  ON notificacoes (usuario_id)
  WHERE lida = FALSE;
