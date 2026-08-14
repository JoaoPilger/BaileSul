/**
 * Máscaras de input reutilizáveis (CNPJ, telefone/WhatsApp, CEP).
 * Reexporta as implementações centralizadas em authFormValidation.js /
 * criarEventoValidation.js para dar um ponto único de importação aos
 * formulários, sem duplicar a lógica de formatação.
 */
export { formatCnpj, formatPhone, isValidCnpj, validateCnpjField } from './authFormValidation'
export { formatCep } from './criarEventoValidation'

/**
 * Normaliza um WhatsApp para os dígitos completos (com DDI) esperados por
 * links wa.me. Números cadastrados no formato nacional (10-11 dígitos,
 * DDD + telefone, sem DDI) ganham o prefixo do Brasil "55" — sem isso o
 * wa.me abre um número inválido/errado.
 */
export function toWhatsappLinkDigits(whatsapp) {
  const digits = String(whatsapp || '').replace(/\D/g, '')
  if (!digits) return ''
  if (digits.length >= 12 && digits.startsWith('55')) return digits
  if (digits.length === 10 || digits.length === 11) return `55${digits}`
  return digits
}
