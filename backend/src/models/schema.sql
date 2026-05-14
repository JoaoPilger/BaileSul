-- ============================================================
--  BaileSul – Schema PostgreSQL  v4
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
  id          BIGSERIAL PRIMARY KEY,
  email       VARCHAR(255) UNIQUE NOT NULL,
  senha_hash  VARCHAR(255)        NOT NULL,
  tipo        tipo_usuario        NOT NULL,
  criado_em   TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER trg_usuarios_atualizado_em
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();


-- ============================================================
--  Perfis
-- ============================================================

CREATE TABLE perfis_pessoais (
  usuario_id  INT PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  nome        VARCHAR(150) NOT NULL,
  cidade      VARCHAR(100),
  estado      VARCHAR(2)
);

CREATE TABLE perfis_bandas (
  usuario_id      INT PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  nome_artistico  VARCHAR(150) NOT NULL,
  estilo_musical  VARCHAR(100),
  descricao       TEXT,
  cnpj            VARCHAR(18) UNIQUE,
  whatsapp        VARCHAR(20),
  criado_em       TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_banda_cnpj CHECK (
    cnpj IS NULL OR cnpj ~ '^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$'
  )
);

CREATE TRIGGER trg_perfis_bandas_atualizado_em
  BEFORE UPDATE ON perfis_bandas
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

