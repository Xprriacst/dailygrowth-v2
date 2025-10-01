import 'dart:io';

void main() {
  print('🇫🇷 TEST TIMEZONE FRANCE - SIMPLE');
  print('=' * 50);
  
  // Heure actuelle du système
  final now = DateTime.now();
  print('🕐 Heure système actuelle: $now');
  print('🌍 Timezone offset: ${now.timeZoneOffset.inHours}h');
  
  // Test de l'heure de notification pour expertiaen5min@gmail.com
  final userNotificationTime = '14:30:00';
  final timeParts = userNotificationTime.split(':');
  final hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);
  
  // Calculer la prochaine instance de cette heure
  DateTime scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
  if (scheduledTime.isBefore(now)) {
    scheduledTime = scheduledTime.add(const Duration(days: 1));
  }
  
  final timeUntil = scheduledTime.difference(now);
  
  print('\n👤 UTILISATEUR expertiaen5min@gmail.com:');
  print('Heure configurée: $userNotificationTime');
  print('Prochaine notification: $scheduledTime');
  print('Dans: ${timeUntil.inHours}h ${timeUntil.inMinutes % 60}min');
  
  // Vérifier si c'est cohérent avec l'heure française
  final isInFranceTimezone = now.timeZoneOffset.inHours == 1 || now.timeZoneOffset.inHours == 2;
  
  print('\n🔍 VÉRIFICATIONS:');
  print('Timezone française détectée: ${isInFranceTimezone ? "✅" : "❌"}');
  print('Heure d\'été (UTC+2): ${now.timeZoneOffset.inHours == 2 ? "✅" : "❌"}');
  print('Heure d\'hiver (UTC+1): ${now.timeZoneOffset.inHours == 1 ? "✅" : "❌"}');
  
  if (timeUntil.inMinutes < 60) {
    print('🚨 NOTIFICATION IMMINENTE: Dans ${timeUntil.inMinutes} minutes !');
  } else if (timeUntil.inHours < 24) {
    print('📅 Notification aujourd\'hui à ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
  } else {
    print('📅 Notification demain à ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
  }
  
  // Test avec différentes heures
  print('\n⏰ TESTS AUTRES HEURES:');
  final testHours = ['09:00', '12:00', '18:00', '22:00'];
  
  for (final timeStr in testHours) {
    final parts = timeStr.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    
    DateTime testTime = DateTime(now.year, now.month, now.day, h, m);
    if (testTime.isBefore(now)) {
      testTime = testTime.add(const Duration(days: 1));
    }
    
    final testTimeUntil = testTime.difference(now);
    final status = testTimeUntil.inMinutes < 60 ? '🚨 IMMINENT' : 
                   testTimeUntil.inHours < 24 ? '📅 AUJOURD\'HUI' : '📅 DEMAIN';
    
    print('$timeStr → $status (dans ${testTimeUntil.inHours}h${testTimeUntil.inMinutes % 60}min)');
  }
}
