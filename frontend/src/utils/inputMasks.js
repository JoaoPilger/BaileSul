/**
 * Máscaras de input reutilizáveis (CNPJ, telefone/WhatsApp, CEP).
 * Reexporta as implementações centralizadas em authFormValidation.js /
 * criarEventoValidation.js para dar um ponto único de importação aos
 * formulários, sem duplicar a lógica de formatação.
 */
export { formatCnpj, formatPhone, isValidCnpj, validateCnpjField } from './authFormValidation'
export { formatCep } from './criarEventoValidation'
