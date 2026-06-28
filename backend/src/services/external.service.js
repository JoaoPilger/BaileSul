/**
 * services/external.service.js
 * Integrações externas: validação de CNPJ (OpenCNPJ) e
 * geocodificação de endereços (Nominatim / OpenStreetMap).
 */

/**
 * Valida e busca dados de um CNPJ via API pública da ReceitaWS / OpenCNPJ.
 * Retorna { valido, razao_social, situacao } ou lança erro.
 *
 * Endpoint gratuito: https://open.cnpja.com/office/:cnpj
 * Fallback: https://receitaws.com.br/v1/cnpj/:cnpj (rate-limited)
 *
 * @param {string} cnpj - CNPJ formatado (XX.XXX.XXX/XXXX-XX) ou só dígitos
 * @returns {Promise<{valido: boolean, razao_social: string|null, situacao: string|null}>}
 */
const validarCNPJ = async (cnpj) => {
  const digits = cnpj.replace(/\D/g, '');

  if (digits.length !== 14) {
    return { valido: false, apiDisponivel: true, razao_social: null, situacao: null };
  }

  try {
    const res = await fetch(`https://open.cnpja.com/office/${digits}`, {
      headers: { Accept: 'application/json' },
      signal: AbortSignal.timeout(8000),
    });

    if (!res.ok) {
      // 404 = CNPJ não existe; demais erros = API indisponível
      const apiDisponivel = res.status === 404;
      return { valido: false, apiDisponivel, razao_social: null, situacao: null };
    }

    const data = await res.json();
    const statusId = data?.status?.id;
    const statusText = (data?.status?.text || '').toLowerCase();
    const razao_social = data?.company?.name ?? null;
    const valido =
      statusId === 2 ||
      statusId === 'ATIVA' ||
      statusText === 'ativa';

    return { valido, apiDisponivel: true, razao_social, situacao: statusId ?? null };
  } catch (err) {
    console.error('[CNPJ] Erro ao consultar API:', err.message);
    return { valido: false, apiDisponivel: false, razao_social: null, situacao: null };
  }
};

/**
 * Geocodifica um endereço usando Nominatim (OpenStreetMap).
 * Retorna { latitude, longitude } ou null se não encontrado.
 *
 * Política de uso Nominatim: max 1 req/s, User-Agent obrigatório.
 *
 * @param {string} endereco - Endereço completo ou cidade+estado
 * @returns {Promise<{latitude: number, longitude: number}|null>}
 */
const geocodificarEnderecoBase = async (endereco) => {
  if (!endereco || endereco.trim().length < 3) return null;

  try {
    const query = encodeURIComponent(endereco);
    const url = `https://nominatim.openstreetmap.org/search?q=${query}&format=json&limit=1&countrycodes=br`;

    const res = await fetch(url, {
      headers: {
        'User-Agent': 'BaileSul/1.0 (projeto-integrador@ifc.edu.br)',
        Accept: 'application/json',
      },
      signal: AbortSignal.timeout(8000),
    });

    if (!res.ok) return null;

    const data = await res.json();
    if (!data || data.length === 0) return null;

    return {
      latitude: parseFloat(data[0].lat),
      longitude: parseFloat(data[0].lon),
    };
  } catch (err) {
    console.error('[Nominatim] Erro ao geocodificar:', err.message);
    return null;
  }
};

/**
 * Geocodifica usando parâmetros estruturados do Nominatim para maior precisão.
 * @param {{ street?: string, city?: string, postalcode?: string }} params
 * @returns {Promise<{latitude: number, longitude: number}|null>}
 */
const geocodificarEstruturado = async ({ street, city, postalcode }) => {
  const qs = new URLSearchParams({ format: 'json', limit: '1', countrycodes: 'br' });
  if (street)     qs.set('street', street);
  if (city)       qs.set('city', city);
  if (postalcode) qs.set('postalcode', postalcode.replace(/\D/g, ''));

  try {
    const url = `https://nominatim.openstreetmap.org/search?${qs}`;
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'BaileSul/1.0 (projeto-integrador@ifc.edu.br)',
        Accept: 'application/json',
      },
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return null;
    const data = await res.json();
    if (!data || data.length === 0) return null;
    return { latitude: parseFloat(data[0].lat), longitude: parseFloat(data[0].lon) };
  } catch {
    return null;
  }
};

/**
 * Geocodifica um endereço usando Nominatim.
 * Tenta primeiro uma busca estruturada (street + city + postalcode)
 * e depois cai para buscas progressivas por query livre.
 */
const geocodificarEndereco = async (endereco) => {
  if (!endereco || endereco.trim().length < 3) return null;

  // Separa os componentes (rua, bairro, referencia, cidade, cep)
  const parts = endereco.split(',').map(p => p.trim()).filter(Boolean);

  // Detecta um CEP no último componente
  const cepCandidate = parts.length > 0 ? parts[parts.length - 1] : '';
  const hasCep = /^\d{5}-?\d{3}$/.test(cepCandidate.replace(/\D/g, '').length === 8 ? cepCandidate : '');

  // Tenta montar busca estruturada
  if (parts.length >= 2) {
    const postalcode = hasCep ? cepCandidate : undefined;
    // A cidade é o penúltimo componente (ou último se não houver CEP)
    const cityIdx = hasCep ? parts.length - 2 : parts.length - 1;
    const city = parts[cityIdx] || undefined;
    // A rua é o primeiro componente (se houver mais de 2 partes)
    const street = cityIdx > 0 ? parts[0] : undefined;

    // 1) rua + cidade + cep
    if (street && city) {
      const coords = await geocodificarEstruturado({ street, city, postalcode });
      if (coords) return coords;
    }
    // 2) só cidade + cep
    if (city) {
      const coords = await geocodificarEstruturado({ city, postalcode });
      if (coords) return coords;
    }
  }

  // Fallback: busca livre progressiva removendo partes da esquerda
  let remaining = [...parts];
  while (remaining.length > 0) {
    const coords = await geocodificarEnderecoBase(remaining.join(', '));
    if (coords) return coords;
    remaining.shift();
  }

  return null;
};

/**
 * Calcula a distância em km entre dois pontos usando a fórmula de Haversine.
 * Substitui a dependência geolib para manter o código sem dependências extras
 * nessa função utilitária simples.
 *
 * @param {number} lat1
 * @param {number} lon1
 * @param {number} lat2
 * @param {number} lon2
 * @returns {number} distância em km
 */
const calcularDistanciaKm = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // raio da Terra em km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

module.exports = { validarCNPJ, geocodificarEndereco, calcularDistanciaKm };