import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { token, title, body } = await req.json()

    if (!token || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: token, title, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Test simple : confirmer que la fonction reçoit les données correctement
    console.log(`Received notification request:`)
    console.log(`- Token: ${token.substring(0, 20)}...`)
    console.log(`- Title: ${title}`)
    console.log(`- Body: ${body}`)

    // Vérifier que les credentials Firebase sont disponibles
    const firebaseKey = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')
    
    if (!firebaseKey) {
      return new Response(
        JSON.stringify({ 
          error: 'FIREBASE_SERVICE_ACCOUNT_KEY not found',
          sent: false 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let serviceAccount
    try {
      serviceAccount = JSON.parse(firebaseKey)
      console.log(`✅ Service account parsed: ${serviceAccount.client_email}`)
    } catch (parseError) {
      console.error('❌ JSON parse error:', parseError.message)
      return new Response(
        JSON.stringify({ 
          error: 'Invalid service account JSON',
          details: parseError.message,
          sent: false 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Test de base réussi - pour l'instant on confirme juste que tout est configuré
    return new Response(
      JSON.stringify({ 
        message: 'Test successful - Firebase config loaded',
        service_account_email: serviceAccount.client_email,
        project_id: serviceAccount.project_id,
        token_received: `${token.substring(0, 20)}...`,
        sent: false, // Pas encore d'envoi réel
        next_step: 'Implement actual FCM sending'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in test function:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: error.message 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})