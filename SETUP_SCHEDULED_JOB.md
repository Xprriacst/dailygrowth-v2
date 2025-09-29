# 📅 Configuration du Scheduled Job Automatique

## 🎯 Objectif
Faire tourner les notifications automatiquement toutes les 15 minutes sans intervention manuelle.

## 📋 Étapes dans Supabase Dashboard

### 1. Aller dans le Dashboard
👉 https://supabase.com/dashboard/project/hekdcsulxrukfturuone

### 2. Créer le Scheduled Job
1. **Menu gauche** → **Database** → **Cron Jobs**
2. Cliquer sur **"Create a new cron job"** ou **"New Cron Job"**

### 3. Configuration du Cron Job

**Name:** `daily-notifications-every-15min`

**Schedule:** `*/15 * * * *` (toutes les 15 minutes)

**SQL Command:**
```sql
SELECT
  net.http_post(
      url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/send-daily-notifications',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
      body := ('{"trigger": "scheduled-cron", "timestamp": "' || now()::text || '"}')::jsonb
  ) AS request_id;
```

**Active:** ✅ Coché

### 4. Sauvegarder

Cliquer sur **"Create cron job"** ou **"Save"**

---

## ✅ Vérification

Après création, tu verras :
- Le job dans la liste avec schedule `*/15 * * * *`
- Status **Active**
- Prochaine exécution affichée

---

## 🎯 Résultat

Le système tournera automatiquement :
- **07:00, 07:15, 07:30, ..., 09:15, 09:30, 09:45** ← Ta notification à 9h30
- Fenêtre de ±15 min → notification envoyée entre 09:15 et 09:45
- Aucune intervention manuelle nécessaire

---

## 📊 Alternative via SQL Editor

Si l'interface ne marche pas, exécute ce SQL :

```sql
SELECT cron.schedule(
    'daily-notifications-every-15min',
    '*/15 * * * *',
    $$
    SELECT net.http_post(
        url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/send-daily-notifications',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
        body := ('{"trigger": "scheduled-cron", "timestamp": "' || now()::text || '"}')::jsonb
    );
    $$
);
```

---

## 🔍 Vérifier que ça fonctionne

**Demain matin à 9h35**, exécute ce SQL :

```sql
SELECT * FROM notification_logs 
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'expertiaen5min@gmail.com')
  AND DATE(created_at) = CURRENT_DATE
ORDER BY created_at DESC;
```

Tu devrais voir un log avec :
- `notification_sent: true`
- `trigger_type: 'scheduled-cron'`
- `created_at` vers 7h30-7h45 UTC (9h30-9h45 heure française)
