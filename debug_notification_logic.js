// Debug de la logique de notification pour expertiaen5min@gmail.com
// Reproduit exactement la logique de send-daily-notifications

const now = new Date();
const currentHour = now.getUTCHours();
const currentMinute = now.getUTCMinutes();
const currentTime = `${currentHour.toString().padStart(2, '0')}:${currentMinute.toString().padStart(2, '0')}`;

console.log('🕐 DEBUG NOTIFICATION LOGIC');
console.log('='.repeat(50));
console.log(`Current UTC time: ${now.toISOString()}`);
console.log(`Current UTC time formatted: ${currentTime}`);

// Données utilisateur (d'après la base)
const user = {
  id: '550e8400-e29b-41d4-a716-446655440001',
  email: 'expertiaen5min@gmail.com',
  notification_time: '11:05:00', // Heure française configurée
  notification_timezone_offset_minutes: 120, // UTC+2
  notifications_enabled: true,
  fcm_token: 'cmYX3ikdnaae42gaQPiogT:APA91bGZ...' // Existe maintenant
};

console.log('\n👤 USER DATA:');
console.log(`Email: ${user.email}`);
console.log(`Notification time: ${user.notification_time}`);
console.log(`Timezone offset: ${user.notification_timezone_offset_minutes} minutes`);

// Parse user's preferred notification time
const notificationTime = user.notification_time || '09:00:00';
const [hours, minutes] = notificationTime.split(':').map(Number);
const userNotificationTime = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;

console.log(`\n🔧 PARSING:`)
console.log(`Parsed hours: ${hours}`);
console.log(`Parsed minutes: ${minutes}`);
console.log(`User notification time: ${userNotificationTime}`);

// Calculate timezone offset (same logic as Edge Function)
const defaultOffsetMinutes = (() => {
  const parisTime = new Date(now.toLocaleString('en-US', { timeZone: 'Europe/Paris' }));
  const utcTime = new Date(now.toLocaleString('en-US', { timeZone: 'UTC' }));
  return Math.round((parisTime.getTime() - utcTime.getTime()) / (1000 * 60));
})();

const timezoneOffsetMinutes = typeof user.notification_timezone_offset_minutes === 'number'
  ? user.notification_timezone_offset_minutes
  : defaultOffsetMinutes;

console.log(`\n🌍 TIMEZONE CALCULATION:`)
console.log(`Default offset (Paris): ${defaultOffsetMinutes} minutes`);
console.log(`User stored offset: ${user.notification_timezone_offset_minutes} minutes`);
console.log(`Final offset used: ${timezoneOffsetMinutes} minutes`);

// Calculate target time in UTC
const targetLocalMinutes = hours * 60 + minutes;
const targetUtcMinutes = ((targetLocalMinutes - timezoneOffsetMinutes) % 1440 + 1440) % 1440;
const currentTotalMinutes = currentHour * 60 + currentMinute;
const rawDiff = Math.abs(currentTotalMinutes - targetUtcMinutes);
const diffMinutes = Math.min(rawDiff, 1440 - rawDiff);

console.log(`\n⏰ TIME CALCULATION:`)
console.log(`Target local minutes: ${targetLocalMinutes} (${Math.floor(targetLocalMinutes/60)}:${(targetLocalMinutes%60).toString().padStart(2,'0')})`);
console.log(`Target UTC minutes: ${targetUtcMinutes} (${Math.floor(targetUtcMinutes/60)}:${(targetUtcMinutes%60).toString().padStart(2,'0')})`);
console.log(`Current total minutes: ${currentTotalMinutes} (${currentHour}:${currentMinute.toString().padStart(2,'0')})`);
console.log(`Raw difference: ${rawDiff} minutes`);
console.log(`Final difference: ${diffMinutes} minutes`);

// Check if should send now (window of 10 minutes)
const shouldSendNow = diffMinutes <= 10;

console.log(`\n🎯 DECISION:`)
console.log(`Should send now (≤10min): ${shouldSendNow}`);
console.log(`Difference: ${diffMinutes} minutes`);

if (shouldSendNow) {
  console.log('✅ NOTIFICATION WOULD BE SENT!');
} else {
  console.log('❌ NOTIFICATION SKIPPED');
  console.log(`Need to wait ${diffMinutes - 10} more minutes or adjust time window`);
}

// Show when next window would be
const nextWindowStart = targetUtcMinutes - 10;
const nextWindowEnd = targetUtcMinutes + 10;
console.log(`\n📅 NOTIFICATION WINDOW:`)
console.log(`Window start: ${Math.floor(nextWindowStart/60)}:${(nextWindowStart%60).toString().padStart(2,'0')} UTC`);
console.log(`Target time: ${Math.floor(targetUtcMinutes/60)}:${(targetUtcMinutes%60).toString().padStart(2,'0')} UTC`);
console.log(`Window end: ${Math.floor(nextWindowEnd/60)}:${(nextWindowEnd%60).toString().padStart(2,'0')} UTC`);
