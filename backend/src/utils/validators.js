/**
 * Valida número de WhatsApp para links wa.me.
 * Aceita 10–15 dígitos (com ou sem +, espaços, parênteses).
 */
const whatsappValido = (whatsapp) => {
  if (!whatsapp || typeof whatsapp !== 'string') return false;
  const digits = whatsapp.replace(/\D/g, '');
  return digits.length >= 10 && digits.length <= 15;
};

/**
 * Normaliza um WhatsApp para os dígitos completos (com DDI) esperados por
 * links wa.me. Números cadastrados no formato nacional (10-11 dígitos,
 * DDD + telefone, sem DDI) ganham o prefixo do Brasil "55" — sem isso o
 * wa.me abre um número inválido/errado.
 */
const normalizarWhatsapp = (whatsapp) => {
  const digits = String(whatsapp || '').replace(/\D/g, '');
  if (!digits) return '';
  if (digits.length >= 12 && digits.startsWith('55')) return digits;
  if (digits.length === 10 || digits.length === 11) return `55${digits}`;
  return digits;
};

/**
 * Valida URL http(s) com hostname mínimo (evita "https://..." placeholder).
 */
const urlHttpValida = (url) => {
  if (!url) return true;
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return false;
    return parsed.hostname.includes('.') && parsed.hostname.length >= 4;
  } catch {
    return false;
  }
};

/**
 * Valida formato de CNPJ (XX.XXX.XXX/XXXX-XX).
 */
const cnpjFormatoValido = (cnpj) =>
  /^\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}$/.test(cnpj);

module.exports = { whatsappValido, normalizarWhatsapp, urlHttpValida, cnpjFormatoValido };
