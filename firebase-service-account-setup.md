# Configuration Firebase Service Account pour DailyGrowth

## 📋 Étapes pour récupérer les clés Firebase OAuth2

### 1. Générer Service Account JSON

1. **Va sur Firebase Console** : https://console.firebase.google.com/project/dailygrowth-pwa
2. **Paramètres du projet** ⚙️ → **Comptes de service**  
3. **Clique sur "Générer une nouvelle clé privée"**
4. **Télécharge le fichier JSON**

### 2. Fichier JSON contient ces informations :

```json
{
  "type": "service_account",
  "project_id": "dailygrowth-pwa",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-...@dailygrowth-pwa.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-...%40dailygrowth-pwa.iam.gserviceaccount.com"
}
```

### 3. Configuration dans Supabase

**Aller dans Supabase Dashboard → Edge Functions → Environment Variables**

Ajouter :
- **Nom :** `FIREBASE_SERVICE_ACCOUNT_KEY`
- **Valeur :** Le contenu complet du fichier JSON (en une ligne)

### 4. Alternative plus simple - Server Key Legacy

Si OAuth2 est trop complexe, on peut essayer de récupérer l'ancienne Server Key :

1. **Firebase Console** → **Cloud Messaging**
2. **Chercher "Server Key"** dans les paramètres
3. Format : `AAAA...` (très long)

**Mais attention :** Google déprécie cette méthode.