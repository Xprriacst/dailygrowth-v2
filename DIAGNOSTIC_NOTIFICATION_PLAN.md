# 🔍 Plan de Diagnostic - Notifications Non Reçues

## 📊 Situation actuelle

- ✅ Cron job actif et s'exécute
- ✅ Notification marquée comme "envoyée" à 17:15
- ✅ FCM Token présent
- ✅ Fuseau horaire corrigé (UTC+1)
- ❌ **Notification pas reçue sur iPhone**

## 🎯 Tests à effectuer (dans l'ordre)

### Test 1 : Vérifier les logs détaillés
**Fichier:** `deep_diagnostic.sql`

**But:** Voir les détails exacts de la notification envoyée
- Y a-t-il un `challenge_name` ?
- Y a-t-il des `error_message` ?
- Quel est le `trigger_type` ?

**Action:** Exécute dans Supabase SQL Editor et partage les résultats

---

### Test 2 : Test d'envoi direct
**Fichier:** `test_notification_direct.sql`

**But:** Envoyer une notification directement à ton token FCM
- Bypass le système de cron
- Test direct Edge Function → FCM → iPhone

**Action:** 
1. Exécute la première requête pour voir le token
2. Exécute la deuxième requête pour envoyer
3. Vérifie ton iPhone dans les 30 secondes

**Résultat attendu:**
- Si tu reçois → Problème dans le système de daily-notifications
- Si tu ne reçois pas → Problème FCM/Token/Firebase

---

### Test 3 : Vérifier Firebase Console
**URL:** https://console.firebase.google.com/project/dailygrowth-pwa

**Points à vérifier:**

1. **Authentication → Settings → Authorized domains**
   - [ ] `challengeme.ch` est dans la liste ?
   - [ ] `www.challengeme.ch` est dans la liste ?

2. **Cloud Messaging → Web configuration**
   - [ ] Web Push certificates actif ?
   - [ ] Clé VAPID présente ?

3. **Project Settings → Service Accounts**
   - [ ] Service account actif ?
   - [ ] Pas d'erreur affichée ?

---

### Test 4 : Vérifier l'app iOS
**Dans Safari sur iPhone:**

1. Ouvre https://challengeme.ch
2. Ouvre la console développeur (si possible)
3. Vérifie :
   - [ ] Pas d'erreur Firebase ?
   - [ ] Service Worker actif ?
   - [ ] Permissions notifications accordées ?

---

### Test 5 : Vérifier le Service Worker
**Fichier:** `/web/sw.js`

**Points à vérifier:**
- [ ] Firebase config utilise le bon projectId ?
- [ ] Gestion des notifications push implémentée ?
- [ ] Badge notifications configuré ?

---

## 🔬 Hypothèses par ordre de probabilité

### 1. Token FCM invalide/expiré (60%)
**Symptômes:** Backend dit "envoyé" mais rien reçu
**Solution:** Régénérer le token FCM depuis l'app

### 2. Domaine pas autorisé dans Firebase (30%)
**Symptômes:** FCM rejette silencieusement
**Solution:** Ajouter challengeme.ch dans Firebase Console

### 3. Permissions iOS bloquées (5%)
**Symptômes:** Tout fonctionne mais appareil refuse
**Solution:** Réinstaller la PWA, réautoriser les notifications

### 4. Service Worker inactif (3%)
**Symptômes:** Pas d'écoute des notifications push
**Solution:** Vérifier sw.js et réenregistrer

### 5. Problème FCM API (2%)
**Symptômes:** Erreur côté serveur non capturée
**Solution:** Vérifier les logs Edge Functions

---

## 📝 Ordre d'exécution recommandé

1. ✅ Exécute `deep_diagnostic.sql` → Partage résultats
2. ✅ Exécute `test_notification_direct.sql` → Vérifie iPhone
3. ✅ Vérifie Firebase Console → Liste ce qui manque
4. ✅ Si rien ne marche → Régénère le token FCM dans l'app
5. ✅ Re-teste avec le nouveau token

---

## 🎯 Next Steps

Une fois les tests effectués, on saura exactement où est le problème dans la chaîne :

```
[Cron] → [send-daily-notifications] → [send-push-notification] → [FCM] → [iPhone]
   ✅           ✅                            ?                      ?        ❌
```

Commence par Test 1 et partage les résultats ! 🚀
