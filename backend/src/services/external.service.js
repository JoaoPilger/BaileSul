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
  // Normaliza: remove pontos, barras e hífens
  const digits = cnpj.replace(/\D/g, '');

  if (digits.length !== 14) {
    return { valido: false, razao_social: null, situacao: null };
  }

  try {
    const res = await fetch(`https://open.cnpja.com/office/${digits}`, {
      headers: { Accept: 'application/json' },
      signal: AbortSignal.timeout(8000),
    });

    if (!res.ok) {
      // CNPJ não encontrado ou erro na API — trata como inválido
      return { valido: false, razao_social: null, situacao: null };
    }

    const data = await res.json();

    // open.cnpja.com retorna status.id = 'ATIVA' quando ativo
    const situacao = data?.status?.id ?? null;
    const razao_social = data?.company?.name ?? null;
    const valido = situacao === 'ATIVA';

    return { valido, razao_social, situacao };
  } catch (err) {
    console.error('[CNPJ] Erro ao consultar API:', err.message);
    // Em caso de falha na API externa, não bloqueia o cadastro;
    // apenas registra como não validado (cnpj_validado = false).
    return { valido: false, razao_social: null, situacao: null };
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
const geocodificarEndereco = async (endereco) => {
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