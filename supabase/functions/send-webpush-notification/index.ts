import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import webpush, { PushSubscription } from 'npm:web-push@3.6.7'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type SubscriptionRow = {
  id: string
  endpoint: string
  keys: {
    p256dh: string
    auth: string
  }
  platform: string | null
}

interface RequestPayload {
  user_id?: string
  subscription?: PushSubscription
  title: string
  body: string
  url?: string
  data?: Record<string, unknown>
  tag?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload: RequestPayload = await req.json()

    if (!payload.title || !payload.body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: title, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const publicKey = Deno.env.get('WEB_PUSH_VAPID_PUBLIC_KEY')
    const privateKey = Deno.env.get('WEB_PUSH_VAPID_PRIVATE_KEY')
    const subject = Deno.env.get('WEB_PUSH_VAPID_SUBJECT') ?? 'mailto:support@dailygrowth.ch'

    if (!publicKey || !privateKey) {
      return new Response(
        JSON.stringify({ error: 'Missing VAPID keys configuration' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    webpush.setVapidDetails(subject, publicKey, privateKey)

    let subscriptions: PushSubscription[] = []

    if (payload.subscription) {
      subscriptions = [payload.subscription]
    } else if (payload.user_id) {
      const supabaseUrl = Deno.env.get('SUPABASE_URL')
      const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

      if (!supabaseUrl || !serviceKey) {
        throw new Error('Supabase credentials missing in environment')
      }

      const supabase = createClient(supabaseUrl, serviceKey)

      const { data, error } = await supabase
        .from('web_push_subscriptions')
        .select('id, endpoint, keys, platform')
        .eq('user_id', payload.user_id)

      if (error) {
        console.error('Error fetching web push subscriptions:', error)
        return new Response(
          JSON.stringify({ error: 'Failed to fetch subscriptions' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (!data || data.length === 0) {
        return new Response(
          JSON.stringify({ message: 'No web push subscriptions for user', sent: false }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      subscriptions = data.map((row: SubscriptionRow) => ({
        endpoint: row.endpoint,
        expirationTime: null,
        keys: row.keys,
      }))
    } else {
      return new Response(
        JSON.stringify({ error: 'Provide either subscription or user_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const notificationPayload = JSON.stringify({
      title: payload.title,
      body: payload.body,
      url: payload.url ?? '/#/challenges',
      data: payload.data ?? {},
      tag: payload.tag ?? 'dailygrowth-webpush',
      timestamp: Date.now(),
    })

    let successCount = 0
    const failures: Array<{ endpoint: string; error: unknown }> = []
    const staleSubscriptionIds: string[] = []

    for (const subscription of subscriptions) {
      try {
        await webpush.sendNotification(subscription, notificationPayload, { TTL: 60 * 60 * 12 })
        successCount++
      } catch (error) {
        console.error('Web push error:', error)
        failures.push({ endpoint: subscription.endpoint, error })

        const statusCode = (error as { statusCode?: number }).statusCode
        if (payload.user_id && (statusCode === 404 || statusCode === 410)) {
          // mark subscription for cleanup
          staleSubscriptionIds.push(subscription.endpoint)
        }
      }
    }

    if (payload.user_id && staleSubscriptionIds.length > 0) {
      const supabaseUrl = Deno.env.get('SUPABASE_URL')
      const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
      if (supabaseUrl && serviceKey) {
        const supabase = createClient(supabaseUrl, serviceKey)
        await supabase
          .from('web_push_subscriptions')
          .delete()
          .in('endpoint', staleSubscriptionIds)
      }
    }

    return new Response(
      JSON.stringify({
        sent: successCount,
        failed: failures.length,
        failures,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('send-webpush-notification error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
