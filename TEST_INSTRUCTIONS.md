# 🧪 Instructions de Test - DailyGrowth Notifications PWA

## 🚀 Démarrer le Test

### Option 1: Serveur HTTPS Local (Recommandé)
```bash
cd "/Users/alexandreerrasti/Downloads/dailygrowth v2"
python3 start_test_server.py
```

### Option 2: Serveur HTTP Simple
```bash
cd "/Users/alexandreerrasti/Downloads/dailygrowth v2"  
python3 -m http.server 8080
```

## 📱 Test sur iOS Safari 16.4+

### Étapes de Test:
1. **Ouvrir Safari iOS** → Aller sur l'URL du serveur
2. **Accepter certificat** (si HTTPS) → "Visiter ce site web"
3. **Ouvrir la page de test** → `/test_pwa_notifications.html`
4. **Accepter permissions** → Autoriser notifications quand demandé
5. **Ajouter PWA à l'écran d'accueil** :
   - Appuyer sur partager 🔗
   - "Ajouter à l'écran d'accueil"
   - Confirmer l'ajout
6. **Ouvrir depuis l'écran d'accueil** → Utiliser l'icône PWA (pas Safari)

## 🧪 Tests à Effectuer

### ✅ Tests de Base
- [ ] **Permissions accordées** → Bouton "📱 Demander Permissions"
- [ ] **Token FCM généré** → Bouton "🔥 Obtenir Token FCM"
- [ ] **PWA installée** → Status doit afficher "✅ PWA installée"

### 🔔 Tests de Notifications
- [ ] **Notification basique** → Bouton "🔔 Notification Basique"
- [ ] **Défi quotidien** → Bouton "🎯 Défi Quotidien"
- [ ] **Succès débloqué** → Bouton "🏆 Succès Débloqué" 
- [ ] **Série de 7 jours** → Bouton "🔥 Série de 7 jours"

### 🔴 Tests Badge iOS Safari 16.4+
- [ ] **Badge 1** → Bouton "🔴 Badge 1" (compteur rouge sur icône PWA)
- [ ] **Badge 5** → Bouton "🔴 Badge 5"
- [ ] **Badge 99** → Bouton "🔴 Badge 99"
- [ ] **Effacer badge** → Bouton "⚫ Effacer Badge"

## 📊 Résultats Attendus

### Sur iOS Safari 16.4+ (PWA Mode):
- ✅ **Notifications**: Apparition popup native iOS
- ✅ **Badges**: Compteur rouge sur icône PWA de l'écran d'accueil  
- ✅ **Clics notifications**: Focus sur PWA
- ✅ **Service Workers**: Enregistrés avec succès

### Sur Autres Navigateurs:
- ✅ **Notifications**: Popup navigateur standard
- ❌ **Badges**: Non supporté (sauf Chrome desktop récent)
- ✅ **FCM Token**: Généré correctement

## 🔧 Debugging

### Vérifier les Logs:
- **Console navigateur**: F12 → Console → Chercher logs Firebase 🔥
- **Logs temps réel**: Section "📊 Logs en Temps Réel" sur la page test
- **Application tab**: F12 → Application → Service Workers

### Problèmes Courants:
- **"Notifications non autorisées"** → Recharger page et accepter permissions
- **"Badge API non supporté"** → Vérifier iOS Safari 16.4+ ET mode PWA
- **Service Worker échoue** → Vérifier HTTPS et fichiers `/web/` existants
- **Token FCM vide** → Recharger page, vérifier connexion internet

## 📝 Rapport de Test

### Compléter après tests:
```
✅ ENVIRONNEMENT:
□ iOS Safari 16.4+  □ Autre navigateur
□ Mode PWA installé  □ Mode navigateur
□ HTTPS  □ HTTP

✅ FONCTIONNALITÉS TESTÉES:
□ Permissions accordées
□ Token FCM généré  
□ Notifications basiques
□ Notifications thématiques (défi, succès, série)
□ Badge API (iOS uniquement)
□ Service Workers enregistrés

✅ RÉSULTAT GLOBAL:
□ Tout fonctionne parfaitement
□ Fonctionnement partiel (préciser)
□ Problèmes majeurs (détailler)
```

## 🎯 Test Backend (Optionnel)

### Envoyer notification push depuis console Firebase:
1. **Console Firebase** → https://console.firebase.google.com/project/dailygrowth-pwa
2. **Cloud Messaging** → "Envoyer votre premier message"
3. **Copier FCM token** depuis la page de test
4. **Envoyer message test** → Vérifier réception

---

**Une fois les tests terminés, votre système de notifications PWA DailyGrowth sera validé ! 🎉**