// Script de test pour déboguer les notifications quotidiennes
// Usage: node test_notification_debug.js

console.log('🔍 DEBUG: Système de notifications quotidiennes DailyGrowth');
console.log('=' .repeat(60));

// 1. Vérifications temporelles
const now = new Date();
const utcTime = now.toISOString();
const localTime = now.toLocaleString('fr-FR', { timeZone: 'Europe/Paris' });

console.log('\n📅 INFORMATIONS TEMPORELLES:');
console.log(`Heure UTC: ${utcTime}`);
console.log(`Heure locale (Paris): ${localTime}`);
console.log(`Heure UTC: ${now.getUTCHours()}:${now.getUTCMinutes().toString().padStart(2, '0')}`);

// 2. Test de la logique de notification
const targetHour = 9; // 9h00 paramétré
const targetMinute = 0;
const currentHour = now.getUTCHours();
const currentMinute = now.getUTCMinutes();

const targetMinutes = targetHour * 60 + targetMinute;
const currentMinutes = currentHour * 60 + currentMinute;
const timeDiff = Math.abs(currentMinutes - targetMinutes);
const shouldSendNow = timeDiff <= 15 || (currentHour === targetHour && Math.abs(currentMinute - targetMinute) <= 15);

console.log('\n🎯 LOGIQUE DE NOTIFICATION:');
console.log(`Heure cible: ${targetHour}:${targetMinute.toString().padStart(2, '0')} UTC`);
console.log(`Heure actuelle: ${currentHour}:${currentMinute.toString().padStart(2, '0')} UTC`);
console.log(`Différence en minutes: ${timeDiff}`);
console.log(`Devrait envoyer maintenant: ${shouldSendNow ? 'OUI' : 'NON'}`);

// 3. Points à vérifier
console.log('\n✅ CHECKLIST DEBUG:');
console.log('1. [ ] Cron job configuré et actif dans Supabase');
console.log('2. [ ] Variables d\'environnement FIREBASE_SERVER_KEY configurée');
console.log('3. [ ] Utilisateur expertiaen5min@gmail.com existe avec:');
console.log('   - notifications_enabled = true');
console.log('   - reminder_notifications_enabled = true');
console.log('   - fcm_token renseigné');
console.log('   - notification_time = "09:00:00"');
console.log('4. [ ] Token FCM valide et non expiré');
console.log('5. [ ] Fonction Edge accessible et fonctionnelle');

console.log('\n🧪 PROCHAINES ACTIONS:');
console.log('1. Tester manuellement la fonction send-daily-notifications');
console.log('2. Vérifier les logs Supabase');
console.log('3. Contrôler la base de données utilisateur');
console.log('4. Tester l\'envoi de push notification direct');