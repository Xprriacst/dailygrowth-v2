import 'dart:io';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

void main() async {
  // Test du système de timezone pour la France
  print('🇫🇷 TEST SYSTÈME NOTIFICATIONS - FRANCE UNIQUEMENT');
  print('=' * 60);
  
  // 1. Initialiser les timezones
  tzdata.initializeTimeZones();
  
  // 2. Définir la timezone française (comme dans le code actuel)
  tz.Location franceLocation;
  try {
    franceLocation = tz.getLocation('Europe/Paris');
    tz.setLocalLocation(franceLocation);
    print('✅ Timezone configurée: Europe/Paris');
  } catch (e) {
    franceLocation = tz.UTC;
    tz.setLocalLocation(franceLocation);
    print('⚠️ Fallback sur UTC: $e');
  }
  
  // 3. Heure actuelle
  final now = tz.TZDateTime.now(tz.local);
  print('🕐 Heure actuelle France: ${now.toString()}');
  print('🕐 Heure actuelle système: ${DateTime.now().toString()}');
  
  // 4. Test de programmation de notification
  print('\n📅 TEST PROGRAMMATION NOTIFICATIONS:');
  
  // Simuler les heures de notification de l'utilisateur expertiaen5min@gmail.com
  final testTimes = ['14:30:00', '09:00:00', '18:00:00', '22:00:00'];
  
  for (final timeString in testTimes) {
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    final timeUntilNotification = scheduledTime.difference(now);
    
    print('⏰ Notification à $timeString:');
    print('   Programmée pour: ${scheduledTime.toString()}');
    print('   Dans: ${timeUntilNotification.inHours}h ${timeUntilNotification.inMinutes % 60}min');
    print('   Timezone: ${scheduledTime.location.name}');
    print('');
  }
  
  // 5. Test de l'offset timezone
  print('🌍 INFORMATIONS TIMEZONE:');
  print('Offset actuel: ${now.timeZoneOffset.inHours}h');
  print('Offset en minutes: ${now.timeZoneOffset.inMinutes}min');
  print('Est en heure d\'été: ${now.timeZoneOffset.inHours == 2}');
  
  // 6. Test spécifique pour expertiaen5min@gmail.com
  print('\n👤 TEST UTILISATEUR expertiaen5min@gmail.com:');
  final userNotificationTime = '14:30:00';
  final userTimeParts = userNotificationTime.split(':');
  final userHour = int.parse(userTimeParts[0]);
  final userMinute = int.parse(userTimeParts[1]);
  
  final userScheduledTime = _nextInstanceOfTime(userHour, userMinute);
  final userTimeUntil = userScheduledTime.difference(now);
  
  print('Heure configurée: $userNotificationTime');
  print('Prochaine notification: ${userScheduledTime.toString()}');
  print('Dans: ${userTimeUntil.inHours}h ${userTimeUntil.inMinutes % 60}min');
  
  if (userTimeUntil.inMinutes < 60) {
    print('🚨 ATTENTION: Notification dans moins d\'1h !');
  } else if (userTimeUntil.inHours < 24) {
    print('✅ Notification programmée pour aujourd\'hui');
  } else {
    print('📅 Notification programmée pour demain');
  }
  
  print('\n🎯 RÉSULTAT:');
  if (franceLocation.name == 'Europe/Paris') {
    print('✅ Système configuré correctement pour la France');
    print('✅ Toutes les notifications seront en heure française');
  } else {
    print('❌ Problème de configuration timezone');
  }
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}
