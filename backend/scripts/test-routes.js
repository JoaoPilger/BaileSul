/**
 * Teste integrado de todas as rotas da API BaileSul.
 * Uso: node scripts/test-routes.js
 * Requer: servidor rodando em BASE_URL (padrão http://localhost:3000)
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const BASE = process.env.TEST_BASE_URL || 'http://localhost:3000/api';
const ts = Date.now();

const CNPJS_COMUNIDADE = [
  '33.000.167/0001-01',
  '60.701.190/0001-04',
  '00.000.000/0001-91',
];
const CNPJS_BANDA = [
  '61.186.680/0001-74',
  '07.526.557/0001-00',
];

async function registerComCnpj(body, cnpjPool) {
  for (const cnpj of cnpjPool) {
    const res = await req('POST', '/auth/register', {
      expect: [201, 409],
      body: { ...body, perfil: { ...body.perfil, cnpj } },
    });
    if (res.status === 201) return res;
    if (res.status === 409 && res.data?.error?.includes('CNPJ')) continue;
    return res;
  }
  return { ok: false, status: 409, data: { error: 'Todos os CNPJs do pool já estão em uso' } };
}
let passed = 0;
let failed = 0;
let skipped = 0;

const state = {
  tokens: {},
  ids: {},
};

async function req(method, path, { body, token, expect } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;

  const opts = { method, headers };
  if (body !== undefined) opts.body = JSON.stringify(body);

  let res;
  let data;
  try {
    res = await fetch(`${BASE}${path}`, opts);
    const text = await res.text();
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      data = text;
    }
  } catch (err) {
    return { ok: false, networkError: err.message, status: 0, data: null };
  }

  const statusOk = expect ? expect.includes(res.status) : res.ok;
  return { ok: statusOk, status: res.status, data, res };
}

const results = [];

function record(name, result, note = '') {
  const entry = {
    rota: name,
    status: result.status,
    ok: result.ok,
    note,
    erro: result.ok ? undefined : (result.data?.error || result.networkError || JSON.stringify(result.data)?.slice(0, 120)),
  };
  results.push(entry);
  if (result.skipped) {
    skipped++;
    console.log(`⏭  ${name} — ${note}`);
  } else if (result.ok) {
    passed++;
    console.log(`✅ ${name} — ${result.status}${note ? ` (${note})` : ''}`);
  } else {
    failed++;
    console.log(`❌ ${name} — ${result.status} — ${entry.erro}`);
  }
  return result;
}

function skip(name, note) {
  record(name, { ok: false, skipped: true, status: 'SKIP' }, note);
}

async function main() {
  console.log(`\n🧪 BaileSul — teste de rotas\nBase: ${BASE}\n`);

  // ── Health ──────────────────────────────────────────────────────────────
  record('GET /health', await req('GET', '/health', { expect: [200] }));

  // ── Auth: register 3 tipos ───────────────────────────────────────────────
  const comEmail = `comunidade_${ts}@test.com`;
  const bandaEmail = `banda_${ts}@test.com`;
  const pessoalEmail = `pessoal_${ts}@test.com`;
  const senha = 'senha1234';

  const regCom = await registerComCnpj(
    {
      email: comEmail,
      senha,
      tipo: 'comunidade',
      perfil: {
        nome_entidade: `CTG Teste ${ts}`,
        endereco: 'Rua Teste, 100',
        cidade: 'Blumenau',
        estado: 'SC',
        whatsapp: '5547999887766',
      },
    },
    CNPJS_COMUNIDADE
  );
  record('POST /auth/register (comunidade)', regCom);
  if (regCom.ok) {
    state.tokens.comunidade = regCom.data.token;
    state.ids.comunidade = regCom.data.usuario_id;
  }

  const regBanda = await registerComCnpj(
    {
      email: bandaEmail,
      senha,
      tipo: 'banda',
      perfil: {
        nome_artistico: `Banda Teste ${ts}`,
        estilo_musical: 'Vanera',
        whatsapp: '5547988776655',
      },
    },
    CNPJS_BANDA
  );
  record('POST /auth/register (banda)', regBanda);
  if (regBanda.ok) {
    state.tokens.banda = regBanda.data.token;
    state.ids.banda = regBanda.data.usuario_id;
  }

  const regPessoal = await req('POST', '/auth/register', {
    expect: [201],
    body: {
      email: pessoalEmail,
      senha,
      tipo: 'pessoal',
      perfil: { nome: 'Comprador Teste', cidade: 'Blumenau', estado: 'SC' },
    },
  });
  record('POST /auth/register (pessoal)', regPessoal);
  if (regPessoal.ok) {
    state.tokens.pessoal = regPessoal.data.token;
    state.ids.pessoal = regPessoal.data.usuario_id;
  }

  // Login
  const loginCom = await req('POST', '/auth/login', {
    expect: [200],
    body: { email: comEmail, senha },
  });
  record('POST /auth/login (comunidade)', loginCom);
  if (loginCom.ok) state.tokens.comunidade = loginCom.data.token;

  // Validações auth
  record(
    'POST /auth/login (credenciais inválidas → 401)',
    await req('POST', '/auth/login', { expect: [401], body: { email: comEmail, senha: 'errada' } })
  );

  if (!state.tokens.comunidade) {
    console.log('\n⚠️  Sem token de comunidade — abortando testes autenticados.\n');
    printSummary();
    process.exit(1);
  }

  // ── Comunidades (público) ──────────────────────────────────────────────
  record('GET /comunidades', await req('GET', '/comunidades?pagina=1&limite=5', { expect: [200] }));
  if (state.ids.comunidade) {
    record(
      'GET /comunidades/:id',
      await req('GET', `/comunidades/${state.ids.comunidade}`, { expect: [200] })
    );
  }

  record(
    'PUT /comunidades/me/perfil',
    await req('PUT', '/comunidades/me/perfil', {
      token: state.tokens.comunidade,
      expect: [200],
      body: { descricao: 'Perfil atualizado pelo teste' },
    })
  );

  // ── Bandas (público) ─────────────────────────────────────────────────────
  record('GET /bandas', await req('GET', '/bandas?pagina=1&limite=5', { expect: [200] }));
  if (state.ids.banda) {
    record('GET /bandas/:id', await req('GET', `/bandas/${state.ids.banda}`, { expect: [200] }));
    record(
      'GET /bandas/me/agenda',
      await req('GET', '/bandas/me/agenda', { token: state.tokens.banda, expect: [200] })
    );
    record(
      'PUT /bandas/me/perfil',
      await req('PUT', '/bandas/me/perfil', {
        token: state.tokens.banda,
        expect: [200],
        body: { descricao: 'Vitrine banda teste' },
      })
    );
  }

  // ── Eventos ──────────────────────────────────────────────────────────────
  record('GET /eventos', await req('GET', '/eventos?pagina=1&limite=5', { expect: [200] }));

  record(
    'GET /eventos/calendario',
    await req('GET', '/eventos/calendario', { token: state.tokens.comunidade, expect: [200] })
  );

  // Criar evento com banda
  const dataEvento = '2027-06-15';
  const criarEvt = await req('POST', '/eventos', {
    token: state.tokens.comunidade,
    expect: [201],
    body: {
      titulo: `Baile Teste ${ts}`,
      descricao: 'Evento criado pelo script de teste',
      data_inicio: dataEvento,
      data_fim: dataEvento,
      local_nome: 'Parque Teste',
      local_endereco: 'Rua Y, Blumenau, SC',
      valor_ingresso: 30,
      foto_capa_url: 'https://example.com/capa-teste.jpg',
      bandas: state.ids.banda ? [state.ids.banda] : [],
      dias: [{ data: dataEvento, hora_inicio: '20:00', hora_fim: '23:59' }],
    },
  });
  record('POST /eventos', criarEvt);
  if (criarEvt.ok) state.ids.evento = criarEvt.data.evento_id;

  if (state.ids.evento) {
    const detEvt = await req('GET', `/eventos/${state.ids.evento}`, { expect: [200] });
    record('GET /eventos/:id', detEvt);
    if (detEvt.ok && detEvt.data.bandas?.length) {
      state.ids.contrato = detEvt.data.bandas[0].usuario_id
        ? (await req('GET', `/eventos/${state.ids.evento}`)).data.bandas
        : null;
      // contrato id vem da query interna — buscar via detalhe
      const bandasDet = detEvt.data.bandas;
      // Precisamos do contrato_id — buscar no banco via resposta parcial
      // O GET evento retorna bandas sem contrato id; buscar via PATCH tentativa
    }

    record(
      'PUT /eventos/:id',
      await req('PUT', `/eventos/${state.ids.evento}`, {
        token: state.tokens.comunidade,
        expect: [200],
        body: {
          titulo: `Baile Teste Atualizado ${ts}`,
          dias: [{ data: dataEvento, hora_inicio: '19:00', hora_fim: '23:00' }],
        },
      })
    );
  }

  // Contrato: buscar id via pool se necessário — usar fetch alternativo
  if (state.ids.evento && state.tokens.banda) {
    const { Pool } = require('pg');
    const pool = new Pool({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
    });
    try {
      const { rows } = await pool.query(
        'SELECT id FROM contratos WHERE evento_id = $1 AND banda_id = $2',
        [state.ids.evento, state.ids.banda]
      );
      if (rows.length) {
        state.ids.contrato = rows[0].id;
        record(
          'PATCH /eventos/:id/contratos/:contrato_id (aceitar)',
          await req('PATCH', `/eventos/${state.ids.evento}/contratos/${state.ids.contrato}`, {
            token: state.tokens.banda,
            expect: [200],
            body: { status_aceite: 'aceito' },
          })
        );
      } else {
        skip('PATCH /eventos/:id/contratos/:contrato_id', 'contrato não encontrado');
      }
    } finally {
      await pool.end();
    }
  }

  // ── Vendedores ───────────────────────────────────────────────────────────
  const addVend = await req('POST', '/vendedores', {
    token: state.tokens.comunidade,
    expect: [201],
    body: { nome: 'Vendedor Teste', whatsapp: '5547999111222' },
  });
  record('POST /vendedores', addVend);
  if (addVend.ok) state.ids.vendedor = addVend.data.vendedor?.id;

  record(
    'GET /vendedores',
    await req('GET', '/vendedores', { token: state.tokens.comunidade, expect: [200] })
  );

  // Vendedor vinculado a pessoal (modo B)
  if (state.ids.pessoal) {
    record(
      'POST /vendedores (vincular pessoal)',
      await req('POST', '/vendedores', {
        token: state.tokens.comunidade,
        expect: [201],
        body: {
          nome: 'Vendedor Pessoal',
          whatsapp: '5547999334455',
          usuario_id: state.ids.pessoal,
        },
      })
    );
  }

  // ── Reservas ─────────────────────────────────────────────────────────────
  if (state.ids.evento && state.tokens.pessoal) {
    const reserva = await req('POST', `/reservas/eventos/${state.ids.evento}`, {
      token: state.tokens.pessoal,
      expect: [201],
      body: { quantidade: 2 },
    });
    record('POST /reservas/eventos/:evento_id', reserva);
    if (reserva.ok) state.ids.reserva = reserva.data.reserva_id;

    record(
      'GET /reservas/minhas',
      await req('GET', '/reservas/minhas', { token: state.tokens.pessoal, expect: [200] })
    );

    if (state.ids.reserva) {
      record(
        'PATCH /vendedores/reservas/:id/confirmar (comunidade)',
        await req('PATCH', `/vendedores/reservas/${state.ids.reserva}/confirmar`, {
          token: state.tokens.comunidade,
          expect: [200],
        })
      );
    }
  } else {
    skip('POST /reservas/eventos/:evento_id', 'sem evento ou token pessoal');
    skip('GET /reservas/minhas', 'sem token pessoal');
  }

  // ── DELETE vendedor + DELETE evento ──────────────────────────────────────
  if (state.ids.vendedor) {
    record(
      'DELETE /vendedores/:id',
      await req('DELETE', `/vendedores/${state.ids.vendedor}`, {
        token: state.tokens.comunidade,
        expect: [200],
      })
    );
  }

  // Criar segundo evento para testar conflito RF06
  record(
    'POST /eventos (conflito datas → 409)',
    await req('POST', '/eventos', {
      token: state.tokens.comunidade,
      expect: [409],
      body: {
        titulo: 'Conflito Teste',
        data_inicio: dataEvento,
        data_fim: dataEvento,
      },
    })
  );

  if (state.ids.evento) {
    record(
      'DELETE /eventos/:id (cancelar)',
      await req('DELETE', `/eventos/${state.ids.evento}`, {
        token: state.tokens.comunidade,
        expect: [200],
      })
    );
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  record(
    'POST /auth/logout',
    await req('POST', '/auth/logout', {
      token: state.tokens.pessoal,
      expect: [200],
    })
  );

  // Re-login comunidade para testes finais de logout por id
  const relogin = await req('POST', '/auth/login', {
    expect: [200],
    body: { email: comEmail, senha },
  });
  if (relogin.ok) state.tokens.comunidade = relogin.data.token;

  record(
    'POST /auth/logout/:id (token inexistente → 404)',
    await req('POST', '/auth/logout/999999', {
      token: state.tokens.comunidade,
      expect: [404],
    })
  );

  record(
    'POST /auth/logout (comunidade)',
    await req('POST', '/auth/logout', {
      token: state.tokens.comunidade,
      expect: [200],
    })
  );

  record(
    'GET /eventos/calendario (token revogado → 401)',
    await req('GET', '/eventos/calendario', {
      token: state.tokens.comunidade,
      expect: [401],
    })
  );

  // 404
  record('GET /rota-inexistente → 404', await req('GET', '/inexistente', { expect: [404] }));

  printSummary();
  process.exit(failed > 0 ? 1 : 0);
}

function printSummary() {
  console.log('\n' + '─'.repeat(50));
  console.log(`Resultado: ${passed} ok | ${failed} falha(s) | ${skipped} pulado(s) | ${results.length} total`);
  if (failed > 0) {
    console.log('\nFalhas:');
    results.filter((r) => !r.ok && !r.note?.includes('SKIP')).forEach((r) => {
      console.log(`  • ${r.rota}: ${r.erro}`);
    });
  }
  console.log('');
}

main().catch((err) => {
  console.error('Erro fatal:', err);
  process.exit(1);
});
