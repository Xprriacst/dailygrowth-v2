# 🔧 GUIDE DE RÉPARATION DES NOTIFICATIONS

**Problème identifié :** Le cron job de notifications n'est pas configuré dans Supabase.

**Cause :** La migration `20251108000000_setup_notification_cron.sql` n'a jamais été exécutée dans Supabase.

---

## 📋 ÉTAPE 1 : Diagnostic de l'état actuel

### 1.1 Ouvrir Supabase Dashboard

1. Aller sur : https://supabase.com/dashboard/project/hekdcsulxrukfturuone
2. Cliquer sur **"SQL Editor"** dans le menu de gauche

### 1.2 Vérifier l'état actuel du cron

Copier-coller ce script dans le SQL Editor et cliquer sur **"Run"** :

```sql
-- Lister TOUS les cron jobs existants
SELECT
    jobid,
    schedule,
    jobname,
    active,
    nodename
FROM cron.job
ORDER BY jobid;
```

**Résultats attendus :**
- ✅ Si vous voyez `challengeme-daily-notifications` → Le job existe déjà
- ❌ Si la liste est vide ou ne contient pas ce job → Il faut le créer (passer à l'étape 2)

---

## 🧹 ÉTAPE 2 : Nettoyer les anciens cron jobs

**Avant de créer le nouveau job, on supprime tous les anciens jobs de notifications pour éviter les doublons.**

Copier-coller ce script dans le SQL Editor et cliquer sur **"Run"** :

```sql
-- Supprimer TOUS les anciens jobs de notifications
DO $$
DECLARE
    job_record RECORD;
BEGIN
    FOR job_record IN
        SELECT jobid, jobname
        FROM cron.job
        WHERE jobname LIKE '%notification%'
           OR jobname LIKE '%daily%'
           OR jobname LIKE '%challengeme%'
    LOOP
        PERFORM cron.unschedule(job_record.jobid);
        RAISE NOTICE 'Supprimé job: % (ID: %)', job_record.jobname, job_record.jobid;
    END LOOP;
END $$;

-- Vérifier que tous les jobs ont été supprimés
SELECT
    jobid,
    jobname
FROM cron.job
WHERE jobname LIKE '%notification%'
   OR jobname LIKE '%daily%';
```

**Résultat attendu :** La deuxième requête devrait retourner **0 lignes** (aucun job de notifications).

---

## ✅ ÉTAPE 3 : Créer le nouveau cron job

### 3.1 Vérifier les extensions requises

Copier-coller ce script dans le SQL Editor et cliquer sur **"Run"** :

```sql
-- Activer les extensions requises
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Vérifier que les extensions sont activées
SELECT
    extname,
    extversion
FROM pg_extension
WHERE extname IN ('pg_cron', 'pg_net');
```

**Résultat attendu :** Vous devriez voir 2 lignes avec `pg_cron` et `pg_net`.

### 3.2 Créer le cron job

**⚠️ IMPORTANT : C'est le script principal qui va restaurer les notifications automatiques.**

Copier-coller ce script dans le SQL Editor et cliquer sur **"Run"** :

```sql
-- Créer le cron job pour les notifications quotidiennes
-- Ce job s'exécute toutes les 15 minutes
SELECT cron.schedule(
    'challengeme-daily-notifications',  -- Nom du job
    '*/15 * * * *',                     -- Toutes les 15 minutes
    $$
    SELECT
      net.http_post(
          url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications',
          headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
          body := ('{"trigger": "scheduled-cron", "timestamp": "' || now()::text || '"}')::jsonb
      ) AS request_id;
    $$
);

-- Vérifier que le job a été créé et est actif
SELECT
    jobid,
    schedule,
    jobname,
    active,
    command
FROM cron.job
WHERE jobname = 'challengeme-daily-notifications';
```

**Résultat attendu :**
```
jobid | schedule      | jobname                         | active | command
------|---------------|---------------------------------|--------|----------
  XX  | */15 * * * *  | challengeme-daily-notifications | true   | SELECT...
```

✅ **Si `active = true` → Le cron job est opérationnel !**

---

## 🧪 ÉTAPE 4 : Test manuel immédiat (OPTIONNEL)

**Pour tester sans attendre 15 minutes, vous pouvez déclencher manuellement une notification.**

### Option A : Depuis le terminal (recommandé)

Retourner dans le terminal et exécuter :

```bash
curl -X POST 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk' \
  -H 'Content-Type: application/json' \
  -d '{"trigger":"manual-test","timestamp":"2025-11-11T16:00:00Z"}'
```

**Résultat attendu :** Vous devriez recevoir une réponse JSON avec `"success": true`.

### Option B : Depuis Supabase SQL Editor

```sql
-- Déclencher manuellement le cron job
SELECT
  net.http_post(
      url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
      body := '{"trigger": "manual-test", "timestamp": "now"}'::jsonb
  ) AS request_id;
```

---

## 📊 ÉTAPE 5 : Vérification finale

### 5.1 Vérifier les exécutions du cron

Après avoir attendu **15-20 minutes** (ou après le test manuel), vérifier que le cron s'exécute :

```sql
-- Voir les dernières exécutions du cron job
SELECT
    r.jobid,
    j.jobname,
    r.runid,
    r.status,
    r.start_time,
    r.end_time,
    r.return_message,
    EXTRACT(EPOCH FROM (r.end_time - r.start_time)) AS duration_seconds
FROM cron.job_run_details r
JOIN cron.job j ON r.jobid = j.jobid
WHERE j.jobname = 'challengeme-daily-notifications'
ORDER BY r.start_time DESC
LIMIT 10;
```

**Résultat attendu :** Vous devriez voir des lignes avec `status = 'succeeded'`.

### 5.2 Vérifier les logs de notifications

```sql
-- Voir les notifications envoyées dans les dernières 24h
SELECT
    user_id,
    trigger_type,
    notification_sent,
    skip_reason,
    notification_time,
    actual_send_time,
    time_diff_minutes,
    created_at
FROM notification_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC
LIMIT 20;
```

**Résultat attendu :** Vous devriez voir des entrées avec `notification_sent = true` pour les utilisateurs dont l'heure de notification correspond.

### 5.3 Créer la vue de monitoring (optionnel mais recommandé)

```sql
-- Créer une vue pour faciliter le monitoring
CREATE OR REPLACE VIEW cron_job_status AS
SELECT
    j.jobid,
    j.schedule,
    j.jobname,
    j.active,
    j.nodename,
    r.status,
    r.return_message,
    r.start_time,
    r.end_time
FROM cron.job j
LEFT JOIN cron.job_run_details r ON j.jobid = r.jobid
WHERE j.jobname = 'challengeme-daily-notifications'
ORDER BY r.start_time DESC
LIMIT 10;

-- Utiliser la vue
SELECT * FROM cron_job_status;
```

---

## ✅ CHECKLIST DE VALIDATION

Cochez chaque étape au fur et à mesure :

- [ ] **Étape 1** : État actuel diagnostiqué
- [ ] **Étape 2** : Anciens cron jobs supprimés
- [ ] **Étape 3** : Extensions `pg_cron` et `pg_net` activées
- [ ] **Étape 4** : Nouveau cron job `challengeme-daily-notifications` créé
- [ ] **Étape 5** : Job visible avec `active = true`
- [ ] **Étape 6** : Test manuel réussi (optionnel)
- [ ] **Étape 7** : Exécutions visibles dans `cron.job_run_details`
- [ ] **Étape 8** : Notifications visibles dans `notification_logs`

---

## 🎯 RÉSULTAT ATTENDU

Une fois toutes les étapes complétées :

1. ✅ Le cron job s'exécute **toutes les 15 minutes**
2. ✅ Les utilisateurs reçoivent leurs notifications dans une fenêtre de **±15 minutes** autour de leur heure configurée
3. ✅ Les logs sont visibles dans `notification_logs`
4. ✅ Le système est **100% automatique** et opérationnel

---

## 🆘 TROUBLESHOOTING

### Problème : Le cron job ne s'exécute pas

**Solution :** Vérifier que :
```sql
SELECT * FROM cron.job WHERE jobname = 'challengeme-daily-notifications';
```
Retourne `active = true`.

Si `active = false`, réactiver :
```sql
UPDATE cron.job
SET active = true
WHERE jobname = 'challengeme-daily-notifications';
```

### Problème : Les notifications ne sont pas envoyées

**Solution :** Vérifier que les utilisateurs ont :
```sql
SELECT
    id,
    email,
    notifications_enabled,
    notification_time,
    fcm_token IS NOT NULL as has_fcm_token
FROM profiles
WHERE notifications_enabled = true;
```

- `notifications_enabled = true`
- `notification_time` configurée
- `fcm_token` présent (non NULL)

### Problème : Extensions manquantes

**Solution :**
```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;
```

Si vous obtenez une erreur de permissions, contactez le support Supabase.

---

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifier les logs dans `notification_logs`
2. Vérifier les exécutions dans `cron.job_run_details`
3. Tester manuellement avec le curl de l'étape 4

**Ce guide restaure le système de notifications à son état fonctionnel du 1er octobre 2025.**
