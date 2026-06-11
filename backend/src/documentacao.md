# BaileSul – Documentação da API

**Base URL:** `http://localhost:3000/api`  
**Autenticação:** Bearer Token JWT (header `Authorization: Bearer <token>`)  
**Content-Type:** `application/json`  
**Última revisão:** jun/2026 — alinhada ao schema v5 e testes em `scripts/test-routes.js`

---

## Índice

0. [Health check](#0-health-check)
1. [Autenticação](#1-autenticação)
2. [Eventos](#2-eventos)
3. [Bandas](#3-bandas)
4. [Comunidades](#4-comunidades)
5. [Vendedores](#5-vendedores)
6. [Reservas](#6-reservas)
7. [Tipos de Usuário e Permissões](#7-tipos-de-usuário-e-permissões)
8. [Códigos de Resposta](#8-códigos-de-resposta)
9. [Testes](#9-testes)

---

## 0. Health check

### `GET /health`

Verifica se a API está online. **Público.**

**Resposta `200`:**
```json
{ "status": "ok", "projeto": "BaileSul" }
```

---

## 1. Autenticação

### `POST /auth/register`
Cadastra um novo usuário. O tipo define o perfil criado.

**Body:**
```json
{
  "email": "user@email.com",
  "senha": "senha1234",
  "tipo": "pessoal | banda | comunidade",
  "perfil": { ... }
}
```

**Perfil para `pessoal`:**
```json
{
  "nome": "João Silva",
  "cidade": "Florianópolis",
  "estado": "SC"
}
```

**Perfil para `banda`:**
```json
{
  "nome_artistico": "Os Gaúchos",
  "estilo_musical": "Gauchesco",
  "descricao": "Banda de música gauchesca",
  "cnpj": "07.526.557/0001-00",
  "whatsapp": "5547999999999",
  "video_url": "https://youtube.com/..."
}
```

**Perfil para `comunidade`:**
```json
{
  "nome_entidade": "CTG Rancho das Araucárias",
  "descricao": "Centro de Tradições Gaúchas",
  "cnpj": "33.000.167/0001-01",
  "whatsapp": "5547999999999",
  "endereco": "Rua das Flores, 100",
  "cidade": "Blumenau",
  "estado": "SC"
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

**Notas:**
- Senha mínima: 8 caracteres, ao menos 1 letra e 1 número.
- Banda e comunidade exigem CNPJ no formato `XX.XXX.XXX/XXXX-XX` (único no banco).
- CNPJ é validado via [OpenCNPJ](https://open.cnpja.com). A API considera **ativo** quando `status.id = 2` ou `status.text = "Ativa"`. Se a API **responder** que o CNPJ é inválido/inativo, o cadastro é **rejeitado** (`400`). Se a API estiver **indisponível** (timeout/erro de rede), o cadastro prossegue com `cnpj_validado: false`.
- WhatsApp (quando informado) deve ter 10 a 15 dígitos.
- `video_url` (banda) deve ser URL http(s) com domínio válido.
- Endereço da comunidade é geocodificado automaticamente via Nominatim.
- O registro retorna um token JWT já persistido em `auth_tokens` (login automático).

**Erros comuns:** `400` validação, `409` e-mail ou CNPJ duplicado.

---

### `POST /auth/login`
Autentica o usuário, gera JWT e persiste em `auth_tokens`.

**Body:**
```json
{
  "email": "user@email.com",
  "senha": "senha123"
}
```

**Resposta `200`:**
```json
{
  "token": "<jwt>",
  "tipo": "comunidade",
  "usuario_id": 1
}
```

---

### `POST /auth/logout`
Revoga o token atual do usuário autenticado (soft delete em `auth_tokens.deleted_at`).

**Headers:** `Authorization: Bearer <token>`

**Resposta `200`:**
```json
{ "message": "Logout realizado com sucesso" }
```

**Nota:** Dispara limpeza assíncrona de tokens expirados/revogados antigos.

---

### `POST /auth/logout/:id`
Revoga um token específico pelo ID (tabela `auth_tokens`). O `:id` deve pertencer ao usuário autenticado e corresponder ao token enviado no header.

**Headers:** `Authorization: Bearer <token>`

**Resposta `200`:**
```json
{ "message": "Logout realizado com sucesso" }
```

**Erros:** `404` se o ID não existir, já estiver revogado ou não pertencer ao usuário/token atual.

---

## 2. Eventos

### `GET /eventos`
Lista eventos agendados com filtros opcionais. **Público.**

**Query params:**

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `data` | `YYYY-MM-DD` | Filtra pela data de início |
| `cidade` | string | Filtra pela cidade da comunidade organizadora |
| `estado` | string (2 letras) | Filtra pelo estado |
| `estilo` | string | Filtra pelo estilo musical das bandas contratadas |
| `banda` | string | Filtra pelo nome artístico da banda |
| `lat` | number | Latitude para filtro por proximidade |
| `lng` | number | Longitude para filtro por proximidade |
| `raio_km` | number | Raio em km (requer `lat` e `lng`) |
| `pagina` | number | Página (padrão: `1`) — alias: `page` |
| `limite` | number | Itens por página (padrão: `20`, máx: `100`) — alias: `limit` |

**Resposta `200`:**
```json
{
  "dados": [
    {
      "id": 1,
      "titulo": "Baile de Inverno",
      "descricao": "...",
      "data_inicio": "2026-07-02",
      "data_fim": "2026-07-02",
      "local_nome": "Parque",
      "valor_ingresso": "50.00",
      "status": "agendado",
      "foto_capa_url": "https://example.com/foto.jpg",
      "latitude": -26.9,
      "longitude": -49.06,
      "comunidade_nome": "CTG Rancho das Araucárias",
      "comunidade_cidade": "Blumenau",
      "comunidade_estado": "SC"
    }
  ],
  "paginacao": {
    "pagina": 1,
    "limite": 20,
    "total": 42,
    "total_paginas": 3
  }
}
```

---

### `GET /eventos/:id`
Retorna detalhes completos de um evento. **Público.**

**Resposta `200`:**
```json
{
  "id": 1,
  "titulo": "Baile de Inverno",
  "bandas": [
    { "usuario_id": 2, "nome_artistico": "Os Gaúchos", "status_aceite": "aceito" }
  ],
  "vendedores": [
    { "id": 1, "nome": "Carlos", "whatsapp": "5547999999999" }
  ],
  "dias": [
    { "data": "2026-07-02", "hora_inicio": "20:00", "hora_fim": "02:00" }
  ],
  "midias": []
}
```

---

### `POST /eventos`
Cria um novo evento. **Requer:** autenticação como `comunidade`.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "titulo": "Baile de Inverno",
  "descricao": "Descrição do evento",
  "data_inicio": "2026-07-02",
  "data_fim": "2026-07-02",
  "local_nome": "Parque Municipal",
  "local_endereco": "Rua Y, Blumenau, SC",
  "valor_ingresso": 50.00,
  "foto_capa_url": "https://example.com/foto.jpg",
  "bandas": [2, 7],
  "dias": [
    {
      "data": "2026-07-02",
      "hora_inicio": "20:00",
      "hora_fim": "02:00",
      "observacao": "Primeira noite"
    }
  ]
}
```

**Resposta `201`:**
```json
{
  "message": "Evento criado com sucesso",
  "evento_id": 1
}
```

**Erros:**
- `409` — conflito de datas com outro evento agendado na mesma cidade (RF06 **bloqueia** a criação):

```json
{
  "error": "Conflito de datas com outro evento agendado na mesma cidade",
  "conflitos_de_data": [
    { "id": 3, "titulo": "Outro Baile", "cidade": "Blumenau" }
  ]
}
```

**Notas:**
- `bandas` cria contratos com status `pendente`. Cada banda receberá uma notificação para aceitar/recusar.
- `foto_capa_url` deve ser URL http(s) com domínio válido (ex.: `https://example.com/foto.jpg`).
- O endereço é geocodificado automaticamente para preencher `latitude`/`longitude`.

---

### `PUT /eventos/:id`
Atualiza dados de um evento. **Requer:** autenticação como `comunidade` dona do evento.

**Headers:** `Authorization: Bearer <token>`

**Body** (todos os campos são opcionais):
```json
{
  "titulo": "Baile de Verão",
  "status": "cancelado",
  "dias": [
    {
      "data": "2026-07-02",
      "hora_inicio": "20:00",
      "hora_fim": "02:00",
      "observacao": "Primeira noite"
    }
  ]
}
```

**Notas:**
- Se o array `dias` for enviado, **substitui** todos os dias existentes do evento (remove e reinsere).
- Re-geocodifica se `local_endereco` ou `local_nome` forem informados.
- `foto_capa_url` deve ser URL http(s) com domínio válido.

**Transições de status permitidas:**

| De | Para |
|---|---|
| `agendado` | `cancelado` |
| `cancelado` | — (nenhuma) |
| `finalizado` | — (nenhuma) |

**Resposta `200`:**
```json
{ "message": "Evento atualizado com sucesso" }
```

---

### `DELETE /eventos/:id`
Cancela um evento (soft delete — altera status para `cancelado`). **Requer:** autenticação como `comunidade` dona do evento.

**Headers:** `Authorization: Bearer <token>`

**Resposta `200`:**
```json
{ "message": "Evento cancelado com sucesso" }
```

---

### `GET /eventos/calendario`
Retorna todos os eventos não cancelados de todas as comunidades. **Requer:** autenticação como `comunidade`.

**Headers:** `Authorization: Bearer <token>`

**Resposta `200`:**
```json
[
  {
    "id": 1,
    "titulo": "Baile de Inverno",
    "data_inicio": "2026-07-02",
    "data_fim": "2026-07-02",
    "status": "agendado",
    "comunidade": "CTG Rancho das Araucárias",
    "cidade": "Blumenau",
    "estado": "SC"
  }
]
```

---

### `PATCH /eventos/:id/contratos/:contrato_id`
Banda aceita ou recusa convite para participar de um evento. **Requer:** autenticação como `banda`.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{ "status_aceite": "aceito | recusado" }
```

**Resposta `200`:**
```json
{ "message": "Contrato aceito com sucesso" }
```

**Erros:**
- `404` — contrato não encontrado ou banda sem permissão.
- `409` — contrato já respondido anteriormente (`status_aceite` ≠ `pendente`).

**Nota:** Registra auditoria em `logs_status_contratos`.

## 3. Bandas

### `GET /bandas`
Lista bandas cadastradas. **Público.**

**Query params:**

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `estilo` | string | Filtra por estilo musical |
| `cidade` | string | Filtra bandas com contratos **aceitos** em eventos agendados na cidade |
| `pagina` | number | Página (padrão: `1`) |
| `limite` | number | Itens por página (padrão: `20`, máx: `100`) |

**Resposta `200`:**
```json
{
  "dados": [
    {
      "usuario_id": 2,
      "nome_artistico": "Os Gaúchos",
      "estilo_musical": "Gauchesco",
      "descricao": "...",
      "whatsapp": "5547999999999",
      "cnpj_validado": true
    }
  ],
  "paginacao": {
    "pagina": 1,
    "limite": 20,
    "total": 5,
    "total_paginas": 1
  }
}
```

---

### `GET /bandas/:id`
Retorna perfil público detalhado de uma banda. **Público.**

**Resposta `200`:**
```json
{
  "usuario_id": 2,
  "nome_artistico": "Os Gaúchos",
  "estilo_musical": "Gauchesco",
  "descricao": "...",
  "whatsapp": "5547999999999",
  "video_url": "https://youtube.com/...",
  "cnpj_validado": true,
  "eventos": [...],
  "midias": [...]
}
```

---

### `GET /bandas/me/agenda`
Retorna a agenda completa de eventos da banda autenticada. **Requer:** autenticação como `banda`.

**Headers:** `Authorization: Bearer <token>`

**Resposta `200`:**
```json
[
  {
    "id": 1,
    "titulo": "Baile de Inverno",
    "data_inicio": "2026-07-02",
    "status_evento": "agendado",
    "status_aceite": "aceito",
    "comunidade": "CTG Rancho das Araucárias",
    "comunidade_whatsapp": "5547999999999",
    "cidade": "Blumenau",
    "estado": "SC"
  }
]
```

---

### `PUT /bandas/me/perfil`
Atualiza a vitrine da banda autenticada. **Requer:** autenticação como `banda`.

**Headers:** `Authorization: Bearer <token>`

**Body** (todos os campos são opcionais):
```json
{
  "nome_artistico": "Os Gaúchos do Sul",
  "estilo_musical": "Gauchesco",
  "descricao": "Nova descrição",
  "whatsapp": "5547999999999",
  "video_url": "https://youtube.com/..."
}
```

**Resposta `200`:**
```json
{ "message": "Perfil atualizado com sucesso" }
```

**Validação:** `whatsapp` e `video_url` (quando informados) seguem as mesmas regras do cadastro.

---

### `GET /comunidades`
Lista comunidades cadastradas. **Público.**

**Query params:**

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `cidade` | string | Filtra por cidade |
| `estado` | string (2 letras) | Filtra por estado |
| `pagina` | number | Página (padrão: `1`) |
| `limite` | number | Itens por página (padrão: `20`, máx: `100`) |

**Resposta `200`:**
```json
{
  "dados": [
    {
      "usuario_id": 1,
      "nome_entidade": "CTG Rancho das Araucárias",
      "descricao": "...",
      "whatsapp": "5547999999999",
      "cidade": "Blumenau",
      "estado": "SC",
      "latitude": -26.9,
      "longitude": -49.06,
      "cnpj_validado": true
    }
  ],
  "paginacao": {
    "pagina": 1,
    "limite": 20,
    "total": 8,
    "total_paginas": 1
  }
}
```

---

### `GET /comunidades/:id`
Retorna perfil público de uma comunidade com eventos ativos. **Público.**

**Resposta `200`:**
```json
{
  "usuario_id": 1,
  "nome_entidade": "CTG Rancho das Araucárias",
  "eventos": [...],
  "midias": [...]
}
```

---

### `PUT /comunidades/me/perfil`
Atualiza a vitrine da comunidade autenticada. **Requer:** autenticação como `comunidade`.

**Headers:** `Authorization: Bearer <token>`

**Body** (todos os campos são opcionais):
```json
{
  "nome_entidade": "CTG Rancho das Araucárias",
  "descricao": "Nova descrição",
  "whatsapp": "5547999999999",
  "endereco": "Rua das Flores, 100",
  "cidade": "Blumenau",
  "estado": "SC"
}
```

**Resposta `200`:**
```json
{ "message": "Perfil atualizado com sucesso" }
```

**Nota:** Se `endereco` ou `cidade` forem informados, o sistema tenta re-geocodificar e atualizar `latitude`/`longitude`.

**Validação:** WhatsApp deve ter 10 a 15 dígitos quando informado.

---

## 5. Vendedores

### `GET /vendedores`
Lista os vendedores da comunidade autenticada. **Requer:** autenticação como `comunidade`.

**Headers:** `Authorization: Bearer <token>`

**Resposta `200`:**
```json
[
  {
    "id": 1,
    "nome": "Carlos",
    "whatsapp": "5547999999999",
    "ativo": true,
    "usuario_id": 5,
    "usuario_nome": "Carlos Alberto"
  }
]
```

---

### `POST /vendedores`
Adiciona um vendedor à comunidade. **Requer:** autenticação como `comunidade`.

**Headers:** `Authorization: Bearer <token>`

**Modo A — Cadastro simples (sem conta na plataforma):**
```json
{
  "nome": "Carlos",
  "whatsapp": "5547999999999"
}
```

**Modo B — Vinculação de usuário pessoal existente:**
```json
{
  "nome": "Carlos",
  "whatsapp": "5547999999999",
  "usuario_id": 5
}
```

**Resposta `201`:**
```json
{
  "message": "Vendedor adicionado",
  "vendedor": {
    "id": 1,
    "nome": "Carlos",
    "whatsapp": "5547999999999",
    "ativo": true,
    "usuario_id": 5
  }
}
```

**Nota:** No modo B, o `usuario_id` informado deve ser de um usuário do tipo `pessoal`. Um usuário pessoal só pode ser vendedor de uma comunidade por vez.

**Validação:** `whatsapp` obrigatório com 10 a 15 dígitos.

---

### `DELETE /vendedores/:id`
Desativa um vendedor (soft delete). **Requer:** autenticação como `comunidade`.

**Headers:** `Authorization: Bearer <token>`

**Resposta `200`:**
```json
{ "message": "Vendedor desativado com sucesso" }
```

---

### `PATCH /vendedores/reservas/:reserva_id/confirmar`
Confirma o pagamento de uma reserva. **Requer:** autenticação como `comunidade` (dona do evento) **ou** `pessoal` (vendedor vinculado à reserva).

**Headers:** `Authorization: Bearer <token>`

**Resposta `200`:**
```json
{ "message": "Pagamento confirmado com sucesso" }
```

**Erros:**
- `403` — usuário pessoal que não é o vendedor vinculado à reserva.
- `404` — reserva não encontrada.
- `409` — reserva já confirmada ou cancelada.

---

### `POST /reservas/eventos/:evento_id`
Cria uma reserva de ingresso para um evento. **Requer:** autenticação como `pessoal`.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{ "quantidade": 2 }
```

**Resposta `201`:**
```json
{
  "message": "Reserva criada! Entre em contato com o vendedor para confirmar o pagamento.",
  "reserva_id": 42,
  "vendedor": {
    "nome": "Carlos",
    "whatsapp": "5547999999999",
    "whatsapp_link": "https://wa.me/5547999999999?text=..."
  }
}
```

**Notas:**
- Máximo de 10 ingressos por reserva.
- Um usuário pode ter apenas 1 reserva ativa (pendente ou confirmada) por evento.
- O vendedor é selecionado por round-robin (menor número de reservas pendentes).
- O link `whatsapp_link` inclui mensagem pré-formatada com título do evento, quantidade e ID da reserva.

---

### `GET /reservas/minhas`
Lista todas as reservas do usuário autenticado. **Requer:** autenticação como `pessoal`.

**Headers:** `Authorization: Bearer <token>`

**Resposta `200`:**
```json
[
  {
    "id": 42,
    "quantidade": 2,
    "status_pagamento": "pendente",
    "criado_em": "2026-06-11T12:00:00Z",
    "evento": "Baile de Inverno",
    "data_inicio": "2026-07-02",
    "local_nome": "Parque Municipal",
    "vendedor_nome": "Carlos",
    "vendedor_whatsapp": "5547999999999"
  }
]
```

---

## 7. Tipos de Usuário e Permissões

| Rota | Método | `pessoal` | `banda` | `comunidade` |
|---|---|---|---|---|
| `/auth/register` | POST | ✅ | ✅ | ✅ |
| `/auth/login` | POST | ✅ | ✅ | ✅ |
| `/auth/logout` | POST | ✅ | ✅ | ✅ |
| `/auth/logout/:id` | POST | ✅ | ✅ | ✅ |
| `/health` | GET | ✅ | ✅ | ✅ |
| `/eventos` | GET | ✅ | ✅ | ✅ |
| `/eventos/:id` | GET | ✅ | ✅ | ✅ |
| `/eventos/calendario` | GET | ❌ | ❌ | ✅ |
| `/eventos` | POST | ❌ | ❌ | ✅ |
| `/eventos/:id` | PUT | ❌ | ❌ | ✅ (dona) |
| `/eventos/:id` | DELETE | ❌ | ❌ | ✅ (dona) |
| `/eventos/:id/contratos/:cid` | PATCH | ❌ | ✅ (própria) | ❌ |
| `/bandas` | GET | ✅ | ✅ | ✅ |
| `/bandas/:id` | GET | ✅ | ✅ | ✅ |
| `/bandas/me/agenda` | GET | ❌ | ✅ | ❌ |
| `/bandas/me/perfil` | PUT | ❌ | ✅ | ❌ |
| `/comunidades` | GET | ✅ | ✅ | ✅ |
| `/comunidades/:id` | GET | ✅ | ✅ | ✅ |
| `/comunidades/me/perfil` | PUT | ❌ | ❌ | ✅ |
| `/vendedores` | GET | ❌ | ❌ | ✅ |
| `/vendedores` | POST | ❌ | ❌ | ✅ |
| `/vendedores/:id` | DELETE | ❌ | ❌ | ✅ (dona) |
| `/vendedores/reservas/:id/confirmar` | PATCH | ✅ (vendedor) | ❌ | ✅ (dona) |
| `/reservas/eventos/:id` | POST | ✅ | ❌ | ❌ |
| `/reservas/minhas` | GET | ✅ | ❌ | ❌ |

---

## 8. Códigos de Resposta

| Código | Significado |
|---|---|
| `200` | Sucesso |
| `201` | Recurso criado com sucesso |
| `400` | Requisição inválida (campos faltando ou formato incorreto) |
| `401` | Token ausente, inválido ou expirado |
| `403` | Acesso negado (tipo de usuário sem permissão) |
| `404` | Recurso não encontrado |
| `409` | Conflito (duplicata, contrato já respondido, datas sobrepostas) |
| `422` | Não processável (ex.: nenhum vendedor disponível) |
| `429` | Rate limit excedido |
| `500` | Erro interno do servidor |

---

## 9. Testes

### Teste automatizado (recomendado)

Com o servidor rodando:

```bash
cd backend
npm start                  # terminal 1
node scripts/test-routes.js   # terminal 2
```

O script `scripts/test-routes.js` cobre **33 cenários** (todas as rotas + casos de erro 401/404/409). Usa pool de CNPJs ativos reais para cadastro de banda/comunidade.

### Testes manuais (`tests.http`)

Arquivo `src/tests.http` (compatível com REST Client para VS Code):

> **CNPJ em testes:** use CNPJs **ativos e únicos** no banco (ex.: `33.000.167/0001-01`, `07.526.557/0001-00`). CNPJs fictícios retornam `400`.

```http
### Registrar comunidade
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "email": "user2@email.com",
  "senha": "senha1234",
  "tipo": "comunidade",
  "perfil": {
    "nome_entidade": "CTG Rancho das Araucárias",
    "cnpj": "33.000.167/0001-01",
    "endereco": "Rua X, 100",
    "cidade": "Blumenau",
    "estado": "SC",
    "whatsapp": "5547999999999"
  }
}

###

### Login
# @name fazerLogin
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "user2@email.com",
  "senha": "senha123"
}

###

### Guardar token
@authToken = {{fazerLogin.response.body.token}}

###

### Criar evento (comunidade autenticada)
POST http://localhost:3000/api/eventos
Content-Type: application/json
Authorization: Bearer {{authToken}}

{
  "titulo": "Baile de Inverno",
  "descricao": "Descrição do evento",
  "data_inicio": "2026-07-02",
  "data_fim": "2026-07-02",
  "local_nome": "Parque Municipal",
  "local_endereco": "Rua Y, Blumenau, SC",
  "valor_ingresso": 50.00,
  "foto_capa_url": "https://example.com/foto.jpg",
  "bandas": [2, 7],
  "dias": [
    {
      "data": "2026-07-02",
      "hora_inicio": "20:00",
      "hora_fim": "02:00",
      "observacao": "Primeira noite"
    }
  ]
}

###

### Atualizar evento (inclui substituição de dias)
PUT http://localhost:3000/api/eventos/1
Content-Type: application/json
Authorization: Bearer {{authToken}}

{
  "titulo": "Baile de Verão",
  "dias": [
    {
      "data": "2026-07-02",
      "hora_inicio": "20:00",
      "hora_fim": "02:00"
    }
  ]
}

###

### Listar eventos públicos
GET http://localhost:3000/api/eventos

###

### Listar eventos com filtros e paginação
GET http://localhost:3000/api/eventos?cidade=Blumenau&estado=SC&pagina=1&limite=10

###

### Buscar evento por ID
GET http://localhost:3000/api/eventos/1

###

### Calendário compartilhado (comunidade)
GET http://localhost:3000/api/eventos/calendario
Authorization: Bearer {{authToken}}

###

### Logout
POST http://localhost:3000/api/auth/logout
Authorization: Bearer {{authToken}}

###

### Registrar usuário pessoal
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "email": "joao@email.com",
  "senha": "senha1234",
  "tipo": "pessoal",
  "perfil": {
    "nome": "João Silva",
    "cidade": "Blumenau",
    "estado": "SC"
  }
}

###

### Registrar banda
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "email": "banda@email.com",
  "senha": "banda123",
  "tipo": "banda",
  "perfil": {
    "nome_artistico": "Os Gaúchos",
    "estilo_musical": "Gauchesco",
    "cnpj": "07.526.557/0001-00",
    "whatsapp": "5547988887777"
  }
}

###

### Listar bandas
GET http://localhost:3000/api/bandas

###

### Listar bandas com filtro
GET http://localhost:3000/api/bandas?estilo=gauchesco&cidade=Blumenau

###

### Perfil público da banda
GET http://localhost:3000/api/bandas/2

###

### Adicionar vendedor
POST http://localhost:3000/api/vendedores
Content-Type: application/json
Authorization: Bearer {{authToken}}

{
  "nome": "Carlos Vendedor",
  "whatsapp": "5547999991111"
}

###

### Listar vendedores
GET http://localhost:3000/api/vendedores
Authorization: Bearer {{authToken}}

###

### Reservar ingresso (login como pessoal antes)
POST http://localhost:3000/api/reservas/eventos/1
Content-Type: application/json
Authorization: Bearer {{authToken}}

{
  "quantidade": 2
}

###

### Minhas reservas
GET http://localhost:3000/api/reservas/minhas
Authorization: Bearer {{authToken}}

###

### Confirmar pagamento
PATCH http://localhost:3000/api/vendedores/reservas/1/confirmar
Authorization: Bearer {{authToken}}

###

### Aceitar contrato (login como banda antes)
PATCH http://localhost:3000/api/eventos/1/contratos/1
Content-Type: application/json
Authorization: Bearer {{authTokenBanda}}

{
  "status_aceite": "aceito"
}

###

### Logout por ID (404 se ID inválido)
POST http://localhost:3000/api/auth/logout/999999
Authorization: Bearer {{authToken}}

###

### Health check
GET http://localhost:3000/api/health
```

---

## Observações Gerais

**Rate Limiting**
- Rotas de autenticação: 20 requisições por 15 minutos por IP.
- Criação de reservas: 10 requisições por minuto por IP.
- Demais rotas: 120 requisições por minuto por IP.

**Segurança**
- Senhas armazenadas com bcrypt (salt 10).
- Tokens JWT expiram em 7 dias por padrão (configurável via `JWT_EXPIRES_IN`).
- Tokens são armazenados na tabela `auth_tokens` e revogados via logout — o middleware valida a existência ativa do token no banco a cada requisição.
- Limpeza automática de tokens expirados e revogados há mais de 30 dias (na inicialização, a cada 6h e após logout).
- Headers de segurança aplicados via Helmet.

**Validações de entrada**
- **WhatsApp:** 10 a 15 dígitos (cadastro, perfis, vendedores).
- **URLs (`foto_capa_url`, `video_url`):** http(s) com domínio completo (rejeita placeholders como `https://...`).
- **CNPJ:** formato obrigatório; bloqueio quando API OpenCNPJ confirma invalidez.

**Paginação**
- Endpoints `GET /eventos`, `GET /bandas`, `GET /comunidades` retornam `{ dados, paginacao }`.
- Query: `?pagina=1&limite=20` (máximo 100 por página).
- Com filtro geográfico (`lat`, `lng`, `raio_km`), a paginação é aplicada após o filtro Haversine.

**Serviços Externos**
- **Validação de CNPJ:** [open.cnpja.com](https://open.cnpja.com) — timeout 8s; status ativo = `id: 2` / `"Ativa"`; bloqueia cadastro se inválido quando a API responde; falha de rede permite cadastro com `cnpj_validado: false`.
- **Geocodificação:** Nominatim/OpenStreetMap — timeout 8s; falha silenciosa (`latitude`/`longitude` nulos).

**Histórico de correções (jun/2026)**
- Validação CNPJ: compatibilidade com formato atual da OpenCNPJ (`status.id = 2`).
- RF06: conflito de datas na mesma cidade **bloqueia** criação (`409`).
- Paginação em listagens públicas (`dados` + `paginacao`).
- `PUT /eventos/:id` aceita array `dias` (substituição completa).
- Validação de WhatsApp (10–15 dígitos) e URLs com domínio real.
- Persistência e limpeza de tokens em `auth_tokens`.
- Filtro de bandas por cidade considera apenas contratos **aceitos**.
- Correção de parâmetros SQL dinâmicos em updates com geocodificação (comunidade/evento).
- Cast de enum PostgreSQL em `PATCH /eventos/:id/contratos/:contrato_id`.