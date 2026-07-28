-- ============================================================
--  BaileSul – Migration v7
--  Adiciona 'rejeitado' ao ENUM status_pagamento
--
--  vendedor.controller.js já grava 'rejeitado' em reservas.status_pagamento
--  e em logs_status_pagamentos.status_novo, mas o ENUM original só definia
--  ('pendente', 'confirmado', 'cancelado'). Sem esse valor, os inserts/updates
--  de rejeição de pagamento falham com "invalid input value for enum".
-- ============================================================

ALTER TYPE status_pagamento ADD VALUE IF NOT EXISTS 'rejeitado';
