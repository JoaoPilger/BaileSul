import { useEffect, useState } from 'react'
import { cn } from '../../utils/cn';
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import Header from '../../components/header/Header'
import Footer from '../../components/footer/Footer'
import { loadEventById } from '../../utils/events'
import styles from './eventos.module.css';

function formatDate(dateValue) {
  if (!dateValue) return 'Não informado'
  const date = new Date(dateValue)
  return date.toLocaleDateString('pt-BR', {
    weekday: 'long', day: '2-digit', month: 'long', year: 'numeric',
  })
}

export default function EventoDetalhes() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [event, setEvent] = useState(null)

  useEffect(() => {
    loadEventById(id).then(setEvent)
  }, [id])

  if (!event) {
    return (
      <>
        <Header />
        <main className={styles['event-detail-page']}>
          <div className={styles['event-detail-empty']}>
            <h2>Evento não encontrado</h2>
            <p>Esse evento pode ter sido removido ou não existe mais.</p>
            <button className={cn(styles['btn'], styles['btn-primary'])} onClick={() => navigate('/eventos')}>
              Voltar para eventos
            </button>
          </div>
        </main>
        <Footer />
      </>
    )
  }

  return (
    <>
      <Header />
      <main className={styles['event-detail-page']}>
        <section className={styles['event-cover']} style={{ backgroundImage: `url(${event.image})` }}>
          <div className={styles['event-cover-overlay']} />
          <button className={styles['event-cover-back']} onClick={() => navigate(-1)}>
            <ArrowLeft size={16} /> Voltar
          </button>
        </section>

        <section className={styles['event-detail-content']}>
          <div className={styles['event-detail-left']}>
            <span className={styles['event-type']}>{event.style || 'Evento'}</span>
            <h1>{event.title}</h1>
            <p className={styles['event-subtitle']}>{event.band || 'Detalhes do evento'}</p>

            <div className={styles['event-detail-panel']}>
              <div className={styles['event-detail-panel-header']}>
                <div>
                  <span className={styles['panel-label']}>Sobre o Evento</span>
                  <p className={styles['panel-title']}>Informações do evento</p>
                </div>
                <button type="button" className={cn(styles['btn'], styles['btn-primary'], styles['btn-share'])}>Compartilhar evento</button>
              </div>

              <div className={styles['event-detail-panel-body']}>
                <p>
                  {event.description || `Esse evento está localizado em ${event.city || 'cidade não informada'} e foi cadastrado como um baile de ${event.style}.`}
                  {event.referencia ? ` A referência é: ${event.referencia}.` : ''}
                </p>
              </div>

              {event.vendors?.length > 0 && (
                <div className={styles['event-detail-vendors']}>
                  <h2>Vendedores</h2>
                  <ul>
                    {event.vendors.map((vendor) => (
                      <li key={vendor.id}>{vendor.name}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          </div>

          <aside className={styles['event-detail-right']}>
            <div className={styles['event-detail-info-card']}>
              <ul className={styles['event-detail-info-list']}>
                <li>
                  <span>Data</span>
                  <strong>{formatDate(event.date)}</strong>
                </li>
                <li>
                  <span>Horários</span>
                  <strong>{event.time_start || 'Não informado'} • {event.time_end || 'Não informado'}</strong>
                </li>
                <li>
                  <span>Local</span>
                  <strong>{event.city || 'Não informado'}</strong>
                </li>
                <li>
                  <span>CEP</span>
                  <strong>{event.cep || 'Não informado'}</strong>
                </li>
                <li>
                  <span>Bairro</span>
                  <strong>{event.bairro || 'Não informado'}</strong>
                </li>
                <li>
                  <span>Rua</span>
                  <strong>{event.rua || 'Não informado'}</strong>
                </li>
              </ul>
            </div>

            <div className={styles['event-detail-price-card']}>
              <div className={styles['event-detail-price-label']}>Valor do ingresso</div>
              <div className={styles['event-detail-price-row']}>
                <strong>{event.price || 'Grátis'}</strong>
                <button type="button" className={cn(styles['btn'], styles['btn-primary'], styles['btn-reserve'])}>Reservar</button>
              </div>
            </div>
          </aside>
        </section>
      </main>
      <Footer />
    </>
  )
}
