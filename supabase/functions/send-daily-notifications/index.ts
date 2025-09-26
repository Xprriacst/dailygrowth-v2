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
    const supabaseServiceKey = Deno.env.get('SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (!supabaseServiceKey) {
      throw new Error('Missing service role key in environment (SERVICE_ROLE_KEY)')
    }
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get current time and calculate time ranges for different timezones
    const now = new Date()
    const currentHour = now.getUTCHours()
    const currentMinute = now.getUTCMinutes()
    const currentTime = `${currentHour.toString().padStart(2, '0')}:${currentMinute.toString().padStart(2, '0')}`

    console.log(`Running daily notifications check at ${now.toISOString()} (UTC ${currentTime})`)

    // Get all users with notifications enabled
    // We'll check each user's timezone and notification time individually
    const { data: users, error: usersError } = await supabase
      .from('user_profiles')
      .select('id, fcm_token, notifications_enabled, reminder_notifications_enabled, notification_time, notification_timezone_offset_minutes, last_notification_sent_at')
      .eq('notifications_enabled', true)
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

    // Firebase configuration - using VAPID key for web push
    const vapidKey = Deno.env.get('FIREBASE_VAPID_KEY') || 'BJe790aSYySweHjaldtDhKaWTx5BBQ0dskvXly3urJWFnFifeoWY1EA8wJnDvyUhIu_s_AZODY9ucqBi0FgMxXs'
    const firebaseProjectId = 'dailygrowth-pwa'
    
    console.log(`Firebase VAPID key configured: ${vapidKey ? 'YES' : 'NO'}`)

    for (const user of users || []) {
      try {
        // Parse user's preferred notification time
        const notificationTime = user.notification_time || '09:00:00'
        const [hours, minutes] = notificationTime.split(':').map(Number)
        const userNotificationTime = `${hours.toString().padStart(2, '0')}:${minutes
          .toString()
          .padStart(2, '0')}`

        const defaultOffsetMinutes = (() => {
          const parisTime = new Date(now.toLocaleString('en-US', { timeZone: 'Europe/Paris' }))
          const utcTime = new Date(now.toLocaleString('en-US', { timeZone: 'UTC' }))
          return Math.round((parisTime.getTime() - utcTime.getTime()) / (1000 * 60))
        })()

        const timezoneOffsetMinutes = typeof user.notification_timezone_offset_minutes === 'number'
          ? user.notification_timezone_offset_minutes
          : defaultOffsetMinutes

        const targetLocalMinutes = hours * 60 + minutes
        const targetUtcMinutes = ((targetLocalMinutes - timezoneOffsetMinutes) % 1440 + 1440) % 1440
        const currentTotalMinutes = currentHour * 60 + currentMinute
        const rawDiff = Math.abs(currentTotalMinutes - targetUtcMinutes)
        const diffMinutes = Math.min(rawDiff, 1440 - rawDiff)

        // Send only when we're within a one-minute window of the desired time
        const shouldSendNow = diffMinutes === 0

        if (!shouldSendNow) {
          console.log(`⏭️ Skipping user ${user.id}: target ${userNotificationTime} (offset ${timezoneOffsetMinutes} min), current ${currentTime}, diff ${diffMinutes}min`)
          continue
        }

        if (user.last_notification_sent_at) {
          const lastSent = new Date(user.last_notification_sent_at)
          const lastSentDate = lastSent.toISOString().split('T')[0]
          const todayDate = now.toISOString().split('T')[0]
          if (lastSentDate === todayDate) {
            console.log(`⏸️ Notification already sent today for user ${user.id}, skipping`)
            continue
          }
        }

        console.log(`🎯 Sending notification to user ${user.id}: target ${userNotificationTime} (offset ${timezoneOffsetMinutes} min), current ${currentTime} UTC`)

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

        // Use Firebase Cloud Messaging REST API v1 (requires service account)
        // For simplicity, call the existing send-push-notification function
        const notificationPayload = {
          token: user.fcm_token,
          title: title,
          body: body,
          data: {
            type: 'daily-reminder',
            url: '/#/challenges',
            timestamp: Date.now().toString(),
          }
        }

        // Call the send-push-notification function
        const fcmResponse = await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${supabaseServiceKey}`,
          },
          body: JSON.stringify(notificationPayload)
        })

        const fcmResult = await fcmResponse.json()

        if (fcmResponse.ok) {
          notificationsSent++
          console.log(`Daily notification sent to user ${user.id}`)

          await supabase
            .from('user_profiles')
            .update({ last_notification_sent_at: new Date().toISOString() })
            .eq('id', user.id)
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
