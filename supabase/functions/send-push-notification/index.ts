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

    // Firebase Cloud Messaging API v1 - utiliser compte de service
    const firebaseProjectId = 'dailygrowth-pwa'
    
    // Service account JSON pour l'authentification OAuth2
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')
    
    if (!serviceAccountJson) {
      console.error('FIREBASE_SERVICE_ACCOUNT_KEY not configured')
      return new Response(
        JSON.stringify({ 
          error: 'Firebase service account not configured',
          sent: false 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    let serviceAccount
    try {
      serviceAccount = JSON.parse(serviceAccountJson)
      console.log(`Firebase service account configured: ${serviceAccount.client_email}`)
    } catch (parseError) {
      console.error('Error parsing service account JSON:', parseError)
      return new Response(
        JSON.stringify({ 
          error: 'Invalid Firebase service account JSON format',
          details: parseError.message,
          sent: false 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Payload pour API FCM v1
    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type,
          url: url || '/',
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
            tag: 'challengeme-notification',
          },
          fcm_options: {
            link: `https://challengeme.ch${url || '/'}`
          }
        }
      }
    }

    try {
      console.log(`Sending FCM notification to token: ${fcmToken.substring(0, 20)}...`)
      
      // Générer JWT pour l'authentification OAuth2
      const now = Math.floor(Date.now() / 1000)
      const jwtHeader = {
        alg: 'RS256',
        typ: 'JWT'
      }
      
      const jwtPayload = {
        iss: serviceAccount.client_email,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        iat: now,
        exp: now + 3600
      }
      
      // Encoder en base64url (fonction helper simple)
      const base64UrlEncode = (data: any) => {
        let str: string
        if (typeof data === 'string') {
          str = data
        } else if (data instanceof Uint8Array) {
          str = String.fromCharCode(...data)
        } else {
          str = JSON.stringify(data)
        }
        return btoa(str)
          .replace(/\+/g, '-')
          .replace(/\//g, '_')
          .replace(/=/g, '')
      }
      
      const jwtHeaderEncoded = base64UrlEncode(jwtHeader)
      const jwtPayloadEncoded = base64UrlEncode(jwtPayload)
      const jwtUnsigned = `${jwtHeaderEncoded}.${jwtPayloadEncoded}`
      
      // Pour Edge Functions, on va utiliser Web Crypto API pour signer
      // Import de la clé privée
      const privateKeyPem = serviceAccount.private_key
      const privateKeyFormatted = privateKeyPem
        .replace('-----BEGIN PRIVATE KEY-----', '')
        .replace('-----END PRIVATE KEY-----', '')
        .replace(/\n/g, '')
        .replace(/\r/g, '')
        .replace(/\s/g, '')
      
      let privateKeyBuffer
      try {
        privateKeyBuffer = Uint8Array.from(atob(privateKeyFormatted), c => c.charCodeAt(0))
      } catch (decodeError) {
        console.error('Error decoding private key:', decodeError)
        return new Response(
          JSON.stringify({ 
            error: 'Failed to decode private key',
            details: decodeError.message,
            sent: false 
          }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
      let cryptoKey
      try {
        cryptoKey = await crypto.subtle.importKey(
          'pkcs8',
          privateKeyBuffer,
          {
            name: 'RSASSA-PKCS1-v1_5',
            hash: 'SHA-256'
          },
          false,
          ['sign']
        )
      } catch (importError) {
        console.error('Error importing private key:', importError)
        return new Response(
          JSON.stringify({ 
            error: 'Failed to import private key',
            details: importError.message,
            sent: false 
          }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
      // Signer le JWT
      const signatureBuffer = await crypto.subtle.sign(
        'RSASSA-PKCS1-v1_5',
        cryptoKey,
        new TextEncoder().encode(jwtUnsigned)
      )
      
      const signature = base64UrlEncode(new Uint8Array(signatureBuffer))
      const jwt = `${jwtUnsigned}.${signature}`
      
      console.log('JWT generated successfully')
      
      // Obtenir access token via OAuth2
      const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`
      })
      
      const tokenData = await tokenResponse.json()
      
      if (!tokenResponse.ok) {
        console.error('OAuth2 token error:', tokenData)
        return new Response(
          JSON.stringify({ 
            error: 'Failed to obtain OAuth2 token',
            details: tokenData,
            sent: false 
          }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
      const accessToken = tokenData.access_token
      console.log('OAuth2 access token obtained')
      
      // Envoyer notification via FCM API v1
      const fcmResponse = await fetch(
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
      
      const fcmResult = await fcmResponse.json()
      
      if (!fcmResponse.ok) {
        console.error('FCM Error Response:', fcmResult)
        return new Response(
          JSON.stringify({ 
            error: 'FCM API error',
            details: fcmResult,
            sent: false 
          }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
      console.log(`Push notification sent successfully:`, fcmResult)
      
      return new Response(
        JSON.stringify({ 
          message: 'Push notification sent successfully',
          fcm_response: fcmResult,
          sent: true 
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
      
    } catch (fcmError) {
      console.error('FCM Error:', fcmError)
      
      return new Response(
        JSON.stringify({ 
          error: 'Failed to send push notification',
          details: fcmError.message,
          sent: false 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    console.error('Error sending push notification:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})