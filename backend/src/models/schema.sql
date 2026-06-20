-- ============================================================
--  BaileSul – Schema PostgreSQL  v5
--  Alterações em relação à v4:
--    - auth_tokens: persistência e revogação de JWT
--    - video_url adicionado em perfis_bandas
--    - vendedores: usuario_id passa a ser FK para usuarios
--      com tipo 'pessoal' (papel atribuído pela comunidade).
--      A coluna é NULLABLE para suportar vendedores cadastrados
--      apenas com nome/whatsapp sem conta no sistema.
--    - lat/lng em perfis_comunidades e eventos (geolocalização)
--    - tipo_usuario permanece sem 'vendedor' (papel, não tipo)
--    - cnpj_validado adicionado em perfis_bandas e
--      perfis_comunidades (resultado da validação OpenCNPJ)
-- ============================================================


-- ============================================================
--  Tipos enumerados
-- ============================================================

CREATE TYPE tipo_usuario    AS ENUM ('pessoal', 'banda', 'comunidade');
CREATE TYPE status_evento   AS ENUM ('agendado', 'cancelado', 'finalizado');
CREATE TYPE status_contrato AS ENUM ('pendente', 'aceito', 'recusado');
CREATE TYPE status_pagamento AS ENUM ('pendente', 'confirmado', 'cancelado');
CREATE TYPE tipo_midia      AS ENUM ('imagem', 'video');
CREATE TYPE dono_midia      AS ENUM ('banda', 'comunidade');


-- ============================================================
--  Função de auditoria (trigger compartilhado)
-- ============================================================

CREATE OR REPLACE FUNCTION fn_set_atualizado_em()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.atualizado_em = NOW();
  RETURN NEW;
END;
$$;


-- ============================================================
--  Autenticação
-- ============================================================

