# 🚨 DEBUG : Aucune notification reçue à 17h35

## 🔍 Étapes de diagnostic

Vous avez configuré une notification pour 17h35 mais rien n'est arrivé. Suivons un diagnostic méthodique.

---

## ÉTAPE 1 : Exécuter le script de diagnostic

1. Ouvrir Supabase SQL Editor : https://supabase.com/dashboard/project/hekdcsulxrukfturuone/sql

2. Ouvrir le fichier `debug_17h35_pas_de_notif.sql`

3. **IMPORTANT** : Remplacer `'votre-email@example.com'` par votre vrai email dans les sections 2, 5, 6

4. Exécuter le script complet

---

## ÉTAPE 2 : Analyser les résultats

### Section 1 : Heure actuelle
Vérifiez que l'heure de Paris est correcte.

### Section 2 : Votre configuration ⚠️ CRITIQUE

Vérifiez **chaque champ** :

```sql
notifications_enabled = true     ← Doit être TRUE
notification_time = 17:35:00     ← Doit être 17:35
has_fcm_token = true             ← Doit être TRUE
fcm_token_preview = "eXyz..."    ← Doit être présent
```

#### 🚨 Problèmes courants :

**Si `notifications_enabled = false` :**
```sql
-- Activer les notifications
UPDATE profiles
SET notifications_enabled = true
WHERE email = 'votre-email@example.com';
```

**Si `has_fcm_token = false` :**
- Ouvrir l'app ChallengeMe
- Aller dans Paramètres → Notifications
- Autoriser les notifications sur l'appareil
- Redémarrer l'app si nécessaire

**Si `notification_time != 17:35:00` :**
```sql
-- Corriger l'heure
UPDATE profiles
SET notification_time = '17:35:00'::time
WHERE email = 'votre-email@example.com';
```

### Section 3 : Logs autour de 17h35 ⚠️ CRITIQUE

**Résultat A : Aucune ligne**
→ Le cron ne s'est PAS exécuté ou n'a pas vérifié votre utilisateur
→ Passer à la section 4

**Résultat B : Ligne(s) présente(s)**
→ Regarder la colonne `skip_reason` :

| skip_reason | Signification | Solution |
|-------------|---------------|----------|
| `"Outside notification window"` | Heure incorrecte ou décalage | Vérifier `notification_time` |
| `"No FCM token"` | Token manquant | Ouvrir l'app et autoriser notifs |
| `"Notifications disabled"` | Désactivées | Activer dans la base |
| `"Already sent today"` | Déjà envoyé | Normal, max 1 notif/jour |
| `"No active challenge today"` | Pas de défi | Créer un défi pour aujourd'hui |
| NULL mais `notification_sent = false` | Erreur technique | Regarder `error_message` |

### Section 4 : Exécutions du cron ⚠️ CRITIQUE

**Résultat A : Aucune ligne**
→ 🚨 **PROBLÈME MAJEUR** : Le cron ne s'est PAS exécuté entre 17h20 et 17h50
→ Solutions possibles :
1. Le cron job a été désactivé
2. Problème Supabase
3. Vérifier section 8

**Résultat B : Ligne(s) présente(s)**
→ Regarder la colonne `status` :

| status | Signification |
|--------|---------------|
| `succeeded` | ✅ Cron exécuté avec succès |
| `failed` | ❌ Erreur - regarder `return_message` |

Si `status = succeeded` mais pas de notification → Le problème est dans votre configuration (section 2)

### Section 5 : Défi aujourd'hui ⚠️ IMPORTANT

**Résultat : 0 lignes**
→ 🚨 Vous n'avez PAS de défi actif pour aujourd'hui !
→ **Solution** : Créer un défi via l'app

**Résultat : 1 ligne**
→ ✅ Défi existe

### Section 6 : Tous vos logs (24h)

Regardez l'historique complet pour voir si vous avez déjà reçu des notifications avant.

### Section 7 : Tous les utilisateurs

Compare votre config avec les autres utilisateurs pour voir si quelque chose diffère.

### Section 8 : Cron toujours actif

**Résultat attendu :**
```
jobid: 9
active: true
```

**Si `active = false` :**
```sql
-- Réactiver le cron
UPDATE cron.job
SET active = true
WHERE jobname = 'challengeme-daily-notifications';
```

---

## ÉTAPE 3 : Tests manuels

### Test 1 : Forcer une notification maintenant

```bash
curl -X POST 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk' \
  -H 'Content-Type: application/json' \
  -d '{"trigger":"manual-test"}'
```

Vérifier immédiatement :
```sql
SELECT * FROM notification_logs ORDER BY created_at DESC LIMIT 5;
```

