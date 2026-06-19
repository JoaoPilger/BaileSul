import { formatCep } from './criarEventoValidation'

export { formatCep }

export function formatEmail(value) {
  return value.trim().toLowerCase()
}

export function formatPhone(value) {
  const digits = value.replace(/\D/g, '').slice(0, 11)
  if (!digits) return ''
  if (digits.length <= 2) return `(${digits}`
  if (digits.length <= 6) return `(${digits.slice(0, 2)}) ${digits.slice(2)}`
  if (digits.length <= 10) {
    return `(${digits.slice(0, 2)}) ${digits.slice(2, 6)}-${digits.slice(6)}`
  }
  return `(${digits.slice(0, 2)}) ${digits.slice(2, 7)}-${digits.slice(7)}`
}

export function formatCnpj(value) {
  const digits = value.replace(/\D/g, '').slice(0, 14)
  if (digits.length <= 2) return digits
  if (digits.length <= 5) return `${digits.slice(0, 2)}.${digits.slice(2)}`
  if (digits.length <= 8) return `${digits.slice(0, 2)}.${digits.slice(2, 5)}.${digits.slice(5)}`
  if (digits.length <= 12) {
    return `${digits.slice(0, 2)}.${digits.slice(2, 5)}.${digits.slice(5, 8)}/${digits.slice(8)}`
  }
  return `${digits.slice(0, 2)}.${digits.slice(2, 5)}.${digits.slice(5, 8)}/${digits.slice(8, 12)}-${digits.slice(12)}`
}

