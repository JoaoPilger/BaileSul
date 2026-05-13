-- ============================================================
--  BaileSul – Schema PostgreSQL
--  Baseado na modelagem do Pré-Projeto (seção 4.5)
-- ============================================================

-- Tipos de usuário
CREATE TYPE tipo_usuario AS ENUM ('pessoal', 'banda', 'comunidade', 'vendedor');

-- Tabela base de autenticação
CREATE TABLE usuarios (
  id          SERIAL PRIMARY KEY,
  email       VARCHAR(255) UNIQUE NOT NULL,
  senha_hash  VARCHAR(255) NOT NULL,
  tipo        tipo_usuario NOT NULL,
  criado_em   TIMESTAMP DEFAULT NOW()
);

-- Perfil: Pessoal
CREATE TABLE perfis_pessoais (
  usuario_id  INT PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  nome        VARCHAR(150) NOT NULL,
  cidade      VARCHAR(100),
  estado      VARCHAR(2)
);

-- Perfil: Banda
CREATE TABLE perfis_bandas (
  usuario_id      INT PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  nome_artistico  VARCHAR(150) NOT NULL,
  estilo_musical  VARCHAR(100),
  descricao       TEXT,
  cnpj            VARCHAR(18) UNIQUE,
  whatsapp        VARCHAR(20),
  video_url       VARCHAR(255)
);

-- Perfil: Comunidade
CREATE TABLE perfis_comunidades (
  usuario_id    INT PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  nome_entidade VARCHAR(150) NOT NULL,
  descricao     TEXT,
  cnpj          VARCHAR(18) UNIQUE,
  whatsapp      VARCHAR(20),
  endereco      VARCHAR(255),
  cidade        VARCHAR(100),
  estado        VARCHAR(2)
);

-- Vendedores (subperfil vinculado à comunidade)
CREATE TABLE vendedores (
  id             SERIAL PRIMARY KEY,
  usuario_id     INT REFERENCES usuarios(id) ON DELETE CASCADE,
  comunidade_id  INT REFERENCES usuarios(id) ON DELETE CASCADE,
  nome           VARCHAR(150) NOT NULL,
  whatsapp       VARCHAR(20),
  ativo          BOOLEAN DEFAULT TRUE
);

-- Eventos
CREATE TYPE status_evento AS ENUM ('agendado', 'cancelado', 'finalizado');

CREATE TABLE eventos (
  id              SERIAL PRIMARY KEY,
  comunidade_id   INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  titulo          VARCHAR(200) NOT NULL,
  descricao       TEXT,
  data_inicio     TIMESTAMP NOT NULL,
  data_fim        TIMESTAMP NOT NULL,
  local_nome      VARCHAR(255),
  valor_ingresso  DECIMAL(10, 2),
  status          status_evento DEFAULT 'agendado',
  criado_em       TIMESTAMP DEFAULT NOW()
);

-- Relação N:N Evento <-> Banda
CREATE TABLE evento_bandas (
  evento_id  INT REFERENCES eventos(id) ON DELETE CASCADE,
  banda_id   INT REFERENCES usuarios(id) ON DELETE CASCADE,
  PRIMARY KEY (evento_id, banda_id)
);

-- Contratos (agenda oficial das bandas)
CREATE TYPE status_contrato AS ENUM ('pendente', 'aceito', 'recusado');

CREATE TABLE contratos (
  id              SERIAL PRIMARY KEY,
  evento_id       INT NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  banda_id        INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  status_aceite   status_contrato DEFAULT 'pendente',
  data_assinatura TIMESTAMP
);

-- Reservas de ingresso
CREATE TYPE status_pagamento AS ENUM ('pendente', 'confirmado', 'cancelado');

CREATE TABLE reservas (
  id                SERIAL PRIMARY KEY,
  evento_id         INT NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  comprador_id      INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  vendedor_id       INT NOT NULL REFERENCES vendedores(id),
  quantidade        INT NOT NULL DEFAULT 1,
  status_pagamento  status_pagamento DEFAULT 'pendente',
  criado_em         TIMESTAMP DEFAULT NOW()
);