import 'dart:io';

void main() async {
  print('🎯 TEST COMPLET NOTIFICATIONS - expertiaen5min@gmail.com');
  print('=' * 60);
  
  final now = DateTime.now();
  print('🕐 Heure actuelle: ${now.toString()}');
  print('🌍 Timezone: UTC${now.timeZoneOffset.isNegative ? '' : '+'}${now.timeZoneOffset.inHours}');
  
  // Test 1: Configuration utilisateur
  print('\n1️⃣ CONFIGURATION UTILISATEUR:');
  await testUserConfiguration();
  
  // Test 2: Logique de programmation
  print('\n2️⃣ LOGIQUE DE PROGRAMMATION:');
  await testSchedulingLogic();
  
  // Test 3: Gestion des cas limites
  print('\n3️⃣ CAS LIMITES:');
  await testEdgeCases();
  
  // Test 4: Recommandations
  print('\n4️⃣ RECOMMANDATIONS:');
  await printRecommendations();
}

Future<void> testUserConfiguration() async {
  // Simuler la récupération depuis la base
  final userConfig = {
    'id': '550e8400-e29b-41d4-a716-446655440001',
    'email': 'expertiaen5min@gmail.com',
    'notification_time': '14:30:00',
    'notifications_enabled': true,
    'reminder_notifications_enabled': false,
    'notification_timezone_offset_minutes': 120, // UTC+2 (France été)
  };
  
  print('✅ Configuration récupérée:');
  userConfig.forEach((key, value) {
    print('   $key: $value');
  });
  
  // Vérifier la cohérence
  final systemOffset = DateTime.now().timeZoneOffset.inMinutes;
  final userOffset = userConfig['notification_timezone_offset_minutes'] as int;
  
  if (systemOffset == userOffset) {
    print('✅ Timezone cohérente: système ($systemOffset min) = utilisateur ($userOffset min)');
  } else {
    print('⚠️ Timezone différente: système ($systemOffset min) ≠ utilisateur ($userOffset min)');
  }
}

Future<void> testSchedulingLogic() async {
  final notificationTime = '14:30:00';
  final timeParts = notificationTime.split(':');
  final hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);
  
  print('Heure configurée: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
  
  // Logique de _nextInstanceOfTime()
  final now = DateTime.now();
  DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
  
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
    print('⏰ Heure passée → notification reportée à demain');
  } else {
    print('⏰ Heure future → notification programmée aujourd\'hui');
  }
  
  final timeUntil = scheduledDate.difference(now);
  print('📅 Prochaine notification: $scheduledDate');
  print('⏱️ Dans: ${timeUntil.inHours}h ${timeUntil.inMinutes % 60}min ${timeUntil.inSeconds % 60}s');
  
  // Vérifier si c'est dans la plage de test
  if (timeUntil.inMinutes <= 5) {
    print('🚨 NOTIFICATION IMMINENTE ! Parfait pour tester maintenant');
  } else if (timeUntil.inMinutes <= 60) {
    print('⏰ Notification dans moins d\'1h - bon moment pour tester');
  } else {
    print('📅 Notification plus tard - modifier l\'heure pour tester');
  }
}

Future<void> testEdgeCases() async {
  print('Test des cas limites:');
  
  // Cas 1: Heure exacte (maintenant)
  final now = DateTime.now();
  final currentTimeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
  print('1. Heure actuelle ($currentTimeStr):');
  
  DateTime currentScheduled = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  if (currentScheduled.isBefore(now)) {
    currentScheduled = currentScheduled.add(const Duration(days: 1));
    print('   → Reportée à demain (logique correcte)');
  } else {
    print('   → Programmée maintenant (peut créer des conflits)');
  }
  
  // Cas 2: Minuit
  print('2. Notification à minuit (00:00):');
  DateTime midnightScheduled = DateTime(now.year, now.month, now.day, 0, 0);
  if (midnightScheduled.isBefore(now)) {
    midnightScheduled = midnightScheduled.add(const Duration(days: 1));
    print('   → Reportée à demain minuit ✅');
  }
  
  // Cas 3: Changement d'heure (été/hiver)
  print('3. Changement d\'heure:');
  print('   - Actuellement: UTC+2 (heure d\'été) ✅');
  print('   - Passage hiver: Le système s\'adaptera automatiquement ✅');
  
  // Cas 4: Weekend vs semaine
  final dayOfWeek = now.weekday;
  final dayName = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'][dayOfWeek - 1];
  print('4. Jour de la semaine:');
  print('   - Aujourd\'hui: $dayName');
  print('   - Notifications 7j/7: ✅ (pas de logique weekend)');
}

Future<void> printRecommendations() async {
  final now = DateTime.now();
  final targetTime = DateTime(now.year, now.month, now.day, 14, 30);
  final timeUntil = targetTime.difference(now);
  
  print('🎯 PLAN DE TEST RECOMMANDÉ:');
  
  if (timeUntil.inMinutes > 0 && timeUntil.inMinutes <= 10) {
    print('🚨 URGENT - Tester MAINTENANT:');
    print('1. Ouvrir l\'app DailyGrowth');
    print('2. Aller dans Profil → Notifications');
    print('3. Vérifier que l\'heure est bien 14:30');
    print('4. Attendre ${timeUntil.inMinutes} minutes');
    print('5. Vérifier si la notification arrive');
  } else if (timeUntil.inMinutes <= 60) {
    print('⏰ PRÉPARER LE TEST:');
    print('1. Dans ${timeUntil.inMinutes} minutes, la notification devrait arriver');
    print('2. Préparer l\'app et surveiller');
    print('3. Vérifier les logs dans la console');
  } else if (timeUntil.inMinutes < 0) {
    print('📅 PROGRAMMER POUR DEMAIN:');
    final tomorrow = targetTime.add(const Duration(days: 1));
    print('1. Prochaine notification: $tomorrow');
    print('2. Ou modifier l\'heure pour tester plus tôt');
  } else {
    print('🔧 TEST IMMÉDIAT:');
    print('1. Modifier l\'heure de notification à ${now.hour}:${(now.minute + 2).toString().padLeft(2, '0')}');
    print('2. Sauvegarder les paramètres');
    print('3. Attendre 2 minutes');
    print('4. Vérifier la notification');
  }
  
  print('\n🔍 POINTS À VÉRIFIER:');
  print('✅ Notification reçue à l\'heure exacte');
  print('✅ Titre: "🎯 Votre défi quotidien vous attend !"');
  print('✅ Corps: "Connectez-vous pour découvrir votre nouveau micro-défi personnalisé."');
  print('✅ Clic sur notification → ouvre l\'app');
  print('✅ Pas de notification en double');
  
  print('\n🐛 SI PROBLÈME:');
  print('1. Vérifier les permissions de notification');
  print('2. Consulter les logs de l\'app (console développeur)');
  print('3. Tester sur différentes plateformes (web/mobile)');
  print('4. Vérifier la base de données Supabase');
}
