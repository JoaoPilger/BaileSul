const STORAGE_KEY = 'bailesul_events'
const HIDDEN_KEY = 'bailesul_deleted_event_ids'

const MOCK_EVENTS = [
  {
    id: 1,
    title: 'Baile do Rancho' ,
    date: '2025-06-14',
    city: 'Concórdia',
    style: 'sertanejo',
    image: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80',
    price: 'R$ 30',
  },
  {
    id: 2,
    title: 'Forró na Praça',
    date: '2025-06-21',
    city: 'Seara',
    style: 'forro',
    image: 'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=600&q=80',
    price: 'Grátis',
  },
  {
    id: 3,
    title: 'Noite Gaúcha',
    date: '2025-06-28',
    city: 'Peritiba',
    style: 'gaucha',
    image: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=600&q=80',
    price: 'R$ 20',
  },
]

function getHiddenIds() {
  try {
    const raw = localStorage.getItem(HIDDEN_KEY)
    return raw ? new Set(JSON.parse(raw).map(String)) : new Set()
  } catch {
    return new Set()
  }
}

export function loadEvents() {
  const hiddenIds = getHiddenIds()
  const raw = localStorage.getItem(STORAGE_KEY)
  const savedEvents = raw ? JSON.parse(raw) : []

  const byId = new Map()
  savedEvents.forEach((event) => {
    const id = String(event.id)
    if (!hiddenIds.has(id)) byId.set(id, event)
  })

  MOCK_EVENTS.forEach((event) => {
    const id = String(event.id)
    if (!hiddenIds.has(id) && !byId.has(id)) {
      byId.set(id, event)
    }
  })

  return Array.from(byId.values())
}

export function loadEventById(id) {
  if (!id) return null
  const target = String(id)
  return loadEvents().find((event) => String(event.id) === target) || null
}

export function deleteEventById(id) {
  if (!id) return
  const target = String(id)

  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw) {
      const savedEvents = JSON.parse(raw).filter((event) => String(event.id) !== target)
      localStorage.setItem(STORAGE_KEY, JSON.stringify(savedEvents))
    }

    const hiddenIds = getHiddenIds()
    hiddenIds.add(target)
    localStorage.setItem(HIDDEN_KEY, JSON.stringify(Array.from(hiddenIds)))
  } catch (err) {
    console.error('Erro ao excluir evento', err)
  }
}
