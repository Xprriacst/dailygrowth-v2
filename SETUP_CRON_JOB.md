# 🔧 Configuration du Cron Job pour les Notifications

## ⚠️ PROBLÈME IDENTIFIÉ

Le système de notifications ne fonctionne pas car **le cron job pg_cron n'est pas configuré** dans Supabase.

Les Edge Functions sont déployées et fonctionnelles, mais elles ne sont jamais appelées automatiquement.

## ✅ SOLUTION : Configurer le Cron Job

### Étape 1 : Activer les extensions requises

1. Va sur **Supabase Dashboard** : https://supabase.com/dashboard/project/hekdcsulxrukfturuone
2. Clique sur **Database** > **Extensions** dans le menu gauche
3. Active les extensions suivantes si ce n'est pas déjà fait :
   - ✅ **pg_cron** (pour les tâches planifiées)
   - ✅ **pg_net** (pour les appels HTTP depuis pg_cron)

### Étape 2 : Exécuter le script de configuration

1. Va sur **SQL Editor** dans le menu gauche
2. Crée une nouvelle query
3. Copie-colle le contenu du fichier : `supabase/migrations/20251108000000_setup_notification_cron.sql`
4. Clique sur **Run** pour exécuter

### Étape 3 : Vérifier que le cron job fonctionne

1. Dans le **SQL Editor**, exécute le script : `check_cron_status.sql`
2. Vérifie que :
   - Le job `challengeme-daily-notifications` existe
   - Le champ `active` est à `true`
   - Le schedule est `*/15 * * * *` (toutes les 15 minutes)

### Étape 4 : Attendre la première exécution

- Le cron job s'exécute **toutes les 15 minutes**
- Attends maximum 15 minutes après la configuration
- Les notifications seront envoyées aux utilisateurs dont l'heure configurée est dans la fenêtre ±15 minutes

## 📊 Monitoring

### Vérifier les exécutions du cron

```sql
-- Voir les dernières exécutions du cron job
SELECT * FROM cron_job_status;
```

### Vérifier les logs de notifications

```sql
-- Voir les dernières tentatives d'envoi
SELECT 
    user_id,
    notification_sent,
    skip_reason,
    notification_time,
    actual_send_time,
    time_diff_minutes,
    created_at
FROM notification_logs
ORDER BY created_at DESC
LIMIT 10;
```

## 🎯 Workflow complet

1. **Cron job** (toutes les 15 min) → Appelle `cron-daily-notifications`
2. **cron-daily-notifications** → Appelle `send-daily-notifications`  
3. **send-daily-notifications** → Vérifie les utilisateurs et envoie via `send-push-notification`
4. **send-push-notification** → Envoie la notification FCM vers l'app
5. **Notification reçue** → Utilisateur cliqué → Redirigé vers `challengeme.ch`

## ⚡ Test manuel immédiat

Si tu veux tester sans attendre le cron, tu peux appeler manuellement :

```bash
# Appeler directement la fonction cron
curl -X POST 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk' \
  -H 'Content-Type: application/json' \
  -d '{"trigger":"manual-test","timestamp":"2025-11-08T16:00:00Z"}'
```

## 🔍 Troubleshooting

### Le cron job ne s'exécute pas

1. Vérifie que les extensions `pg_cron` et `pg_net` sont activées
2. Vérifie que le job est `active = true`
3. Regarde les logs dans `cron.job_run_details`

### Les notifications ne sont pas envoyées

1. Vérifie que les utilisateurs ont :
   - `notifications_enabled = true`
   - Un `fcm_token` valide
   - Une `notification_time` configurée
2. Vérifie que l'heure actuelle est dans la fenêtre ±15 minutes de leur `notification_time`
3. Regarde la table `notification_logs` pour les détails

### Les notifications redirigeant vers l'ancien domaine

✅ **DÉJÀ CORRIGÉ** : Les Edge Functions utilisent maintenant `challengeme.ch`

## 📅 Historique

- **08/11/2025** : Identification du problème (cron job manquant)
- **30/09/2025** : Dernier cron job fonctionnel (commit 85ebcdb)
- **27/09/2025** : Tests validés avec l'ancien domaine
