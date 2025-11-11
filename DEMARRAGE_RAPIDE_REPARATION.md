# 🚀 DÉMARRAGE RAPIDE - Réparation des Notifications

## 📌 Résumé du problème

**Les notifications fonctionnaient le 1er octobre 2025**, mais ne fonctionnent plus aujourd'hui.

**Cause :** Le cron job qui déclenche les notifications automatiquement n'est pas configuré dans Supabase.

---

## ⚡ SOLUTION RAPIDE (5 minutes)

### 1️⃣ Ouvrir Supabase Dashboard

https://supabase.com/dashboard/project/hekdcsulxrukfturuone/sql

### 2️⃣ Copier-coller ce script SQL

```sql
-- Activer les extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Supprimer les anciens jobs de notifications
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname LIKE '%notification%' OR jobname LIKE '%daily%';

-- Créer le nouveau cron job
SELECT cron.schedule(
    'challengeme-daily-notifications',
    '*/15 * * * *',
    $$
    SELECT
      net.http_post(
          url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications',
          headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
          body := ('{"trigger": "scheduled-cron", "timestamp": "' || now()::text || '"}')::jsonb
      ) AS request_id;
    $$
);

-- Vérifier que ça a marché
SELECT jobid, schedule, jobname, active
FROM cron.job
WHERE jobname = 'challengeme-daily-notifications';
```

### 3️⃣ Cliquer sur "Run"

Vous devriez voir :
```
jobid | schedule      | jobname                         | active
------|---------------|---------------------------------|--------
  XX  | */15 * * * *  | challengeme-daily-notifications | true
```

✅ **C'est tout ! Les notifications sont maintenant réparées.**

---

## 🧪 Test immédiat (optionnel)

Pour tester sans attendre 15 minutes :

```bash
./test_notifications_manuellement.sh
```

Ou via curl :

```bash
curl -X POST 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk' \
  -H 'Content-Type: application/json' \
  -d '{"trigger":"manual-test"}'
```

---

## 📊 Vérifier que ça marche

Dans Supabase SQL Editor :

```sql
-- Voir les logs de notifications
SELECT * FROM notification_logs
ORDER BY created_at DESC
LIMIT 10;

-- Voir les exécutions du cron
SELECT * FROM cron_job_status;
```

---

## 📚 Documentation complète

Pour plus de détails, consulter :

- **`GUIDE_REPARATION_NOTIFICATIONS.md`** : Guide complet étape par étape
- **`COMPARAISON_AVANT_APRES.md`** : Analyse détaillée des différences
- **`check_cron_status.sql`** : Script de diagnostic complet
- **`test_notifications_manuellement.sh`** : Script de test automatique

---

## ❓ FAQ

### Les notifications vont-elles s'envoyer immédiatement ?

Non, elles s'envoient dans une fenêtre de **±15 minutes** autour de l'heure configurée par chaque utilisateur.

### À quelle fréquence le cron job s'exécute-t-il ?

**Toutes les 15 minutes**, 24h/24, 7j/7.

### Comment savoir si un utilisateur va recevoir une notification ?

Il faut que :
- ✅ `notifications_enabled = true`
- ✅ `notification_time` configurée
- ✅ `fcm_token` présent (l'utilisateur a autorisé les notifications)
- ✅ L'heure actuelle soit dans la fenêtre ±15 min de son `notification_time`

---

## ✅ Résultat attendu

Après cette réparation, le système sera **exactement comme le 1er octobre 2025** quand ça marchait, avec le rebranding ChallengeMe appliqué.
