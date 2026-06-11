# BaileSul API — Documentação do Backend

API REST para a plataforma **BaileSul** (gestão integrada de eventos regionais: comunidades, bandas, vendedores, reservas de ingresso e contratos).

- **Base URL:** `http://localhost:3000` (desenvolvimento)
- **Prefixo:** `/api`
- **Formato:** JSON (`Content-Type: application/json`)
- **Versão do schema:** PostgreSQL v5 (`src/models/schema.sql`)

---

## Índice

1. [Stack e dependências](#stack-e-dependências)
2. [Estrutura do projeto](#estrutura-do-projeto)
3. [Instalação e execução](#instalação-e-execução)
4. [Variáveis de ambiente](#variáveis-de-ambiente)
5. [Banco de dados](#banco-de-dados)
6. [Autenticação e autorização](#autenticação-e-autorização)
7. [Segurança](#segurança)
8. [Integrações externas](#integrações-externas)
9. [Referência da API](#referência-da-api)
10. [Códigos de status e erros](#códigos-de-status-e-erros)
11. [Tipos de usuário e papéis](#tipos-de-usuário-e-papéis)
12. [Requisitos funcionais (RF)](#requisitos-funcionais-rf)
13. [Limitações conhecidas](#limitações-conhecidas)

---

## Stack e dependências

| Tecnologia | Uso |
|------------|-----|
| Node.js | Runtime |
| Express 5 | Servidor HTTP |
| PostgreSQL (`pg`) | Persistência |
| bcrypt | Hash de senhas |
| jsonwebtoken | JWT |
| helmet | Headers de segurança |
| express-rate-limit | Limite de requisições |
| cors | Controle de origem |
| dotenv | Variáveis de ambiente |

**Scripts npm:**

```bash
npm start    # node server.js
npm run dev  # node --watch server.js
```

---

## Estrutura do projeto

```
backend/
├── server.js                 # Entrada: listen + graceful shutdown
├── package.json
├── .env.example
├── README.md                 # Este arquivo
└── src/
    ├── app.js                # Express: middlewares, rotas, erros
    ├── config/
    │   └── database.js       # Pool PostgreSQL
    ├── middlewares/
    │   └── auth.middleware.js
    ├── routes/               # Definição de rotas HTTP
    ├── controllers/          # Lógica de negócio + SQL
    ├── services/
    │   ├── external.service.js  # CNPJ + geocodificação
    │   └── token.service.js       # Limpeza de auth_tokens
    ├── utils/
    │   ├── validators.js          # WhatsApp, URL, CNPJ
    │   └── pagination.js
    ├── models/
    │   └── schema.sql        # DDL PostgreSQL v5
    ├── documentacao.md       # Referência completa da API
    ├── tests.http            # Exemplos REST Client (opcional)
    └── scripts/
        └── test-routes.js    # Teste integrado de rotas
```

**Padrão arquitetural:** rotas → controllers → queries parametrizadas (sem ORM).

---

## Instalação e execução

### Pré-requisitos

- Node.js 18+
- PostgreSQL 14+

### Passos

```bash
cd backend
npm install
cp .env.example .env
# Edite .env com credenciais do banco e JWT_SECRET
```

Crie o banco e aplique o schema:

```bash
psql -U postgres -d nome_do_banco -f src/models/schema.sql
```

Inicie a API:

```bash
npm run dev
```

Verifique o health check:

```http
GET http://localhost:3000/api/health
```

Resposta esperada:

```json
{ "status": "ok", "projeto": "BaileSul" }
```

---

## Variáveis de ambiente

Copie `.env.example` para `.env`.

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `PORT` | Não | Porta HTTP (padrão: `3000`) |
| `JWT_SECRET` | **Sim** | Chave secreta para assinar/verificar JWT |
| `JWT_EXPIRES_IN` | Não | Expiração do token (padrão: `7d`) |
| `CLIENT_URL` | Recomendada | Origem(ns) CORS. Várias URLs separadas por vírgula |
| `DB_HOST` | **Sim** | Host PostgreSQL |
| `DB_PORT` | Não | Porta (padrão: `5432`) |
| `DB_NAME` | **Sim** | Nome do banco |
| `DB_USER` | **Sim** | Usuário do banco |
| `DB_PASSWORD` | **Sim** | Senha do banco |
| `NODE_ENV` | Não | `production` habilita SSL no pool PostgreSQL |

Se faltar alguma variável obrigatória, a aplicação encerra na inicialização com mensagem no console.

---

## Banco de dados

### Modelo principal

```
usuarios (pessoal | banda | comunidade)
    ├── auth_tokens              # JWT persistidos + revogação
    ├── perfis_pessoais
    ├── perfis_bandas
    └── perfis_comunidades
            ├── vendedores (opcional: usuario_id → pessoal)
            └── eventos
                    ├── evento_dias
                    ├── evento_midias
                    ├── contratos (evento ↔ banda)
                    └── reservas
```

### Enums relevantes

| Enum | Valores |
|------|---------|
| `tipo_usuario` | `pessoal`, `banda`, `comunidade` |
| `status_evento` | `agendado`, `cancelado`, `finalizado` |
| `status_contrato` | `pendente`, `aceito`, `recusado` |
| `status_pagamento` | `pendente`, `confirmado`, `cancelado` |

### Observações

- **Vendedor não é um `tipo_usuario`:** é um papel na tabela `vendedores`, vinculado a uma comunidade. Pode existir só com `nome` + `whatsapp`, ou associado a um usuário `pessoal` via `usuario_id`.
- Tabelas `perfil_midias` e `evento_midias` existem no schema; a API **lê** mídias em perfis/eventos, mas **não expõe CRUD** de upload/gestão ainda.
- Logs: `logs_status_contratos`, `logs_status_pagamentos`.

---

## Autenticação e autorização

### Login

Envie credenciais em `POST /api/auth/login`. A resposta inclui:

```json
{
  "token": "<JWT>",
  "tipo": "pessoal",
  "usuario_id": 1
}
```

O cadastro via `POST /api/auth/register` também retorna um JWT e realiza login automático.

### Uso do token

Inclua em todas as rotas protegidas:

```http
Authorization: Bearer <token>
```

O middleware `autenticar` decodifica o JWT e define `req.usuario`:

```json
{ "id": 1, "tipo": "comunidade" }
```

### Logout

Revogue o token ativo com:

```http
POST /api/auth/logout
Authorization: Bearer <token>
```

O endpoint faz soft delete do token em `auth_tokens.deleted_at`.

Também é possível revogar um token específico pelo seu ID:

```http
POST /api/auth/logout/:id
Authorization: Bearer <token>
```

### RBAC

O middleware `autorizar('comunidade', 'pessoal')` restringe por `req.usuario.tipo`.

| Rota / ação | Perfis permitidos |
|-------------|-------------------|
| CRUD eventos, calendário, vendedores | `comunidade` |
| Reservar ingresso, minhas reservas | `pessoal` |
| Agenda, perfil banda, responder contrato | `banda` |
| Confirmar pagamento | `comunidade` **ou** `pessoal` (com regras extras no controller) |

---

## Segurança

| Medida | Implementação |
|--------|----------------|
| Senhas | bcrypt (cost 10); mínimo 8 caracteres, letra + número |
| JWT | Persistido em `auth_tokens`; revogado via logout; validado a cada request |
| Limpeza tokens | Expirados + revogados >30 dias (boot, 6h, pós-logout) |
| CORS | Origens em `CLIENT_URL`; localhost permitido em dev |
| Headers | `helmet()` |
| Body | `express.json({ limit: '1mb' })` |
| Rate limit | Global: 120 req/min; auth: 20/15 min; reserva: 10/min |
| Validações | WhatsApp (10–15 dígitos), URLs com domínio, CNPJ via OpenCNPJ |
| Erros 500 | Mensagem genérica ao cliente |
| SQL | Queries parametrizadas |
| Shutdown | `SIGTERM` / `SIGINT` fecham servidor e pool |

---

## Integrações externas

Arquivo: `src/services/external.service.js`

| Serviço | Função | Comportamento |
|---------|--------|---------------|
| [OpenCNPJ](https://open.cnpja.com) | `validarCNPJ` | Ativo quando `status.id = 2` ou `"Ativa"`. Bloqueia cadastro se inválido quando API responde; falha de rede permite com `cnpj_validado: false` |
| [Nominatim](https://nominatim.openstreetmap.org) | `geocodificarEndereco` | Latitude/longitude para comunidades e eventos |
| Haversine (local) | `calcularDistanciaKm` | Filtro `lat`, `lng`, `raio_km` em listagem de eventos |

---

## Referência da API

### Convenções

- IDs de **banda** e **comunidade** = `usuario_id` da tabela `usuarios`.
- IDs de **evento**, **contrato**, **vendedor**, **reserva** = chaves próprias das tabelas.
- Campos omitidos em `PUT`/`PATCH` com `COALESCE` não são apagados.
- Listagens públicas retornam `{ dados, paginacao }` com `?pagina=1&limite=20` (máx. 100).

> Referência detalhada: [`src/documentacao.md`](src/documentacao.md)

---

### Health

#### `GET /api/health`

Público. Status da API.

---

### Autenticação — `/api/auth`

#### `POST /api/auth/register`

Cadastro (RF01). Rate limit: 20 req / 15 min.

**Body:**

```json
{
  "email": "user@email.com",
  "senha": "senha123",
  "tipo": "pessoal",
  "perfil": {
    "nome": "João",
    "cidade": "Blumenau",
    "estado": "SC"
  }
}
```

**Tipos:** `pessoal` | `banda` | `comunidade`

**Perfil `banda`:**

```json
{
  "email": "user@email.com",
  "senha": "senha123",
  "tipo": "banda",
  "perfil": {
    "nome_artistico": "Grupo Sul",
    "estilo_musical": "Vanera",
    "cnpj": "12.345.678/0001-90",
    "whatsapp": "5547999999999",
    "video_url": "https://youtube.com/..."
  }
}
```

**Perfil `comunidade`:**

```json
{
  "email": "user@email.com",
  "senha": "senha123",
  "tipo": "comunidade",
  "perfil": {
    "nome_entidade": "CTG Rancho",
    "cnpj": "12.345.678/0001-90",
    "endereco": "Rua X, 100",
    "cidade": "Blumenau",
    "estado": "SC",
    "whatsapp": "5547999999999"
  }
}
```

**Resposta `201`:**

```json
{
  "message": "Usuário cadastrado com sucesso",
  "token": "<jwt>",
  "tipo": "comunidade",
  "usuario_id": 1,
  "email": "user@email.com",
  "cnpj_validado": true
}
```

**Erros comuns:** `400` validação, `409` e-mail ou CNPJ duplicado.

---

#### `POST /api/auth/login`

**Body:** `{ "email", "senha" }`

**Resposta `200`:** `{ "token", "tipo", "usuario_id" }`

**Erros:** `401` credenciais inválidas (mensagem genérica).

---

### Eventos — `/api/eventos`

#### `GET /api/eventos`

Público. Lista eventos com `status = agendado` (RF14, RF16).

**Query opcionais:**

| Parâmetro | Descrição |
|-----------|-----------|
| `data` | Data de início (`YYYY-MM-DD`) |
| `cidade` | Cidade da comunidade (LIKE) |
| `estado` | UF |
| `estilo` | Estilo musical de banda contratada |
| `banda` | Nome artístico da banda |
| `lat`, `lng`, `raio_km` | Filtro por proximidade (Haversine) |
| `pagina`, `limite` | Paginação (padrão 20, máx. 100) |

---

#### `GET /api/eventos/calendario`

Auth: `comunidade`. Calendário compartilhado (RF06) — todos os eventos não cancelados.

---

#### `GET /api/eventos/:id`

Público. Detalhe do evento (RF17): bandas, vendedores ativos, dias, mídias.

---

#### `POST /api/eventos`

Auth: `comunidade`. Cria evento (RF07).

**Body:**

```json
{
  "titulo": "Baile de Inverno",
  "descricao": "Descrição do evento",
  "data_inicio": "2026-07-01",
  "data_fim": "2026-07-02",
  "local_nome": "Parque",
  "local_endereco": "Rua Y, Blumenau, SC",
  "valor_ingresso": 50.00,
  "foto_capa_url": "https://...",
  "bandas": [2, 5],
  "dias": [
    {
      "data": "2026-07-01",
      "hora_inicio": "20:00",
      "hora_fim": "02:00",
      "observacao": "Primeira noite"
    }
  ]
}
```

**Resposta `201`:** `{ "message", "evento_id" }`

**Erro `409`:** conflito de datas na mesma cidade (RF06 **bloqueia** criação).

---

#### `PUT /api/eventos/:id`

Auth: `comunidade` (somente dona). Atualização parcial. Se `dias` for enviado, substitui todos os dias do evento.

**Status:** transições permitidas de `agendado` → `cancelado` apenas.

---

#### `DELETE /api/eventos/:id`

Auth: `comunidade` (somente dona). Soft delete: `status = cancelado`.

---

#### `PATCH /api/eventos/:id/contratos/:contrato_id`

Auth: `banda`. Aceita ou recusa contrato.

**Body:** `{ "status_aceite": "aceito" }` ou `"recusado"`

Registra log em `logs_status_contratos`.

---

### Bandas — `/api/bandas`

#### `GET /api/bandas`

Público (RF10, RF15). Query: `estilo`, `cidade` (contratos **aceitos** em eventos agendados), `pagina`, `limite`.

---

#### `GET /api/bandas/:id`

Público. Perfil, eventos futuros aceitos, mídias da vitrine.

`:id` = `usuario_id` da banda.

---

#### `GET /api/bandas/me/agenda`

Auth: `banda`. Agenda de contratos (RF18).

---

#### `PUT /api/bandas/me/perfil`

Auth: `banda`. Atualiza vitrine (RF12, RF20): `nome_artistico`, `estilo_musical`, `descricao`, `whatsapp`, `video_url`.

---

### Comunidades — `/api/comunidades`

#### `GET /api/comunidades`

Público (RF15). Query: `cidade`, `estado`.

---

#### `GET /api/comunidades/:id`

Público. Perfil, eventos futuros agendados, mídias.

---

#### `PUT /api/comunidades/me/perfil`

Auth: `comunidade`. Atualiza vitrine; re-geocodifica se `endereco` ou `cidade` mudarem.

---

### Vendedores — `/api/vendedores`

#### `GET /api/vendedores`

Auth: `comunidade`. Lista vendedores da comunidade autenticada (RF08).

---

#### `POST /api/vendedores`

Auth: `comunidade`. Adiciona vendedor (RF08).

**Modo A — cadastro simples (sem conta):**

```json
{
  "nome": "Maria Vendas",
  "whatsapp": "5547999887766"
}
```

**Modo B — vincular usuário pessoal existente:**

```json
{
  "nome": "Maria Vendas",
  "whatsapp": "5547999887766",
  "usuario_id": 42
}
```

---

#### `DELETE /api/vendedores/:id`

Auth: `comunidade`. Desativa vendedor (`ativo = false`).

---

#### `PATCH /api/vendedores/reservas/:reserva_id/confirmar`

Auth: `comunidade` **ou** `pessoal` (RF13).

**Quem pode confirmar:**

1. **Comunidade** dona do evento da reserva.
2. **Pessoal** cujo `usuario_id` está vinculado ao `vendedor_id` da reserva.

Atualiza `status_pagamento` para `confirmado` e grava log.

---

### Reservas — `/api/reservas`

#### `POST /api/reservas/eventos/:evento_id`

Auth: `pessoal`. Cria reserva (RF11). Rate limit: 10/min.

**Body:** `{ "quantidade": 2 }` (máx. 10; 1 reserva ativa por usuário/evento)

**Resposta `201`:** `reserva_id`, vendedor e `whatsapp_link`.

#### `GET /api/reservas/minhas`

Auth: `pessoal`. Lista reservas do comprador autenticado (RF11).

---

## Códigos de status e erros

Respostas de erro seguem o formato:

```json
{ "error": "Mensagem descritiva" }
```

| Código | Uso típico |
|--------|------------|
| `400` | Validação de entrada |
| `401` | Token ausente, inválido ou credenciais incorretas |
| `403` | Perfil sem permissão ou recurso de outro dono |
| `404` | Recurso não encontrado |
| `409` | Conflito (duplicata, estado já processado) |
| `422` | Regra de negócio (ex.: sem vendedor disponível) |
| `429` | Rate limit excedido |
| `500` | Erro interno (mensagem genérica) |

---

## Tipos de usuário e papéis

| Conceito | Descrição |
|----------|-----------|
| `pessoal` | Comprador de ingressos; pode ser vendedor se vinculado em `vendedores` |
| `banda` | Artista; responde contratos; gerencia vitrine e agenda |
| `comunidade` | Organizadora; CRUD de eventos e vendedores; confirma pagamentos |
| Vendedor (papel) | Registro em `vendedores`; não é tipo JWT separado |

**Fluxo reserva → pagamento:**

1. Pessoal reserva em `POST /api/reservas/eventos/:evento_id`.
2. Sistema atribui vendedor (round-robin por menor fila de pendentes).
3. Comprador contata via WhatsApp.
4. Comunidade ou vendedor vinculado confirma em `PATCH /api/vendedores/reservas/:id/confirmar`.

---

## Requisitos funcionais (RF)

| RF | Descrição | Endpoints principais |
|----|-----------|----------------------|
| RF01 | Cadastro multi-tipo | `POST /api/auth/register` |
| RF02 | Login JWT | `POST /api/auth/login` |
| RF03 | Logout JWT | `POST /api/auth/logout`, `POST /api/auth/logout/:id` |
| RF04 | CNPJ banda/comunidade | Validação OpenCNPJ no register |
| RF05 | RBAC por tipo | Middleware `autorizar` |
| RF06 | Calendário / conflito de datas | `GET /calendario`, bloqueio em `POST /eventos` (`409`) |
| RF07 | CRUD eventos | `POST`, `PUT`, `DELETE /api/eventos/:id` |
| RF08 | Gestão vendedores | `/api/vendedores` |
| RF10 | Listagem bandas | `GET /api/bandas` |
| RF11 | Reservas | `POST /api/reservas/eventos/:id`, `GET /api/reservas/minhas` |
| RF12 / RF20 | Vitrine perfil | `PUT .../me/perfil` (banda, comunidade) |
| RF13 | Confirmar pagamento | `PATCH .../confirmar` |
| RF14 / RF16 / RF17 | Busca e detalhe eventos | `GET /api/eventos` |
| RF15 | Perfis públicos | `GET /api/bandas`, `/api/comunidades` |
| RF18 | Agenda banda | `GET /api/bandas/me/agenda` |

---

## Limitações conhecidas

- **CRUD de mídias:** `perfil_midias` e `evento_midias` são lidas em GET, mas não há rotas para criar/editar/remover.
- **Status `finalizado`:** não há endpoint documentado para marcar evento como finalizado.
- **Contratos:** criação na criação do evento; resposta via `PATCH` da banda; sem listagem dedicada de contratos pendentes.
- **Cancelamento de reserva:** não implementado (`status_pagamento = cancelado`).
- **Testes automatizados:** `node scripts/test-routes.js` (33 cenários; requer servidor ativo).
- **Pagamento online:** fluxo manual via WhatsApp; sem gateway de pagamento.

---

## Exemplo rápido (cURL)

```bash
# Login
curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"comunidade@email.com","senha":"senha1234"}'

# Listar eventos
curl -s "http://localhost:3000/api/eventos?cidade=Blumenau"

# Criar evento (com token)
curl -s -X POST http://localhost:3000/api/eventos \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"titulo":"Baile","data_inicio":"2026-08-01","data_fim":"2026-08-01"}'
```

---

## Suporte e manutenção

- Schema: sempre alinhar `src/models/schema.sql` com o banco antes de deploy.
- Em produção: definir `NODE_ENV=production`, `JWT_SECRET` forte, `CLIENT_URL` explícito e HTTPS no proxy reverso.
- Arquivo `src/documentacao.md` — referência completa da API.
- Arquivo `src/tests.http` — testes manuais com REST Client (VS Code).
- `node scripts/test-routes.js` — teste integrado automatizado.