CREATE TABLE usuarios (
  id            BIGSERIAL PRIMARY KEY,
  email         VARCHAR(255) UNIQUE NOT NULL,
  senha_hash    VARCHAR(255)        NOT NULL,
  tipo          tipo_usuario        NOT NULL,
  criado_em     TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER trg_usuarios_atualizado_em
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

CREATE TABLE auth_tokens (
  id          BIGSERIAL PRIMARY KEY,
  usuario_id  BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  token       TEXT NOT NULL UNIQUE,
  expires_at  TIMESTAMPTZ NOT NULL,
  deleted_at  TIMESTAMPTZ,
  criado_em   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_auth_tokens_usuario ON auth_tokens (usuario_id);
CREATE INDEX idx_auth_tokens_expires ON auth_tokens (expires_at);
CREATE INDEX idx_auth_tokens_ativos ON auth_tokens (token, usuario_id)
  WHERE deleted_at IS NULL;


-- ============================================================
--  Perfis
-- ============================================================

CREATE TABLE perfis_pessoais (
  usuario_id  BIGINT PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  nome        VARCHAR(150) NOT NULL,
  cidade      VARCHAR(100),
  estado      VARCHAR(2)
);

CREATE TABLE perfis_bandas (
  usuario_id      BIGINT PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  nome_artistico  VARCHAR(150) NOT NULL,
  estilo_musical  VARCHAR(100),
  descricao       TEXT,
  cnpj            VARCHAR(18) UNIQUE,
  cnpj_validado   BOOLEAN     NOT NULL DEFAULT FALSE,
  whatsapp        VARCHAR(20),
  video_url       VARCHAR(500),
  criado_em       TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_banda_cnpj CHECK (
    cnpj IS NULL OR cnpj ~ '^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$'
  ),
  CONSTRAINT chk_banda_video_url CHECK (
    video_url IS NULL OR video_url ~ '^https?://'
  )
);

CREATE TRIGGER trg_perfis_bandas_atualizado_em
  BEFORE UPDATE ON perfis_bandas
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

CREATE TABLE perfis_comunidades (
  usuario_id    BIGINT PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  nome_entidade VARCHAR(150) NOT NULL,
  descricao     TEXT,
  cnpj          VARCHAR(18) UNIQUE,
  cnpj_validado BOOLEAN     NOT NULL DEFAULT FALSE,
  whatsapp      VARCHAR(20),
  endereco      VARCHAR(255),
  cidade        VARCHAR(100),
  estado        VARCHAR(2),
  latitude      DECIMAL(10, 7),
  longitude     DECIMAL(10, 7),
  criado_em     TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_comunidade_cnpj CHECK (
    cnpj IS NULL OR cnpj ~ '^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$'
  )
);

CREATE TRIGGER trg_perfis_comunidades_atualizado_em
  BEFORE UPDATE ON perfis_comunidades
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();


-- ============================================================
--  Mídias de perfil (galeria de bandas e comunidades)
-- ============================================================

CREATE TABLE perfil_midias (
  id          BIGSERIAL PRIMARY KEY,
  dono_tipo   dono_midia          NOT NULL,
  dono_id     BIGINT              NOT NULL,
  tipo        tipo_midia          NOT NULL,
  url         VARCHAR(500)        NOT NULL,
  titulo      VARCHAR(150),
  descricao   TEXT,
  ordem       SMALLINT            NOT NULL DEFAULT 0,
  criado_em   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_perfil_midia_url CHECK (url ~ '^https?://')
);

CREATE INDEX idx_perfil_midias_dono  ON perfil_midias (dono_tipo, dono_id);
CREATE INDEX idx_perfil_midias_ordem ON perfil_midias (dono_tipo, dono_id, ordem);


-- ============================================================
--  Vendedores
--  Papel atribuído pela comunidade a um usuário do tipo
--  'pessoal' já cadastrado no sistema. usuario_id é nullable
--  para permitir cadastro simplificado (só nome + whatsapp)
--  sem exigir que o vendedor tenha conta na plataforma.
--  Quando usuario_id for preenchido, deve referenciar um
--  usuário de tipo 'pessoal'.
-- ============================================================

CREATE TABLE vendedores (
  id             SERIAL PRIMARY KEY,
  usuario_id     BIGINT REFERENCES usuarios(id) ON DELETE SET NULL,
  comunidade_id  BIGINT NOT NULL REFERENCES perfis_comunidades(usuario_id) ON DELETE CASCADE,
  nome           VARCHAR(150) NOT NULL,
  whatsapp       VARCHAR(20)  NOT NULL,
  ativo          BOOLEAN      NOT NULL DEFAULT TRUE,
  criado_em      TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em  TIMESTAMPTZ DEFAULT NOW(),
  -- Um usuário pessoal só pode ser vendedor de uma comunidade por vez
  CONSTRAINT uq_vendedor_usuario_comunidade UNIQUE (usuario_id, comunidade_id)
);

CREATE TRIGGER trg_vendedores_atualizado_em
  BEFORE UPDATE ON vendedores
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

CREATE INDEX idx_vendedores_comunidade ON vendedores (comunidade_id);
CREATE INDEX idx_vendedores_usuario    ON vendedores (usuario_id);


-- ============================================================
--  Eventos
-- ============================================================

CREATE TABLE eventos (
  id              SERIAL PRIMARY KEY,
  comunidade_id   BIGINT       NOT NULL REFERENCES perfis_comunidades(usuario_id) ON DELETE CASCADE,
  titulo          VARCHAR(200) NOT NULL,
  descricao       TEXT,
  data_inicio     DATE         NOT NULL,
  data_fim        DATE         NOT NULL,
  local_nome      VARCHAR(255),
  local_endereco  VARCHAR(255),
  latitude        DECIMAL(10, 7),
  longitude       DECIMAL(10, 7),
  valor_ingresso  DECIMAL(10, 2),
  foto_capa_url   VARCHAR(500),
  status          status_evento NOT NULL DEFAULT 'agendado',
  criado_em       TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_datas         CHECK (data_fim >= data_inicio),
  CONSTRAINT chk_ingresso      CHECK (valor_ingresso IS NULL OR valor_ingresso >= 0),
  CONSTRAINT chk_foto_capa_url CHECK (
    foto_capa_url IS NULL
    OR foto_capa_url ~ '^https?://'
    OR foto_capa_url ~ '^/media/'
  )
);

CREATE TRIGGER trg_eventos_atualizado_em
  BEFORE UPDATE ON eventos
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

CREATE INDEX idx_eventos_datas      ON eventos (data_inicio, data_fim);
CREATE INDEX idx_eventos_comunidade ON eventos (comunidade_id);
CREATE INDEX idx_eventos_status     ON eventos (status);


-- ============================================================
--  Dias do evento
-- ============================================================

CREATE TABLE evento_dias (
  id            SERIAL PRIMARY KEY,
  evento_id     INT      NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  data          DATE     NOT NULL,
  data_fim_dia  DATE     NOT NULL,
  hora_inicio   TIME     NOT NULL,
  hora_fim      TIME     NOT NULL,
  observacao    VARCHAR(255),
  atualizado_em TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_data_fim_dia CHECK (
    data_fim_dia = data OR data_fim_dia = data + INTERVAL '1 day'
  ),
  CONSTRAINT uq_evento_data UNIQUE (evento_id, data)
);

CREATE TRIGGER trg_evento_dias_atualizado_em
  BEFORE UPDATE ON evento_dias
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

CREATE INDEX idx_evento_dias_evento ON evento_dias (evento_id);
CREATE INDEX idx_evento_dias_data   ON evento_dias (data);


-- ============================================================
--  Mídias de evento
-- ============================================================

CREATE TABLE evento_midias (
  id          BIGSERIAL PRIMARY KEY,
  evento_id   INT          NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  tipo        tipo_midia   NOT NULL,
  url         VARCHAR(500) NOT NULL,
  titulo      VARCHAR(150),
  descricao   TEXT,
  ordem       SMALLINT     NOT NULL DEFAULT 0,
  criado_em   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_evento_midia_url CHECK (url ~ '^https?://')
);

CREATE INDEX idx_evento_midias_evento ON evento_midias (evento_id);
CREATE INDEX idx_evento_midias_ordem  ON evento_midias (evento_id, ordem);


-- ============================================================
--  Contratos (N:N evento <-> banda + status de aceite)
-- ============================================================

CREATE TABLE contratos (
  id              SERIAL PRIMARY KEY,
  evento_id       INT NOT NULL REFERENCES eventos(id)               ON DELETE CASCADE,
  banda_id        BIGINT NOT NULL REFERENCES perfis_bandas(usuario_id) ON DELETE CASCADE,
  status_aceite   status_contrato NOT NULL DEFAULT 'pendente',
  data_assinatura TIMESTAMPTZ,
  criado_em       TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_contrato_evento_banda UNIQUE (evento_id, banda_id)
);

CREATE TRIGGER trg_contratos_atualizado_em
  BEFORE UPDATE ON contratos
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

CREATE INDEX idx_contratos_evento ON contratos (evento_id);
CREATE INDEX idx_contratos_banda  ON contratos (banda_id);


-- ============================================================
--  Reservas de ingresso
-- ============================================================

CREATE TABLE reservas (
  id                BIGSERIAL PRIMARY KEY,
  evento_id         INT    NOT NULL REFERENCES eventos(id)    ON DELETE CASCADE,
  comprador_id      BIGINT NOT NULL REFERENCES usuarios(id)   ON DELETE CASCADE,
  vendedor_id       INT    REFERENCES vendedores(id)          ON DELETE SET NULL,
  quantidade        INT    NOT NULL DEFAULT 1,
  status_pagamento  status_pagamento NOT NULL DEFAULT 'pendente',
  criado_em         TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em     TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_quantidade CHECK (quantidade >= 1 AND quantidade <= 10)
);

CREATE TRIGGER trg_reservas_atualizado_em
  BEFORE UPDATE ON reservas
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

CREATE INDEX idx_reservas_evento    ON reservas (evento_id);
CREATE INDEX idx_reservas_comprador ON reservas (comprador_id);
CREATE INDEX idx_reservas_vendedor  ON reservas (vendedor_id);

-- Índice para anti-duplicata: um comprador não deve ter mais de N reservas
-- pendentes/confirmadas por evento (checado na aplicação)
CREATE INDEX idx_reservas_comprador_evento ON reservas (comprador_id, evento_id);


-- ============================================================
--  Logs de auditoria
-- ============================================================

CREATE TABLE logs_status_contratos (
  id              BIGSERIAL PRIMARY KEY,
  contrato_id     INT NOT NULL REFERENCES contratos(id) ON DELETE CASCADE,
  status_anterior status_contrato,
  status_novo     status_contrato NOT NULL,
  usuario_id      BIGINT REFERENCES usuarios(id),
  criado_em       TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE logs_status_pagamentos (
  id              BIGSERIAL PRIMARY KEY,
  reserva_id      BIGINT NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
  status_anterior status_pagamento,
  status_novo     status_pagamento NOT NULL,
  usuario_id      BIGINT REFERENCES usuarios(id),
  criado_em       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_logs_contrato_id ON logs_status_contratos (contrato_id);
CREATE INDEX idx_logs_reserva_id  ON logs_status_pagamentos (reserva_id);