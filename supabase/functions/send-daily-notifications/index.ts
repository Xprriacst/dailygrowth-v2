import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get current time in different timezones
    const now = new Date()
    const currentHour = now.getUTCHours()
    const currentMinute = now.getUTCMinutes()

    console.log(`Running daily notifications check at ${now.toISOString()}`)

    // Find users who should receive notifications at this time
    // Note: This is a simplified version - in production you'd want to handle timezones properly
    const { data: users, error: usersError } = await supabase
      .from('user_profiles')
      .select('id, fcm_token, notifications_enabled, reminder_notifications_enabled, notification_time')
      .eq('notifications_enabled', true)
      .eq('reminder_notifications_enabled', true)
      .not('fcm_token', 'is', null)

    if (usersError) {
      console.error('Error fetching users:', usersError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch users' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Found ${users?.length || 0} users with notifications enabled`)

    let notificationsSent = 0
    const errors: any[] = []

    // Firebase configuration
    const firebaseServerKey = Deno.env.get('FIREBASE_SERVER_KEY')!
    const firebaseProjectId = 'dailygrowth-pwa'

    for (const user of users || []) {
      try {
        // Parse user's preferred notification time
        const notificationTime = user.notification_time || '09:00:00'
        const [hours, minutes] = notificationTime.split(':').map(Number)
        
        // Simple check - in production you'd want proper timezone handling
        // For now, assuming users set their local time and we check every hour
        const shouldSendNow = (
          currentHour === hours && 
          currentMinute >= minutes && 
          currentMinute < minutes + 60
        ) || (
          // Also send if it's 9 AM UTC as fallback (adjust as needed)
          currentHour === 9 && currentMinute < 30 && !user.notification_time
        )

        if (!shouldSendNow) {
          continue
        }

        // Check if user already has an active challenge today
        const today = new Date().toISOString().split('T')[0]
        const { data: todaysChallenge } = await supabase
          .from('user_challenges')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', `${today}T00:00:00Z`)
          .lt('created_at', `${today}T23:59:59Z`)
          .single()

        // Prepare notification message
        const title = todaysChallenge 
          ? '🎯 Votre défi vous attend !' 
          : '✨ Nouveau défi disponible !'
        
        const body = todaysChallenge
          ? 'Continuez votre progression quotidienne'
          : 'Un nouveau micro-défi personnalisé vous attend'

        // Prepare FCM payload
        const fcmPayload = {
          message: {
            token: user.fcm_token,
            notification: {
              title: title,
              body: body,
            },
            data: {
              type: 'daily-reminder',
              url: '/#/challenges',
              timestamp: Date.now().toString(),
            },
            webpush: {
              headers: {
                'TTL': '86400' // 24 hours
              },
              notification: {
                title: title,
                body: body,
                icon: '/icons/Icon-192.png',
                badge: '/icons/Icon-192.png',
                tag: 'daily-reminder',
                requireInteraction: false,
                actions: [
                  {
                    action: 'open',
                    title: 'Voir le défi'
                  },
                  {
                    action: 'dismiss',
                    title: 'Plus tard'
                  }
                ]
              },
              fcm_options: {
                link: 'https://dailygrowth-pwa.netlify.app/#/challenges'
              }
            }
          }
        }

        // Send push notification
        const fcmResponse = await fetch(
          `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${firebaseServerKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(fcmPayload),
          }
        )

        const fcmResult = await fcmResponse.json()

        if (fcmResponse.ok) {
          notificationsSent++
          console.log(`Daily notification sent to user ${user.id}`)
        } else {
          console.error(`Failed to send notification to user ${user.id}:`, fcmResult)
          
          // Clear invalid tokens
          if (fcmResult.error?.code === 'INVALID_ARGUMENT' || 
              fcmResult.error?.details?.find((d: any) => d.errorCode === 'UNREGISTERED')) {
            
            await supabase
              .from('user_profiles')
              .update({ fcm_token: null })
              .eq('id', user.id)
              
            console.log(`Cleared invalid FCM token for user ${user.id}`)
          }
          
          errors.push({
            user_id: user.id,
            error: fcmResult
          })
        }

      } catch (error) {
        console.error(`Error processing user ${user.id}:`, error)
        errors.push({
          user_id: user.id,
          error: error.message
        })
      }
    }

    const response = {
      message: 'Daily notifications job completed',
      notifications_sent: notificationsSent,
      total_users_checked: users?.length || 0,
      errors: errors.length > 0 ? errors : undefined,
      timestamp: now.toISOString()
    }

    console.log('Daily notifications job result:', response)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in daily notifications job:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: error.message 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})