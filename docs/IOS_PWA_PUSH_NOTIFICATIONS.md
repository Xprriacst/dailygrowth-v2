# Notifications Push iOS PWA - Guide Complet

## 🎯 Résumé du Problème et Solution

### Problème Initial
Les notifications push ne fonctionnaient pas sur iOS Safari PWA car le code utilisait Firebase Cloud Messaging (FCM), qui **n'est pas supporté sur iOS Safari**.

### Solution Implémentée
Utilisation du protocole **Web Push standard avec VAPID** pour iOS, tout en maintenant FCM pour les autres plateformes.

## 📱 Prérequis iOS

1. **iOS 16.4+** - Les versions antérieures ne supportent pas Web Push
2. **PWA installée** - L'app DOIT être installée sur l'écran d'accueil
3. **Permissions accordées** - Depuis un geste utilisateur (tap/click)

### Comment installer la PWA sur iPhone

1. Ouvrir Safari et accéder à l'app
2. Appuyer sur le bouton **Partager** (carré avec flèche)
3. Sélectionner **"Sur l'écran d'accueil"**
4. Confirmer l'ajout

⚠️ **IMPORTANT**: Les notifications ne fonctionnent PAS dans Safari direct, uniquement depuis l'icône PWA.

## 🔑 Configuration des Clés VAPID

### Clés générées pour ce projet

```
Public Key:  BDoQsFQp4iutcbtRxpZRIYZp6DyZpR0xF0ol9S-r-2uUhzu2iQTxVOH1oByc0WzQl8ZkdslbfpWZ4MSlrJrebko
Private Key: 3fCzBHSOWSReLa9JSmI86cNWvtZQq7KzkXi2aZarvE4
```

### Configuration Supabase (Edge Functions)

Ajouter ces variables d'environnement dans Supabase Dashboard → Edge Functions → Settings:

```bash
WEB_PUSH_VAPID_PUBLIC_KEY=BDoQsFQp4iutcbtRxpZRIYZp6DyZpR0xF0ol9S-r-2uUhzu2iQTxVOH1oByc0WzQl8ZkdslbfpWZ4MSlrJrebko
WEB_PUSH_VAPID_PRIVATE_KEY=3fCzBHSOWSReLa9JSmI86cNWvtZQq7KzkXi2aZarvE4
WEB_PUSH_VAPID_SUBJECT=mailto:support@challengeme.app
```

### Configuration Netlify

Les clés sont déjà configurées dans `netlify.toml`:

```toml
WEB_PUSH_VAPID_PUBLIC_KEY = "BDoQsFQp4iutcbtRxpZRIYZp6DyZpR0xF0ol9S-r-2uUhzu2iQTxVOH1oByc0WzQl8ZkdslbfpWZ4MSlrJrebko"
```

## 🔄 Flux de Fonctionnement

### 1. Inscription (Côté Client)

```
Utilisateur clique "Activer notifications"
    ↓
Demande permission (Notification.requestPermission)
    ↓
Si iOS → PushManager.subscribe() avec clé VAPID Web Push
Si autre → Essayer FCM, fallback sur Web Push
    ↓
Sauvegarde subscription dans table `web_push_subscriptions`
```

### 2. Envoi (Côté Serveur)

```
Edge Function `send-daily-notifications` (cron toutes les 15min)
    ↓
Pour chaque utilisateur à notifier:
    ↓
Si FCM token → send-push-notification (FCM)
Sinon → send-webpush-notification (Web Push VAPID)
    ↓
Notification affichée sur l'appareil
```

## 📊 Base de Données

### Table `web_push_subscriptions`

```sql
CREATE TABLE web_push_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  endpoint TEXT NOT NULL UNIQUE,
  keys JSONB NOT NULL,  -- { p256dh: "...", auth: "..." }
  platform TEXT,        -- "ios-pwa", "android-pwa", etc.
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 🧪 Test des Notifications

### Test depuis l'app

1. Se connecter à l'app
2. Aller dans Profil → Notifications
3. Activer les notifications
4. Utiliser le bouton de test (🔔)

### Test manuel via Supabase

```bash
curl -X POST 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/send-webpush-notification' \
  -H 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "USER_UUID",
    "title": "🧪 Test",
    "body": "Notification de test"
  }'
```

## ⚠️ Limitations iOS Connues

1. **Pas de notifications silencieuses** - iOS révoque les permissions si une notification n'est pas affichée
2. **Pas de close() sur notifications** - Les notifications ne peuvent pas être fermées par code
3. **Service Worker strict** - iOS arrête le SW très rapidement, il faut afficher la notification IMMÉDIATEMENT
4. **Sandbox PWA** - La PWA est isolée de Safari, les données ne sont pas partagées

## 📁 Fichiers Modifiés

| Fichier | Modification |
|---------|-------------|
| `web/manifest.json` | Fix `start_url` et `scope` pour iOS |
| `web/sw.js` | Optimisation pour iOS Safari |
| `web/index.html` | Ajout clé VAPID Web Push |
| `netlify.toml` | Configuration clé VAPID |
| `lib/services/web_notification_service.dart` | Détection iOS et utilisation Web Push |

## 🚀 Déploiement

1. Commit et push sur `new-feature`
2. Configurer les secrets Supabase (clés VAPID)
3. Merger vers `main` pour déployer sur Netlify
4. Tester sur un vrai iPhone (pas le simulateur)

## 📚 Références

- [Apple Web Push Documentation](https://developer.apple.com/documentation/usernotifications/sending_web_push_notifications_in_safari_and_other_browsers)
- [Web Push Protocol](https://datatracker.ietf.org/doc/html/draft-thomson-webpush-vapid)
- [MDN PushManager](https://developer.mozilla.org/en-US/docs/Web/API/PushManager)
