-- Migration: adiciona forma_pagamento e nome_retirada à tabela reservas
-- Execute este script UMA VEZ no banco de dados PostgreSQL.

ALTER TABLE reservas
  ADD COLUMN IF NOT EXISTS forma_pagamento VARCHAR(20) DEFAULT 'presencial',
  ADD COLUMN IF NOT EXISTS nome_retirada   VARCHAR(120);
