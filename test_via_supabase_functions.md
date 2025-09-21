# Test des notifications via l'interface Supabase

## Option 1: Tester via l'onglet Functions dans Supabase Dashboard

1. Aller sur https://supabase.com/dashboard/project/hekdcsulxrukfturuone
2. Aller dans **Functions** → **send-daily-notifications**
3. Cliquer sur **Invoke Function**
4. Body JSON :
```json
{
  "trigger": "manual_test",
  "timestamp": "2025-01-18T09:50:00Z",
  "test_user": "expertiaen5min@gmail.com"
}
```

## Option 2: Test direct avec curl (depuis un terminal)

```bash
curl -X POST 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/send-daily-notifications' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNTU1MjkyMywiZXhwIjoyMDQxMTI4OTIzfQ.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk' \
  -H 'Content-Type: application/json' \
  -d '{
    "trigger": "manual_test",
    "timestamp": "2025-01-18T09:50:00Z",
    "test_user": "expertiaen5min@gmail.com"
  }'
```

## Ce que ça va faire

La fonction va :
1. Chercher tous les utilisateurs avec notifications activées
2. Calculer si c'est l'heure d'envoyer (maintenant elle trouvera expertiaen5min@gmail.com si c'est entre 8h28-8h58 UTC, soit 9h28-9h58 Paris)
3. Envoyer la notification push via FCM
4. Retourner un JSON avec le résultat

## Logs à vérifier

Dans **Functions** → **send-daily-notifications** → **Logs**, vous verrez :
- Les utilisateurs trouvés
- Les calculs de timing  
- Les tentatives d'envoi
- Les erreurs éventuelles

## Status attendu

Si tout fonctionne, vous devriez voir :
```json
{
  "message": "Daily notifications job completed",
  "notifications_sent": 1,
  "total_users_checked": 1,
  "timestamp": "2025-01-18T..."
}
```