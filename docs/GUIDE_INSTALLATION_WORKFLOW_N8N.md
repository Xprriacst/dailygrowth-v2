# 🚀 Guide d'Installation du Workflow n8n - ChallengeMe

## 📋 Vue d'ensemble

Ce workflow génère **1 défi à la fois** parmi **50 défis possibles** par problématique :
- **Défis 1-30** : Récupérés du CSV (défis pré-écrits)
- **Défis 31-50** : Générés par IA (niveau expert)

---

## 📦 Fichiers fournis

| Fichier | Description |
|---------|-------------|
| `docs/N8N_WORKFLOW_COMPLET.json` | Workflow n8n prêt à importer |
| `docs/PROMPT_EXPERT_GOOGLE_SHEETS.md` | Prompt pour les défis 31-50 |
| `/Users/alexandreerrasti/Downloads/ChallengeMe Dailygrowth micro défis.csv` | CSV des 30 premiers défis |

---

## 🔧 Étapes d'installation

### Étape 1 : Préparer Google Sheets

#### 1.1 Créer l'onglet "Micro-Défis"

1. Ouvre ton Google Sheets "ChallengeMe (Dailygrowth)"
2. Crée un nouvel onglet nommé **"Micro-Défis"**
3. Va dans **Fichier → Importer**
4. Importe le fichier CSV : `ChallengeMe Dailygrowth micro défis.csv`
5. Choisis "Remplacer la feuille actuelle"

Les colonnes doivent être :
- `problematique`
- `defi_numero`
- `defi_mission`
- `Durée défi min`
- `dificulté defi 1 à 3`

#### 1.2 Créer l'onglet "Prompt Expert"

1. Crée un nouvel onglet nommé **"Prompt Expert"**
2. Copie le prompt complet depuis `docs/PROMPT_EXPERT_GOOGLE_SHEETS.md`
3. Colle-le dans la cellule **A1**

---

### Étape 2 : Importer le workflow dans n8n

1. Ouvre n8n : https://polaris-ia.app.n8n.cloud
2. Va dans **Workflows → Import**
3. Importe le fichier `docs/N8N_WORKFLOW_COMPLET.json`
4. Vérifie les connexions :
   - **Google Sheets** : Compte connecté
   - **OpenAI** : API Key configurée

---

### Étape 3 : Configurer les nœuds Google Sheets

#### Nœud "Get CSV Challenges"
```
Document: ChallengeMe (Dailygrowth)
Sheet: Micro-Défis
```

#### Nœud "Get Prompt Expert"
```
Document: ChallengeMe (Dailygrowth)
Sheet: Prompt Expert
Range: A1 (première ligne)
```

---

### Étape 4 : Tester le workflow

#### Test 1 : Défi du CSV (numéro <= 30)
```bash
curl -X POST https://polaris-ia.app.n8n.cloud/webhook/e4b66ea3-6195-4b11-89fe-85d05d23cae9 \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "Je veux...=Je veux travailler sur: Mieux gérer mes émotions&Combien de défi à tu relevé=4"
```

**Réponse attendue** (défi 5 du CSV) :
```json
{
  "problematique": "Mieux gérer mes émotions",
  "niveau_detecte": "débutant",
  "source": "csv",
  "defis": [{
    "numero": 5,
    "nom": "Défi 5",
    "mission": "Échelle émotionnelle – Sur une échelle de 1 à 10, évalue l'intensité de ton émotion principale du jour.",
    "pourquoi": "Ce défi fait partie de ta progression personnalisée.",
    "bonus": null,
    "duree_estimee": ""
  }]
}
```

#### Test 2 : Défi expert IA (numéro > 30)
```bash
curl -X POST https://polaris-ia.app.n8n.cloud/webhook/e4b66ea3-6195-4b11-89fe-85d05d23cae9 \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "Je veux...=Je veux travailler sur: Mieux gérer mes émotions&Combien de défi à tu relevé=34"
```

**Réponse attendue** (défi 35 généré par IA) :
```json
{
  "problematique": "Mieux gérer mes émotions",
  "niveau_detecte": "expert",
  "source": "ai_expert",
  "defis": [{
    "numero": 35,
    "nom": "Routine émotionnelle quotidienne",
    "mission": "Crée et applique ta propre routine de gestion émotionnelle...",
    "pourquoi": "L'intégration quotidienne transforme les techniques...",
    "bonus": "Note les changements observés...",
    "duree_estimee": "7j"
  }]
}
```

---

## 🔄 Flux de données

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                             │
│  - Récupère nombreDefis (défis complétés)                       │
│  - Récupère progression_par_problematique                       │
│  - Envoie requête à n8n                                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      WEBHOOK N8N                                 │
│  Parse Input Data:                                               │
│  - problematique                                                 │
│  - nombreDefis                                                   │
│  - progression_par_problematique                                 │
│  - Calcule: numeroDefi = nombreDefis + 1                        │
│  - Détermine: useAI = (numeroDefi > 30)                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │     Router CSV vs AI        │
              └──────────────┬──────────────┘
                             │
          ┌──────────────────┴──────────────────┐
          │                                      │
          ▼                                      ▼
