// Analyse de la base de production Supabase
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = 'https://hekdcsulxrukfturuone.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk'

const supabase = createClient(supabaseUrl, supabaseServiceKey)

console.log('🔍 ANALYSE BASE DE PRODUCTION SUPABASE')
console.log('=' .repeat(50))

async function analyzeDatabase() {
  try {
    // 1. Vérifier les tables existantes
    console.log('\n📋 TABLES EXISTANTES:')
    
    // Test user_profiles
    try {
      const { data: userProfilesTest, error: upError } = await supabase
        .from('user_profiles')
        .select('*')
        .limit(1)
      
      if (upError) {
        console.log('❌ user_profiles: N\'existe pas')
        console.log('   Error:', upError.message)
      } else {
        console.log('✅ user_profiles: Existe')
        if (userProfilesTest && userProfilesTest.length > 0) {
          console.log('   Colonnes détectées:', Object.keys(userProfilesTest[0]))
        }
      }
    } catch (e) {
      console.log('❌ user_profiles: Erreur', e.message)
    }

    // Test user_micro_challenges
    try {
      const { data: microchallengesTest, error: mcError } = await supabase
        .from('user_micro_challenges')
        .select('*')
        .limit(1)
      
      if (mcError) {
        console.log('❌ user_micro_challenges: N\'existe pas')
        console.log('   Error:', mcError.message)
      } else {
        console.log('✅ user_micro_challenges: Existe')
        if (microchallengesTest && microchallengesTest.length > 0) {
          console.log('   Colonnes détectées:', Object.keys(microchallengesTest[0]))
        }
      }
    } catch (e) {
      console.log('❌ user_micro_challenges: Erreur', e.message)
    }

    // Test user_achievements
    try {
      const { data: achievementsTest, error: achError } = await supabase
        .from('user_achievements')
        .select('*')
        .limit(1)
      
      if (achError) {
        console.log('❌ user_achievements: N\'existe pas')
        console.log('   Error:', achError.message)
      } else {
        console.log('✅ user_achievements: Existe')
        if (achievementsTest && achievementsTest.length > 0) {
          console.log('   Colonnes détectées:', Object.keys(achievementsTest[0]))
        }
      }
    } catch (e) {
      console.log('❌ user_achievements: Erreur', e.message)
    }

    // Test daily_challenges
    try {
      const { data: dailyChallengesTest, error: dcError } = await supabase
        .from('daily_challenges')
        .select('*')
        .limit(1)
      
      if (dcError) {
        console.log('❌ daily_challenges: N\'existe pas')
        console.log('   Error:', dcError.message)
      } else {
        console.log('✅ daily_challenges: Existe')
        if (dailyChallengesTest && dailyChallengesTest.length > 0) {
          console.log('   Colonnes détectées:', Object.keys(dailyChallengesTest[0]))
        }
      }
    } catch (e) {
      console.log('❌ daily_challenges: Erreur', e.message)
    }

    // 2. Vérifier l'utilisateur expertiaen5min@gmail.com
    console.log('\n👤 UTILISATEUR expertiaen5min@gmail.com:')
    
    try {
      const { data: users, error: userError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('email', 'expertiaen5min@gmail.com')
      
      if (userError) {
        console.log('❌ Erreur récupération utilisateur:', userError.message)
      } else if (!users || users.length === 0) {
        console.log('❌ Utilisateur n\'existe pas en production')
      } else {
        const user = users[0]
        console.log('✅ Utilisateur trouvé:')
        console.log('   ID:', user.id)
        console.log('   Email:', user.email)
        console.log('   FCM Token:', user.fcm_token ? `${user.fcm_token.substring(0, 20)}...` : 'NULL')
        console.log('   Notifications enabled:', user.notifications_enabled)
        console.log('   Notification time:', user.notification_time)
        console.log('   Timezone offset:', user.notification_timezone_offset_minutes)
        console.log('   Last notification sent:', user.last_notification_sent_at)
        console.log('   Selected problematiques:', user.selected_problematiques)
        console.log('   Selected life domains:', user.selected_life_domains)
      }
    } catch (e) {
      console.log('❌ Erreur analyse utilisateur:', e.message)
    }

    // 3. Compter les utilisateurs avec notifications activées
    console.log('\n📊 STATISTIQUES NOTIFICATIONS:')
    
    try {
      const { data: notifUsers, error: notifError } = await supabase
        .from('user_profiles')
        .select('id, email, fcm_token, notifications_enabled')
        .eq('notifications_enabled', true)
      
      if (notifError) {
        console.log('❌ Erreur stats notifications:', notifError.message)
      } else {
        console.log(`✅ Utilisateurs avec notifications activées: ${notifUsers.length}`)
        const withFCM = notifUsers.filter(u => u.fcm_token && u.fcm_token.trim() !== '')
        console.log(`📱 Avec FCM token valide: ${withFCM.length}`)
        
        if (withFCM.length > 0) {
          console.log('   Utilisateurs avec FCM:')
          withFCM.forEach(u => {
            console.log(`   - ${u.email}: ${u.fcm_token.substring(0, 20)}...`)
          })
        }
      }
    } catch (e) {
      console.log('❌ Erreur stats:', e.message)
    }

  } catch (error) {
    console.error('❌ Erreur générale:', error)
  }
}

analyzeDatabase()
