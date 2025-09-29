# 🔍 DIAGNOSTIC SYSTÈME NOTIFICATIONS PUSH - 29 SEPTEMBRE 2025

## ✅ CE QUI FONCTIONNE
- **Tests manuels** : Les notifications de test s'envoient correctement
- **FCM Token** : L'utilisateur a un token FCM valide
- **Edge Functions** : Déployées et fonctionnelles
- **Service Worker** : Configuré pour iOS PWA

## ❌ PROBLÈMES IDENTIFIÉS

### 🚨 PROBLÈME #1 : Vérification "Déjà envoyé aujourd'hui" trop stricte
**Localisation** : `send-daily-notifications/index.ts` lignes 95-103

```typescript
if (user.last_notification_sent_at) {
  const lastSent = new Date(user.last_notification_sent_at)
  const lastSentDate = lastSent.toISOString().split('T')[0]
  const todayDate = now.toISOString().split('T')[0]
  if (lastSentDate === todayDate) {
    console.log(`⏸️ Notification already sent today for user ${user.id}, skipping`)
    continue
  }
}
```

**Impact** : Si une notification a été envoyée aujourd'hui (même en test), aucune autre notification ne sera envoyée jusqu'à demain minuit UTC.

**Solution** :
- Soit réinitialiser `last_notification_sent_at` à NULL pour tester
- Soit ajouter une fenêtre de "réessai" si la notification a échoué
- Soit différencier notifications de test vs notifications planifiées

---

### 🚨 PROBLÈME #2 : Fenêtre temporelle de 10 minutes peut être manquée
**Localisation** : `send-daily-notifications/index.ts` ligne 88

```typescript
const shouldSendNow = diffMinutes <= 10
```

**Scénario problématique** :
- Cron s'exécute toutes les 15 minutes
- Heure configurée : 14:30
- Cron passe à 14:25 → diff = 5 min → ✅ envoi
- **MAIS** si cron passe à 14:20 et 14:35 → il rate la fenêtre !

**Solution** : Augmenter la fenêtre à 15 minutes minimum :
```typescript
const shouldSendNow = diffMinutes <= 15
```

---

### 🚨 PROBLÈME #3 : Timezone offset peut être NULL ou incorrect
**Localisation** : `send-daily-notifications/index.ts` lignes 71-79

```typescript
const defaultOffsetMinutes = (() => {
  const parisTime = new Date(now.toLocaleString('en-US', { timeZone: 'Europe/Paris' }))
  const utcTime = new Date(now.toLocaleString('en-US', { timeZone: 'UTC' }))
  return Math.round((parisTime.getTime() - utcTime.getTime()) / (1000 * 60))
})()

const timezoneOffsetMinutes = typeof user.notification_timezone_offset_minutes === 'number'
  ? user.notification_timezone_offset_minutes
  : defaultOffsetMinutes
```

**Problème** : Ce calcul de fallback est complexe et peut être incorrect en fonction de l'heure d'été/hiver.

**À vérifier** :
- Est-ce que `notification_timezone_offset_minutes` est bien renseigné pour expertiaen5min@gmail.com ?
- Quelle est sa valeur actuelle ?

---

### 🚨 PROBLÈME #4 : Cron job peut ne pas être actif
**Localisation** : `setup_cron.sql`

Le cron job doit être créé dans Supabase avec :
```sql
SELECT cron.schedule(
  'daily-notifications-check',
  '*/15 * * * *',  -- Toutes les 15 minutes
  ...
);
```

**À vérifier** :
- Le cron job est-il actif dans la base production ?
- Exécuter : `SELECT * FROM cron.job;` pour vérifier

---

### 🚨 PROBLÈME #5 : Logs et monitoring
**Manque** : Pas de système de logging persistant pour savoir :
- Quand le cron s'est exécuté
- Pourquoi les utilisateurs ont été skippés
- Quelles erreurs se sont produites

**Solution** : Créer une table `notification_logs` pour tracer tous les événements.

---

## 🧪 TESTS À EFFECTUER

### Test 1 : Vérifier l'état actuel de l'utilisateur
```sql
-- Exécuter dans Supabase SQL Editor
SELECT 
    id,
    email,
    notifications_enabled,
    notification_time,
    notification_timezone_offset_minutes,
    last_notification_sent_at,
    fcm_token IS NOT NULL as has_fcm_token,
    SUBSTRING(fcm_token, 1, 30) as token_preview
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';
```

### Test 2 : Vérifier le cron job
```sql
SELECT * FROM cron.job WHERE jobname = 'daily-notifications-check';
```

### Test 3 : Réinitialiser last_notification_sent_at pour tester
```sql
UPDATE user_profiles 
SET last_notification_sent_at = NULL
WHERE email = 'expertiaen5min@gmail.com';
```

### Test 4 : Définir une heure de test dans 5 minutes
```sql
-- Si il est 20:53, définir notification_time à 21:00
UPDATE user_profiles 
SET 
    notification_time = '21:00:00',
    notification_timezone_offset_minutes = 120  -- UTC+2 pour la France
WHERE email = 'expertiaen5min@gmail.com';
```

### Test 5 : Invoquer manuellement le cron
```bash
curl -X POST \
  'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk' \
  -d '{"trigger": "manual-test", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"}'
```

---

## 📋 PLAN D'ACTION RECOMMANDÉ

1. **IMMÉDIAT** : Exécuter les requêtes SQL de diagnostic
2. **VÉRIFIER** : État du cron job
3. **CORRIGER** : Fenêtre temporelle de 10→15 minutes
4. **TESTER** : Définir une heure dans 5 minutes et vérifier
5. **LOGGER** : Ajouter une table de logs pour traçabilité

---

## 🔧 CORRECTIONS À APPLIQUER

### Correction 1 : Élargir la fenêtre temporelle
```typescript
// Dans send-daily-notifications/index.ts ligne 88
const shouldSendNow = diffMinutes <= 15  // Au lieu de 10
```

### Correction 2 : Ajouter un flag pour tests
```typescript
// Permettre les notifications multiples en mode test
const isTestMode = req.body?.test_mode === true
if (!isTestMode && user.last_notification_sent_at) {
  // ... vérification normale
}
```

### Correction 3 : Créer une table de logs
```sql
CREATE TABLE notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id),
    trigger_type TEXT, -- 'cron', 'manual-test', etc.
    notification_sent BOOLEAN,
    skip_reason TEXT,
    error_message TEXT,
    notification_time TIME,
    timezone_offset INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 💡 HYPOTHÈSE PRINCIPALE

**Le problème le plus probable** : `last_notification_sent_at` contient une valeur récente (test d'aujourd'hui), ce qui empêche l'envoi de nouvelles notifications jusqu'à demain.

**Validation** : Exécuter la requête Test 1 ci-dessus et vérifier la valeur de `last_notification_sent_at`.