┌─────────────────────┐              ┌─────────────────────┐
│   useAI = false     │              │   useAI = true      │
│   (défis 1-30)      │              │   (défis 31-50)     │
└─────────┬───────────┘              └─────────┬───────────┘
          │                                      │
          ▼                                      ▼
┌─────────────────────┐              ┌─────────────────────┐
│ Get CSV Challenges  │              │ Get Prompt Expert   │
│ (Google Sheets)     │              │ (Google Sheets)     │
└─────────┬───────────┘              └─────────┬───────────┘
          │                                      │
          ▼                                      ▼
┌─────────────────────┐              ┌─────────────────────┐
│ Find CSV Challenge  │              │ AI Agent Expert     │
│ (recherche numéro)  │              │ (GPT-4o-mini)       │
└─────────┬───────────┘              └─────────┬───────────┘
          │                                      │
          │                                      ▼
          │                          ┌─────────────────────┐
          │                          │ Validate Response   │
          │                          │ (nettoyage JSON)    │
          │                          └─────────┬───────────┘
          │                                      │
          └──────────────┬───────────────────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │    Merge Results    │
              └─────────┬───────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │   Select Result     │
              └─────────┬───────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │   Response Final    │
              │   (JSON 1 défi)     │
              └─────────────────────┘
```

---

## 📊 Correspondance Problématiques CSV ↔ App

| Emoji | Problématique CSV | Exemples de recherche Flutter |
|-------|-------------------|-------------------------------|
| 🧠 | Mieux gérer mes émotions | "émotions", "gérer mes émotions" |
| 💪 | Rebondir après un échec | "échec", "rebondir" |
| 🌊 | Apprendre le lâcher-prise | "lâcher-prise", "lacher-prise" |
| ⚡ | Me fixer des règles et les respecter | "règles", "respecter" |
| 👂 | Être plus empathique et développer mon écoute active | "empathie", "écoute" |
| 🤝 | Devenir plus charismatique et développer mon réseau | "charismatique", "charisme", "réseau" |
| 💬 | M'affirmer (oser dire les choses sans blesser) | "affirmer", "dire les choses" |
| 😶 | Surmonter ma timidité et oser m'exprimer | "timidité", "m'exprimer" |
| ⚖️ | Mieux gérer les conflits et critiques | "conflits", "critiques" |
| 🚀 | Entreprendre et développer ma créativité | "entreprendre", "créativité" |
| 💰 | Diversifier mes sources de revenus | "revenus", "diversifier" |
| 🎯 | Prendre des risques calculés | "risques", "décisions" |
| ✨ | Trouver ma passion | "passion", "trouver" |
| 🌟 | Vivre de ma passion | "vivre passion" |
| 🚫 | Sortir de ma dépendance | "dépendance", "addiction" |
| ❤️ | Améliorer mon cardio | "cardio", "sport" |
| ⚖️ | Perdre du poids | "poids", "maigrir" |
| 📅 | Mieux m'organiser | "organiser", "temps" |
| ⏰ | Arrêter de procrastiner | "procrastiner", "concentration" |
| 🔥 | Ne pas abandonner trop vite | "abandonner", "persévérer" |
| 🎯 | Définir mes priorités | "priorités" |
| 🗺️ | Planifier ma vie | "planifier", "objectifs" |
| 💪 | Prendre confiance en moi | "confiance" |
| 🛡️ | Apprendre à dire non | "dire non" |
| 🔍 | Arrêter de me comparer aux autres | "comparer" |
| 🤗 | Accepter qui je suis | "accepter" |
| 📵 | Réduire mon temps d'écran | "écran", "téléphone" |

---

## ⚠️ Points d'attention

### Recherche de problématique
Le workflow effectue une recherche **souple** dans le CSV :
1. Correspondance exacte
2. Correspondance partielle (mots-clés)
3. Fallback générique si non trouvé

### Gestion des erreurs
- Si le défi n'est pas trouvé dans le CSV → Fallback générique
- Si l'IA échoue → Fallback expert prédéfini
- Toujours 1 défi retourné, jamais d'erreur bloquante

### Performance
- Défis 1-30 : ~500ms (lecture CSV)
- Défis 31-50 : ~2-5s (génération IA)

---

## ✅ Checklist finale

- [ ] CSV importé dans Google Sheets (onglet "Micro-Défis")
- [ ] Prompt Expert copié dans Google Sheets (onglet "Prompt Expert")
- [ ] Workflow importé dans n8n
- [ ] Credentials Google Sheets connectés
- [ ] Credentials OpenAI connectés
- [ ] Test défi 1-30 OK
- [ ] Test défi 31-50 OK
- [ ] Code Flutter à jour (branche new-feature)

---

## 🎉 C'est prêt !

Le système génère maintenant :
- **1 défi à la fois** (pas 50 d'un coup)
- **Progression de 1 à 50** basée sur les défis complétés
- **Défis 1-30** : Fidèles au CSV pré-écrit
- **Défis 31-50** : Générés dynamiquement avec progression
