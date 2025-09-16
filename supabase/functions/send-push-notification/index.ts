import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationPayload {
  user_id?: string
  token?: string
  title: string
  body: string
  type?: string
  url?: string
  badge_count?: number
  data?: any
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { user_id, token, title, body, type = 'general', url = '/', badge_count, data }: NotificationPayload = await req.json()

    if (!title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: title, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let fcmToken = token

    // If no direct token provided, fetch from user profile
    if (!fcmToken && user_id) {
      // Initialize Supabase client
      const supabaseUrl = Deno.env.get('SUPABASE_URL')!
      const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
      const supabase = createClient(supabaseUrl, supabaseServiceKey)

      // Get user's FCM token
      const { data: userProfile, error: userError } = await supabase
        .from('user_profiles')
        .select('fcm_token, notifications_enabled')
        .eq('id', user_id)
        .single()

      if (userError) {
        console.error('Error fetching user profile:', userError)
        return new Response(
          JSON.stringify({ error: 'User not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Check if user has notifications enabled
      if (!userProfile.notifications_enabled) {
        return new Response(
          JSON.stringify({ message: 'Notifications disabled for user', sent: false }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      fcmToken = userProfile.fcm_token
    }

    // Check if we have a valid FCM token
    if (!fcmToken) {
      console.log(`No FCM token available`)
      return new Response(
        JSON.stringify({ message: 'No FCM token available', sent: false }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Firebase Cloud Messaging configuration with Service Account
    const firebaseServiceAccountKey = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')
    const firebaseProjectId = 'dailygrowth-pwa'

    if (!firebaseServiceAccountKey) {
      console.error('FIREBASE_SERVICE_ACCOUNT_KEY not configured')
      return new Response(
        JSON.stringify({ 
          error: 'Firebase service account not configured',
          sent: false 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get OAuth2 access token
    async function getFirebaseAccessToken() {
      try {
        const serviceAccount = JSON.parse(firebaseServiceAccountKey)
        
        // Create JWT for OAuth2
        const now = Math.floor(Date.now() / 1000)
        const jwt = {
          iss: serviceAccount.client_email,
          scope: 'https://www.googleapis.com/auth/firebase.messaging',
          aud: 'https://oauth2.googleapis.com/token',
          iat: now,
          exp: now + 3600
        }

        // Create the assertion (simplified)
        const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
        const payload = btoa(JSON.stringify(jwt))
        
        // Use Google's metadata server for access token (simpler approach)
        try {
          const response = await fetch('https://www.googleapis.com/auth/firebase.messaging', {
            method: 'POST',
            headers: { 
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${serviceAccount.private_key_id}`
            },
            body: JSON.stringify({
              grant_type: 'client_credentials',
              client_id: serviceAccount.client_id,
              client_email: serviceAccount.client_email
            })
          })

          if (response.ok) {
            const data = await response.json()
            return data.access_token
          }
        } catch (e) {
          console.log('Metadata server failed, trying direct approach')
        }

        // Fallback: Create a simulated access token from service account data
        // This is a temporary solution until proper JWT signing is implemented
        const mockToken = btoa(JSON.stringify({
          email: serviceAccount.client_email,
          project_id: serviceAccount.project_id,
          private_key_id: serviceAccount.private_key_id,
          timestamp: Date.now()
        }))
        
        return mockToken
      } catch (error) {
        console.error('Error getting access token:', error)
        throw error
      }
    }

    // Prepare FCM payload
    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type,
          url: url,
          badge_count: badge_count?.toString() || '0',
          timestamp: Date.now().toString(),
        },
        webpush: {
          headers: {
            'TTL': '86400'
          },
          notification: {
            title: title,
            body: body,
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
            tag: 'dailygrowth-notification',
            requireInteraction: false,
            data: {
              type: type,
              url: url,
              badge_count: badge_count || 0,
              timestamp: Date.now(),
            }
          },
          fcm_options: {
            link: `https://dailygrowth-pwa.netlify.app${url}`
          }
        }
      }
    }

    // Send push notification via Firebase with OAuth2
    let fcmResponse
    try {
      const accessToken = await getFirebaseAccessToken()
      
      fcmResponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(fcmPayload),
        }
      )
    } catch (authError) {
      console.error('Firebase auth error:', authError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to authenticate with Firebase',
          details: authError.message,
          sent: false 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const fcmResult = await fcmResponse.json()

    if (!fcmResponse.ok) {
      console.error('FCM Error:', fcmResult)
      
      // If token is invalid, clear it from database
      if (fcmResult.error?.code === 'INVALID_ARGUMENT' || 
          fcmResult.error?.details?.find((d: any) => d.errorCode === 'UNREGISTERED')) {
        
        console.log(`Clearing invalid FCM token for user ${user_id}`)
        await supabase
          .from('user_profiles')
          .update({ fcm_token: null })
          .eq('id', user_id)
      }

      return new Response(
        JSON.stringify({ 
          error: 'Failed to send push notification',
          details: fcmResult,
          sent: false 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Push notification sent successfully to user ${user_id}`)

    return new Response(
      JSON.stringify({ 
        message: 'Push notification sent successfully',
        fcm_message_id: fcmResult.name,
        sent: true 
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error sending push notification:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})