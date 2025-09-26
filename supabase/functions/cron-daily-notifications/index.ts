import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const now = new Date()
    console.log(`🕐 Cron job triggered at: ${now.toISOString()}`)

    const supabaseUrl = Deno.env.get('PROJECT_URL') ?? Deno.env.get('SUPABASE_URL')
    if (!supabaseUrl) {
      throw new Error('Missing Supabase URL in environment (PROJECT_URL)')
    }

    const serviceRoleKey = Deno.env.get('SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (!serviceRoleKey) {
      throw new Error('Missing service role key in environment (SERVICE_ROLE_KEY)')
    }

    console.log('📧 Triggering send-daily-notifications edge function...')

    const response = await fetch(`${supabaseUrl}/functions/v1/send-daily-notifications`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({
        trigger: 'cron',
        timestamp: now.toISOString(),
      }),
    })

    const result = await response.json()

    if (!response.ok) {
      console.error('❌ Cron job error:', result)
      return new Response(
        JSON.stringify({
          success: false,
          error: result,
          timestamp: now.toISOString(),
        }),
        {
          status: response.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      )
    }

    console.log('📊 Cron job result:', result)

    return new Response(
      JSON.stringify({
        success: true,
        timestamp: now.toISOString(),
        result,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    )

  } catch (error) {
    console.error('❌ Cron job error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