export function formatNameField(value, max = 60) {
  return value.replace(/[^\p{L}\s'.-]/gu, '').slice(0, max)
}

export function formatCityField(value) {
  return value.replace(/[^\p{L}\s'.-]/gu, '').slice(0, 60)
}

export function isValidCnpj(value) {
  const digits = String(value).replace(/\D/g, '')
  if (digits.length !== 14) return false
  if (/^(\d)\1+$/.test(digits)) return false

  const calcDigit = (base, weights) => {
    const sum = base.split('').reduce((acc, digit, index) => acc + Number(digit) * weights[index], 0)
    const rest = sum % 11
    return rest < 2 ? 0 : 11 - rest
  }

  const base = digits.slice(0, 12)
  const d1 = calcDigit(base, [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2])
  const d2 = calcDigit(`${base}${d1}`, [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2])
  return digits.endsWith(`${d1}${d2}`)
}

export function validateEmail(value, required = true) {
  const text = value.trim()
  if (!text) return required ? 'Informe o e-mail.' : ''
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(text)) return 'Informe um e-mail válido.'
  return ''
}

export function validatePassword(value, required = true) {
  if (!value) return required ? 'Informe a senha.' : ''
  if (value.length < 8) return 'Mínimo de 8 caracteres.'
  if (!/[a-zA-Z]/.test(value)) return 'Inclua pelo menos uma letra.'
  if (!/\d/.test(value)) return 'Inclua pelo menos um número.'
  return ''
}

export function validateConfirmPassword(value, password) {
  if (!value) return 'Confirme a senha.'
  if (value !== password) return 'As senhas não coincidem.'
  return ''
}

export function validatePhone(value, required = true) {
  const digits = value.replace(/\D/g, '')
  if (!digits) return required ? 'Informe o telefone.' : ''
  if (digits.length < 10 || digits.length > 11) {
    return 'Use o formato (XX) 9 0000-0000.'
  }
  return ''
}

export function validateCnpjField(value, required = true) {
  const text = value.trim()
  if (!text) return required ? 'Informe o CNPJ.' : ''
  if (!isValidCnpj(text)) return 'CNPJ inválido. Use 00.000.000/0000-00.'
  return ''
}

export function validateCepField(value, required = true) {
  if (!value.trim()) return required ? 'Informe o CEP.' : ''
  const digits = value.replace(/\D/g, '')
  if (digits.length !== 8) return 'CEP incompleto. Use 00000-000.'
  return ''
}

export function validateName(value, label = 'Nome', required = true, min = 2) {
  const text = value.trim()
  if (!text) return required ? `Informe ${label.toLowerCase()}.` : ''
  if (text.length < min) return `Mínimo de ${min} caracteres.`
  if (!/^[\p{L}\s'.-]+$/u.test(text)) return 'Use apenas letras.'
  return ''
}

export function validateLoginPassword(value) {
  if (!value) return 'Informe a senha.'
  return ''
}

export function validateLoginForm({ email, senha }) {
  const errors = {}
  const emailError = validateEmail(email)
  if (emailError) errors.email = emailError
  const senhaError = validateLoginPassword(senha)
  if (senhaError) errors.senha = senhaError
  return errors
}

export function validateCadastroPessoalForm(form) {
  const errors = {}
  const nome = validateName(form.nome, 'Nome', true, 2)
  if (nome) errors.nome = nome
  if (form.sobrenome.trim()) {
    const sobrenome = validateName(form.sobrenome, 'Sobrenome', false, 2)
    if (sobrenome) errors.sobrenome = sobrenome
  }
  const email = validateEmail(form.email)
  if (email) errors.email = email
  if (form.telefone.trim()) {
    const telefone = validatePhone(form.telefone, false)
    if (telefone) errors.telefone = telefone
  }
  const senha = validatePassword(form.senha)
  if (senha) errors.senha = senha
  const confirmar = validateConfirmPassword(form.confirmarSenha, form.senha)
  if (confirmar) errors.confirmarSenha = confirmar
  if (!form.termos) errors.termos = 'Aceite os termos para continuar.'
  return errors
}

export function validateCadastroBandaForm(form) {
  const errors = {}
  const nome = validateName(form.nomeBanda, 'Nome da banda', true, 2)
  if (nome) errors.nomeBanda = nome
  const telefone = validatePhone(form.telefone)
  if (telefone) errors.telefone = telefone
  const email = validateEmail(form.email)
  if (email) errors.email = email
  const cnpj = validateCnpjField(form.cnpj)
  if (cnpj) errors.cnpj = cnpj
  if (!form.estilo) errors.estilo = 'Selecione o estilo musical.'
  if (form.cidadeCriacao.trim()) {
    const cidade = validateName(form.cidadeCriacao, 'Cidade', false, 2)
    if (cidade) errors.cidadeCriacao = cidade
  }
  const senha = validatePassword(form.senha)
  if (senha) errors.senha = senha
  const confirmar = validateConfirmPassword(form.confirmarSenha, form.senha)
  if (confirmar) errors.confirmarSenha = confirmar
  if (!form.termos) errors.termos = 'Aceite os termos para continuar.'
  return errors
}

export function validateCadastroComunidadeForm(form) {
  const errors = {}
  const nome = validateName(form.nomeComunidade, 'Nome da comunidade', true, 2)
  if (nome) errors.nomeComunidade = nome
  const telefone = validatePhone(form.telefone)
  if (telefone) errors.telefone = telefone
  const email = validateEmail(form.email)
  if (email) errors.email = email
  const cnpj = validateCnpjField(form.cnpj)
  if (cnpj) errors.cnpj = cnpj
  const cep = validateCepField(form.cep)
  if (cep) errors.cep = cep
  const cidade = validateName(form.cidade, 'Cidade', true, 2)
  if (cidade) errors.cidade = cidade
  const bairro = validateName(form.bairro, 'Bairro', true, 2)
  if (bairro) errors.bairro = bairro
  if (!form.rua.trim() || form.rua.trim().length < 3) {
    errors.rua = 'Informe o endereço completo.'
  }
  const senha = validatePassword(form.senha)
  if (senha) errors.senha = senha
  const confirmar = validateConfirmPassword(form.confirmarSenha, form.senha)
  if (confirmar) errors.confirmarSenha = confirmar
  if (!form.termos) errors.termos = 'Aceite os termos para continuar.'
  return errors
}

export function validateCadastroPessoalField(name, value, form) {
  switch (name) {
    case 'nome': return validateName(value, 'Nome', true, 2)
    case 'sobrenome': return value.trim() ? validateName(value, 'Sobrenome', false, 2) : ''
    case 'email': return validateEmail(value)
    case 'telefone': return value.trim() ? validatePhone(value, false) : ''
    case 'senha': return validatePassword(value)
    case 'confirmarSenha': return validateConfirmPassword(value, form.senha)
    default: return ''
  }
}

export function validateCadastroBandaField(name, value, form) {
  switch (name) {
    case 'nomeBanda': return validateName(value, 'Nome da banda', true, 2)
    case 'telefone': return validatePhone(value)
    case 'email': return validateEmail(value)
    case 'cnpj': return validateCnpjField(value)
    case 'estilo': return value ? '' : 'Selecione o estilo musical.'
    case 'cidadeCriacao': return value.trim() ? validateName(value, 'Cidade', false, 2) : ''
    case 'senha': return validatePassword(value)
    case 'confirmarSenha': return validateConfirmPassword(value, form.senha)
    default: return ''
  }
}

export function validateCadastroComunidadeField(name, value, form) {
  switch (name) {
    case 'nomeComunidade': return validateName(value, 'Nome da comunidade', true, 2)
    case 'telefone': return validatePhone(value)
    case 'email': return validateEmail(value)
    case 'cnpj': return validateCnpjField(value)
    case 'cep': return validateCepField(value)
    case 'cidade': return validateName(value, 'Cidade', true, 2)
    case 'bairro': return validateName(value, 'Bairro', true, 2)
    case 'rua':
      if (!value.trim()) return 'Informe o endereço completo.'
      if (value.trim().length < 3) return 'Mínimo de 3 caracteres.'
      return ''
    case 'referencia': return ''
    case 'senha': return validatePassword(value)
    case 'confirmarSenha': return validateConfirmPassword(value, form.senha)
    default: return ''
  }
}
