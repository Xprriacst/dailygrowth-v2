import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('PROJECT_URL') ?? Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    console.log('🔍 ANALYSE BASE DE PRODUCTION')
    
    const analysis = {
      timestamp: new Date().toISOString(),
      tables: {},
      user_analysis: null,
      stats: {}
    }

    // 1. Test user_profiles
    try {
      const { data: userTest, error: userError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('email', 'expertiaen5min@gmail.com')
        .single()
      
      if (userError) {
        analysis.tables.user_profiles = { exists: false, error: userError.message }
      } else {
        analysis.tables.user_profiles = { 
          exists: true, 
          columns: Object.keys(userTest),
          sample_data: userTest
        }
        analysis.user_analysis = {
          found: true,
          id: userTest.id,
          email: userTest.email,
          fcm_token: userTest.fcm_token ? `${userTest.fcm_token.substring(0, 20)}...` : null,
          notifications_enabled: userTest.notifications_enabled,
          notification_time: userTest.notification_time,
          timezone_offset: userTest.notification_timezone_offset_minutes,
          last_notification_sent: userTest.last_notification_sent_at,
          selected_problematiques: userTest.selected_problematiques
        }
      }
    } catch (e) {
      analysis.tables.user_profiles = { exists: false, error: e.message }
    }

    // 2. Test user_micro_challenges
    try {
      const { data: mcTest, error: mcError } = await supabase
        .from('user_micro_challenges')
        .select('*')
        .limit(1)
      
      if (mcError) {
        analysis.tables.user_micro_challenges = { exists: false, error: mcError.message }
      } else {
        analysis.tables.user_micro_challenges = { 
          exists: true, 
          columns: mcTest.length > 0 ? Object.keys(mcTest[0]) : [],
          count: mcTest.length
        }
      }
    } catch (e) {
      analysis.tables.user_micro_challenges = { exists: false, error: e.message }
    }

    // 3. Test user_achievements
    try {
      const { data: achTest, error: achError } = await supabase
        .from('user_achievements')
        .select('*')
        .limit(1)
      
      if (achError) {
        analysis.tables.user_achievements = { exists: false, error: achError.message }
      } else {
        analysis.tables.user_achievements = { 
          exists: true, 
          columns: achTest.length > 0 ? Object.keys(achTest[0]) : [],
          count: achTest.length
        }
      }
    } catch (e) {
      analysis.tables.user_achievements = { exists: false, error: e.message }
    }

    // 4. Test daily_challenges
    try {
      const { data: dcTest, error: dcError } = await supabase
        .from('daily_challenges')
        .select('*')
        .limit(1)
      
      if (dcError) {
        analysis.tables.daily_challenges = { exists: false, error: dcError.message }
      } else {
        analysis.tables.daily_challenges = { 
          exists: true, 
          columns: dcTest.length > 0 ? Object.keys(dcTest[0]) : [],
          count: dcTest.length
        }
      }
    } catch (e) {
      analysis.tables.daily_challenges = { exists: false, error: e.message }
    }

    // 5. Stats notifications
    try {
      const { data: notifUsers, error: notifError } = await supabase
        .from('user_profiles')
        .select('id, email, fcm_token, notifications_enabled')
        .eq('notifications_enabled', true)
      
      if (!notifError && notifUsers) {
        const withFCM = notifUsers.filter(u => u.fcm_token && u.fcm_token.trim() !== '')
        analysis.stats = {
          total_users_with_notifications: notifUsers.length,
          users_with_fcm_token: withFCM.length,
          users_with_fcm: withFCM.map(u => ({ 
            email: u.email, 
            fcm_preview: u.fcm_token.substring(0, 20) + '...' 
          }))
        }
      }
    } catch (e) {
      analysis.stats = { error: e.message }
    }

    console.log('📊 Analysis completed:', JSON.stringify(analysis, null, 2))

    return new Response(
      JSON.stringify(analysis, null, 2),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('❌ Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
