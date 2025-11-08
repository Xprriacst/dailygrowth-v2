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
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Attempting to send notification to token: ${token.substring(0, 20)}...`)

    // Use legacy FCM API with VAPID key (simpler approach)
    const fcmPayload = {
      to: token,
      notification: {
        title: title,
        body: body,
        icon: '/icons/Icon-192.png',
        click_action: 'https://challengeme.ch/#/challenges'
      },
      data: {
        type: 'daily-reminder',
        timestamp: Date.now().toString(),
      }
    }

    // Try multiple approaches
    const approaches = [
      // Approach 1: Legacy API with server key
      {
        url: 'https://fcm.googleapis.com/fcm/send',
        headers: {
          'Authorization': 'key=YOUR_SERVER_KEY_HERE',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload)
      },
      // Approach 2: Direct Web Push (bypass Firebase)
      {
        url: 'https://fcm.googleapis.com/fcm/send/' + token,
        headers: {
          'Content-Type': 'application/json',
          'TTL': '86400',
        },
        body: JSON.stringify({
          title: title,
          body: body,
          icon: '/icons/Icon-192.png',
          data: { type: 'daily-reminder' }
        })
      }
    ]

    let lastError = null
    for (const approach of approaches) {
      try {
        console.log(`Trying approach: ${approach.url}`)
        
        const response = await fetch(approach.url, {
          method: 'POST',
          headers: approach.headers,
          body: approach.body
        })

        const result = await response.json()
        
        if (response.ok) {
          console.log(`✅ Success with approach: ${approach.url}`)
          return new Response(
            JSON.stringify({ 
              success: true, 
              message: 'Notification sent successfully',
              result: result 
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        } else {
          console.log(`❌ Failed approach: ${approach.url}`, result)
          lastError = result
        }
      } catch (error) {
        console.log(`❌ Error with approach: ${approach.url}`, error)
        lastError = error
      }
    }

    // All approaches failed
    return new Response(
      JSON.stringify({ 
        error: 'All notification approaches failed',
        details: lastError 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})