### Test 2 : Changer l'heure pour dans 5 minutes

```sql
-- 1. Voir l'heure actuelle
SELECT NOW() AT TIME ZONE 'Europe/Paris' as maintenant;

-- 2. Changer votre notification_time pour dans 5 minutes
UPDATE profiles
SET notification_time = (NOW() AT TIME ZONE 'Europe/Paris' + INTERVAL '5 minutes')::time
WHERE email = 'votre-email@example.com';

-- 3. Vérifier
SELECT notification_time FROM profiles WHERE email = 'votre-email@example.com';

-- 4. Attendre 5-10 minutes et vérifier les logs
SELECT * FROM notification_logs ORDER BY created_at DESC LIMIT 5;
```

---

## 🎯 CHECKLIST DE VÉRIFICATION

Cochez chaque item :

- [ ] `notifications_enabled = true`
- [ ] `notification_time = 17:35:00` (ou l'heure souhaitée)
- [ ] `has_fcm_token = true`
- [ ] Un défi existe pour aujourd'hui (`daily_challenges` avec `challenge_date = CURRENT_DATE`)
- [ ] Le cron job est actif (`active = true`)
- [ ] Le cron s'est exécuté entre 17h20 et 17h50 (section 4)
- [ ] Il n'y a pas déjà de notification envoyée aujourd'hui (`last_notification_sent_at != today`)

---

## 🔧 SOLUTIONS RAPIDES PAR SCÉNARIO

### Scénario 1 : FCM token manquant
**Symptôme :** `has_fcm_token = false`
**Solution :**
1. Ouvrir l'app ChallengeMe
2. Aller dans Paramètres → Notifications
3. Cliquer sur "Activer les notifications"
4. Autoriser dans les paramètres système
5. Fermer complètement l'app et la rouvrir
6. Vérifier à nouveau dans la base

### Scénario 2 : Pas de défi aujourd'hui
**Symptôme :** Section 5 retourne 0 lignes
**Solution :**
1. Ouvrir l'app
2. Créer un nouveau défi via l'interface
3. Réessayer la notification

### Scénario 3 : Le cron ne s'exécute pas
**Symptôme :** Section 4 retourne 0 lignes
**Solution :**
```sql
-- Vérifier que le cron existe et est actif
SELECT * FROM cron.job WHERE jobname = 'challengeme-daily-notifications';

-- Si désactivé, réactiver
UPDATE cron.job SET active = true WHERE jobname = 'challengeme-daily-notifications';

-- Tester manuellement
SELECT
  net.http_post(
      url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
      body := '{"trigger": "manual-test"}'::jsonb
  ) AS request_id;
```

### Scénario 4 : Déjà envoyé aujourd'hui
**Symptôme :** `skip_reason = "Already sent today"`
**Solution :** C'est normal ! Le système envoie max 1 notification par jour.
```sql
-- Pour tester à nouveau, réinitialiser
UPDATE profiles
SET last_notification_sent_at = NOW() - INTERVAL '2 days'
WHERE email = 'votre-email@example.com';
```

---

## 📊 RÉSULTAT ATTENDU APRÈS CORRECTION

Après avoir corrigé les problèmes identifiés, vous devriez voir :

```sql
-- Dans notification_logs
notification_sent: true
skip_reason: NULL
error_message: NULL
time_diff_minutes: 0-15 (dans la fenêtre)
```

---

## 🆘 SI RIEN NE FONCTIONNE

Exécutez ce script de diagnostic complet et partagez-moi les résultats :

```sql
-- DIAGNOSTIC COMPLET
SELECT 'Configuration utilisateur' as section, * FROM (
    SELECT
        email,
        notifications_enabled,
        notification_time,
        fcm_token IS NOT NULL as has_fcm_token,
        last_notification_sent_at
    FROM profiles
    WHERE email = 'votre-email@example.com'
) t
UNION ALL
SELECT 'Cron job status', * FROM (
    SELECT
        CAST(jobid AS TEXT),
        schedule,
        jobname,
        CAST(active AS TEXT),
        CAST(NULL AS TIMESTAMP)
    FROM cron.job
    WHERE jobname = 'challengeme-daily-notifications'
) t
UNION ALL
SELECT 'Derniers logs', * FROM (
    SELECT
        CAST(id AS TEXT),
        trigger_type,
        CAST(notification_sent AS TEXT),
        skip_reason,
        created_at
    FROM notification_logs
    ORDER BY created_at DESC
    LIMIT 3
) t;
```

Partagez-moi le résultat complet et je pourrai vous aider davantage !