CREATE TABLE perfis_comunidades (
  usuario_id    INT PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  nome_entidade VARCHAR(150) NOT NULL,
  descricao     TEXT,
  cnpj          VARCHAR(18) UNIQUE,
  whatsapp      VARCHAR(20),
  endereco      VARCHAR(255),
  cidade        VARCHAR(100),
  estado        VARCHAR(2),
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
--
--  Centraliza imagens e vídeos exibidos nas páginas de perfil.
--  dono_tipo + dono_id identificam o dono sem FK polimórfica:
--  a aplicação valida que dono_id existe na tabela correta
--  conforme dono_tipo.
--  ordem define a sequência de exibição na galeria (menor = primeiro).
-- ============================================================

CREATE TABLE perfil_midias (
  id          BIGSERIAL PRIMARY KEY,
  dono_tipo   dono_midia          NOT NULL,
  dono_id     INT                 NOT NULL,
  tipo        tipo_midia          NOT NULL,
  url         VARCHAR(500)        NOT NULL,
  titulo      VARCHAR(150),
  descricao   TEXT,
  ordem       SMALLINT            NOT NULL DEFAULT 0,
  criado_em   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_perfil_midia_url CHECK (url ~ '^https?://')
);

CREATE INDEX idx_perfil_midias_dono ON perfil_midias (dono_tipo, dono_id);
CREATE INDEX idx_perfil_midias_ordem ON perfil_midias (dono_tipo, dono_id, ordem);


-- ============================================================
--  Mídias de evento (galeria por evento)
--
--  Fotos e vídeos publicados em um evento específico.
--  Vinculadas ao evento, não ao perfil da comunidade,
--  permitindo que a galeria do evento fique isolada e
--  possa ser removida junto com o evento (ON DELETE CASCADE).
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
--  Vendedores
-- ============================================================

CREATE TABLE vendedores (
  id             SERIAL PRIMARY KEY,
  usuario_id     INT NOT NULL REFERENCES usuarios(id)                    ON DELETE CASCADE,
  comunidade_id  INT NOT NULL REFERENCES perfis_comunidades(usuario_id)  ON DELETE CASCADE,
  nome           VARCHAR(150) NOT NULL,
  whatsapp       VARCHAR(20)  NOT NULL,
  ativo          BOOLEAN      NOT NULL DEFAULT TRUE,
  criado_em      TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER trg_vendedores_atualizado_em
  BEFORE UPDATE ON vendedores
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();


-- ============================================================
--  Eventos
-- ============================================================

CREATE TABLE eventos (
  id              SERIAL PRIMARY KEY,
  comunidade_id   INT          NOT NULL REFERENCES perfis_comunidades(usuario_id) ON DELETE CASCADE,
  titulo          VARCHAR(200) NOT NULL,
  descricao       TEXT,
  data_inicio     DATE         NOT NULL,
  data_fim        DATE         NOT NULL,
  local_nome      VARCHAR(255),
  valor_ingresso  DECIMAL(10, 2),
  foto_capa_url   VARCHAR(500),
  status          status_evento NOT NULL DEFAULT 'agendado',
  criado_em       TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_datas         CHECK (data_fim >= data_inicio),
  CONSTRAINT chk_ingresso      CHECK (valor_ingresso IS NULL OR valor_ingresso >= 0),
  CONSTRAINT chk_foto_capa_url CHECK (foto_capa_url IS NULL OR foto_capa_url ~ '^https?://')
);

CREATE TRIGGER trg_eventos_atualizado_em
  BEFORE UPDATE ON eventos
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

CREATE INDEX idx_eventos_datas         ON eventos (data_inicio, data_fim);
CREATE INDEX idx_eventos_comunidade    ON eventos (comunidade_id);
CREATE INDEX idx_eventos_status        ON eventos (status);


-- ============================================================
--  Dias do evento
-- ============================================================

CREATE TABLE evento_dias (
  id           SERIAL PRIMARY KEY,
  evento_id    INT      NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  data         DATE     NOT NULL,
  data_fim_dia DATE     NOT NULL,
  hora_inicio  TIME     NOT NULL,
  hora_fim     TIME     NOT NULL,
  observacao   VARCHAR(255),
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
--  Contratos (relação N:N evento <-> banda + status de aceite)
-- ============================================================

CREATE TABLE contratos (
  id              SERIAL PRIMARY KEY,
  evento_id       INT NOT NULL REFERENCES eventos(id)              ON DELETE CASCADE,
  banda_id        INT NOT NULL REFERENCES perfis_bandas(usuario_id) ON DELETE CASCADE,
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
  evento_id         INT NOT NULL REFERENCES eventos(id)    ON DELETE CASCADE,
  comprador_id      BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  vendedor_id       INT REFERENCES vendedores(id)          ON DELETE SET NULL, -- Mantém histórico se vendedor for removido
  quantidade        INT NOT NULL DEFAULT 1,
  status_pagamento  status_pagamento NOT NULL DEFAULT 'pendente',
  criado_em         TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em     TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_quantidade CHECK (quantidade >= 1)
);

CREATE TRIGGER trg_reservas_atualizado_em
  BEFORE UPDATE ON reservas
  FOR EACH ROW EXECUTE FUNCTION fn_set_atualizado_em();

CREATE INDEX idx_reservas_evento    ON reservas (evento_id);
CREATE INDEX idx_reservas_comprador ON reservas (comprador_id);
CREATE INDEX idx_reservas_vendedor  ON reservas (vendedor_id);

-- Log de Auditoria para Contratos
CREATE TABLE logs_status_contratos (
  id              BIGSERIAL PRIMARY KEY,
  contrato_id     INT NOT NULL REFERENCES contratos(id) ON DELETE CASCADE,
  status_anterior status_contrato,
  status_novo     status_contrato NOT NULL,
  usuario_id      BIGINT REFERENCES usuarios(id), -- Autor da mudança
  criado_em       TIMESTAMPTZ DEFAULT NOW()
);

-- Log de Auditoria para Pagamentos
CREATE TABLE logs_status_pagamentos (
  id                BIGSERIAL PRIMARY KEY,
  reserva_id        BIGINT NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
  status_anterior   status_pagamento,
  status_novo       status_pagamento NOT NULL,
  usuario_id        BIGINT REFERENCES usuarios(id), -- Autor da mudança
  criado_em         TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_logs_contrato_id ON logs_status_contratos(contrato_id);
CREATE INDEX idx_logs_reserva_id ON logs_status_pagamentos(reserva_id);