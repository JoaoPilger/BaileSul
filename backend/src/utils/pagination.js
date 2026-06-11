const LIMITE_PADRAO = 20;
const LIMITE_MAX = 100;

/**
 * Extrai pagina/limite da query string.
 * Suporta ?pagina=&limite= ou ?page=&limit=
 */
const parsePaginacao = (query) => {
  let pagina = parseInt(query.pagina ?? query.page ?? '1', 10);
  let limite = parseInt(query.limite ?? query.limit ?? String(LIMITE_PADRAO), 10);

  if (Number.isNaN(pagina) || pagina < 1) pagina = 1;
  if (Number.isNaN(limite) || limite < 1) limite = LIMITE_PADRAO;
  if (limite > LIMITE_MAX) limite = LIMITE_MAX;

  return { pagina, limite, offset: (pagina - 1) * limite };
};

const respostaPaginada = (dados, pagina, limite, total) => ({
  dados,
  paginacao: {
    pagina,
    limite,
    total,
    total_paginas: Math.ceil(total / limite) || 0,
  },
});

module.exports = { parsePaginacao, respostaPaginada, LIMITE_PADRAO, LIMITE_MAX };
