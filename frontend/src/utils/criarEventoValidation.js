const MAX_IMAGE_BYTES = 5 * 1024 * 1024
const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp']

export function formatCep(value) {
  const digits = value.replace(/\D/g, '').slice(0, 8)
  if (digits.length <= 5) return digits
  return `${digits.slice(0, 5)}-${digits.slice(5)}`
}

export function formatPriceInput(value) {
  const trimmed = value.trim()
  if (!trimmed) return ''
  if (/^g(rátis|ratis)?$/i.test(trimmed)) {
    const lower = trimmed.toLowerCase()
    if (lower.startsWith('gr')) return lower.charAt(0).toUpperCase() + lower.slice(1)
  }
  if (/^g/i.test(trimmed) && !/^\d/.test(trimmed)) {
    return trimmed.replace(/[^a-zA-ZáàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ]/g, '').slice(0, 6)
  }

  let raw = trimmed.replace(/^R\$\s*/i, '').replace(/[^\d,]/g, '')
  const parts = raw.split(',')
  if (parts.length > 2) raw = `${parts[0]},${parts.slice(1).join('')}`
  if (parts.length === 2) raw = `${parts[0]},${parts[1].slice(0, 2)}`
  return raw.slice(0, 12)
}

export function formatPriceBlur(value) {
  const trimmed = value.trim()
  if (!trimmed || /^(grátis|gratis)$/i.test(trimmed)) return 'Grátis'
  const normalized = trimmed.replace(/^R\$\s*/i, '').replace(',', '.')
  const num = parseFloat(normalized)
  if (Number.isNaN(num) || num <= 0) return trimmed
  return num.toFixed(2).replace('.', ',')
}

export function formatTextField(value, maxLength) {
  return value.slice(0, maxLength)
}

export function formatCityField(value) {
  return value.replace(/[^\p{L}\s'.-]/gu, '').slice(0, 60)
}

export function validateImageFile(file) {
  if (!file) return ''
  if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
    return 'Use uma imagem PNG, JPG ou WEBP.'
  }
  if (file.size > MAX_IMAGE_BYTES) {
    return 'A imagem deve ter no máximo 5 MB.'
  }
  return ''
}

export function validateField(name, value, form = {}) {
  switch (name) {
    case 'title': {
      const text = value.trim()
      if (!text) return 'Informe o título do evento.'
      if (text.length < 3) return 'Mínimo de 3 caracteres.'
      if (/^\d+$/.test(text)) return 'O título não pode conter apenas números.'
      return ''
    }
    case 'band': {
      if (form.tipoEvento && form.tipoEvento !== 'musical') return ''
      const text = value.trim()
      if (!text) return 'Informe a banda ou artista.'
      if (text.length < 2) return 'Mínimo de 2 caracteres.'
      return ''
    }
    case 'descricao': {
      if (!value) return ''
      if (value.trim().length > 0 && value.trim().length < 10) {
        return 'Descreva um pouco mais o evento (mín. 10 caracteres).'
      }
      return ''
    }
    case 'price': {
      const text = value.trim()
      if (!text) return ''
      if (/^(grátis|gratis)$/i.test(text)) return ''
      const amount = text.replace(/^R\$\s*/i, '').replace(',', '.')
      if (!/^\d+(\.\d{1,2})?$/.test(amount)) {
        return 'Use números (ex: 20 ou 20,00) ou escreva Grátis.'
      }
      if (parseFloat(amount) <= 0) return 'O valor deve ser maior que zero.'
      return ''
    }
    case 'dateStart': {
      if (!value) return 'Informe a data de início.'
      return ''
    }
    case 'dateEnd': {
      if (!value) return ''
      if (form.dateStart && value < form.dateStart) {
        return 'A data de término não pode ser anterior ao início.'
      }
      return ''
    }
    case 'timeStart':
      return ''
    case 'timeEnd': {
      if (!value || !form.timeStart) return ''
      const sameDay = !form.dateEnd || form.dateEnd === form.dateStart
      if (sameDay && value <= form.timeStart) {
        return 'O horário de término deve ser após o início.'
      }
      return ''
    }
    case 'cep': {
      if (!value.trim()) return ''
      const digits = value.replace(/\D/g, '')
      if (digits.length !== 8) return 'CEP incompleto. Use o formato 00000-000.'
      return ''
    }
    case 'city': {
      const text = value.trim()
      if (!text) return 'Informe a cidade.'
      if (text.length < 2) return 'Mínimo de 2 caracteres.'
      if (!/^[\p{L}\s'.-]+$/u.test(text)) return 'Use apenas letras.'
      return ''
    }
    case 'bairro': {
      if (!value.trim()) return ''
      if (value.trim().length < 2) return 'Mínimo de 2 caracteres.'
      return ''
    }
    case 'rua': {
      if (!value.trim()) return ''
      if (value.trim().length < 3) return 'Informe o endereço completo.'
      return ''
    }
    case 'referencia':
      return ''
    default:
      return ''
  }
}

export function validateVendorName(value) {
  const text = value.trim()
  if (!text) return 'Informe o nome do vendedor.'
  if (text.length < 2) return 'Mínimo de 2 caracteres.'
  return ''
}

export function validateForm(form) {
  const fields = [
    'title',
    'band',
    'descricao',
    'price',
    'dateStart',
    'dateEnd',
    'timeStart',
    'timeEnd',
    'cep',
    'city',
    'bairro',
    'rua',
    'referencia',
  ]
  const errors = {}
  fields.forEach((field) => {
    const message = validateField(field, form[field], form)
    if (message) errors[field] = message
  })
  return errors
}