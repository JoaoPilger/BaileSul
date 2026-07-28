-- ============================================================
--  BaileSul – Migration v6
--  Adiciona capacidade_maxima em eventos
-- ============================================================

ALTER TABLE eventos
  ADD COLUMN IF NOT EXISTS capacidade_maxima INT
    CONSTRAINT chk_capacidade_maxima CHECK (
      capacidade_maxima IS NULL OR capacidade_maxima >= 1
    );

-- Comentário de auditoria
COMMENT ON COLUMN eventos.capacidade_maxima IS
  'Capacidade máxima de ingressos do evento. NULL = sem limite definido.';
