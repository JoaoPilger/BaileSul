const { createClient } = require('@supabase/supabase-js');

// Client server-side com a Service Role Key — tem permissão total no Storage
// e ignora RLS. NUNCA expor essa key ao frontend/app/desktop.
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

// Bucket público único onde toda a mídia da aplicação é armazenada
// (capas de evento, mídias de evento, fotos/mídias de perfil de banda e comunidade).
const BUCKET = 'media';

module.exports = { supabase, BUCKET };
