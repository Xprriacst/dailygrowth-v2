# Workflow N8N Amélioré - Génération avec Progression par Problématique

## 📋 Nouveaux Paramètres Reçus

### Format de la requête enrichie
```json
{
  "Je veux...": "Je veux travailler sur: devenir plus charismatique",
  "Combien de défi à tu relevé": "12",
  "user_id": "38118795-21a9-4b3d-afe9-b23c63936c9a",
  "progression_par_problematique": "{\"lâcher-prise\": {\"completed\": 5, \"percentage\": 10}, \"charisme\": {\"completed\": 12, \"percentage\": 24}, \"revenus\": {\"completed\": 3, \"percentage\": 6}}",
  "niveau_actuel": "intermédiaire"
}
```

## 🔄 Modifications à apporter dans le workflow n8n

### 1. Nœud "Parser Progression"
Ajouter un nœud pour parser les données de progression :

```javascript
// Parser la progression par problématique
let progressionData = {};
try {
  if (inputData.progression_par_problematique) {
    progressionData = JSON.parse(inputData.progression_par_problematique);
  }
} catch (e) {
  console.log('Erreur parsing progression:', e);
  progressionData = {};
}

// Déterminer la problématique actuelle
const currentProblematique = inputData["Je veux..."].replace("Je veux travailler sur: ", "").trim();

// Récupérer la progression pour la problématique actuelle
const currentProgression = progressionData[currentProblematique] || { completed: 0, percentage: 0 };

return {
  ...inputData,
  progression_par_problematique: progressionData,
  current_progression: currentProgression,
  niveau_actuel: inputData.niveau_actuel || 'débutant'
};
```

### 2. Nœud "Déterminer Niveau Précis"
Logique de niveau affinée :

```javascript
// Niveau basé sur la progression spécifique à la problématique
const currentProgression = inputData.current_progression;
const totalDefis = parseInt(inputData["Combien de défi à tu relevé"]);

let niveau = inputData.niveau_actuel;

// Affiner le niveau selon la progression de la problématique actuelle
if (currentProgression.percentage >= 50) {
  niveau = 'expert';
} else if (currentProgression.percentage >= 25) {
  niveau = 'avancé';
} else if (currentProgression.percentage >= 10) {
  niveau = 'intermédiaire';
} else {
  niveau = 'débutant';
}

// Logique de progression alternative
// Si l'utilisateur est fort dans d'autres domaines mais débutant dans celui-ci
const otherDomainesProgression = Object.values(inputData.progression_par_problematique || {})
  .filter(p => p.percentage > 30)
  .length;

if (otherDomainesProgression > 0 && currentProgression.percentage < 10) {
  niveau = 'intermédiaire'; // Accélérer pour les utilisateurs expérimentés
}

return {
  ...inputData,
  niveau_final: niveau,
  progression_specifique: currentProgression
};
```

### 3. Prompt Google Sheets Amélioré

```
Tu es un expert en développement personnel et coaching.

CONTEXTE DÉTAILLÉ:
- Problématique cible: {{ $json.problematique }}
- Niveau détecté: {{ $json.niveau_final }}
- Progression dans cette problématique: {{ $json.progression_specifique.completed }} défis complétés ({{ $json.progression_specifique.percentage }}%)
- Total défis complétés toutes problématiques: {{ $json.nombreDefis }}
- Progression dans autres domaines: {{ $json.progression_par_problematique }}

MISSION:
Génère UN SEUL micro-défi ultra-personnalisé qui prend en compte :
1. Le niveau spécifique dans la problématique actuelle
2. L'expérience globale dans d'autres domaines
3. La progression déjà accomplie

CRITÈRES AVANCÉS:
1. Adapté au niveau {{ $json.niveau_final }} dans CETTE problématique
2. Si progression > 25% : Défis avancés même si total global est faible
3. Si progression < 10% mais expérience globale > 30% : Défis d'accélération
4. Éviter la redondance avec les {{ $json.progression_specifique.completed }} défis déjà faits
5. Durée réaliste selon le niveau (5-45 minutes)

FORMAT DE RÉPONSE (JSON strict):
{
  "problematique": "{{ $json.problematique }}",
  "niveau_detecte": "{{ $json.niveau_final }}",
  "progression_consideree": {
    "completed": {{ $json.progression_specifique.completed }},
    "percentage": {{ $json.progression_specifique.percentage }}
  },
  "defis": [
    {
      "numero": {{ $json.progression_specifique.completed + 1 }},
      "nom": "Titre spécifique à la progression",
      "mission": "Action adaptée au niveau et à l'expérience",
      "pourquoi": "Bénéfice spécifique à ce stade de progression",
      "bonus": "Défi optionnel pour aller plus loin",
      "duree_estimee": "XX"
    }
  ]
}

EXEMLES DE PERSONNALISATION:

CAS 1 - Charisme 24% (12/50 défis):
- "Défi 13: Animer une discussion de groupe en posant des questions engageantes"
- Pourquoi: "À ce stade, passer de participant à animateur"

CAS 2 - Lâcher-prise 8% (4/50 défis) mais expérience globale 30%:
- "Défi 5: Pratiquer la pleine conscience pendant une conversation difficile"
- Pourquoi: "Utiliser votre expérience pour accélérer dans ce domaine"

CAS 3 - Revenus 60% (30/50 défis):
- "Défi 31: Créer un système de suivi automatique pour vos revenus passifs"
- Pourquoi: "Optimiser et automatiser à ce niveau avancé"
```

### 4. Nœud "Validation Enrichie"

```javascript
// Validation avec métadonnées de progression
const data = inputData;

if (!data.defis || !Array.isArray(data.defis) || data.defis.length !== 1) {
  throw new Error(`Nombre de défis incorrect: ${data.defis?.length || 0} au lieu de 1`);
}

const defi = data.defis[0];
const requiredFields = ['numero', 'nom', 'mission', 'pourquoi'];
const missingFields = requiredFields.filter(field => !defi[field]);

if (missingFields.length > 0) {
  throw new Error(`Défi incomplet - manque: ${missingFields.join(', ')}`);
}

// Validation cohérence numéro
const expectedNumero = (data.progression_specifique?.completed || 0) + 1;
if (defi.numero !== expectedNumero) {
  console.warn(`Attention: numéro ${defi.numero} différent de attendu ${expectedNumero}`);
}

// Ajouter les métadonnées de suivi
defi.generated_with_progression = {
  problematique: data.problematique,
  niveau: data.niveau_final,
  progression_specifique: data.progression_specifique,
  total_defis_globaux: data.nombreDefis,
  generated_at: new Date().toISOString()
};

return data;
```

## 🎯 Bénéfices Attendus

### 1. **Personnalisation avancée**
- Défis adaptés au niveau réel dans chaque problématique
- Accélération pour les utilisateurs expérimentés dans de nouveaux domaines

### 2. **Progression cohérente**
- Numérotation séquentielle par problématique
- Évitement de la redondance

### 3. **Expérience utilisateur**
- Défis toujours pertinents et progressifs
- Reconnaissance de l'accomplissement dans chaque domaine

## 📊 Exemple Concret

**Utilisateur avec progression :**
- Charisme: 12 défis (24%)
- Lâcher-prise: 5 défis (10%)
- Revenus: 3 défis (6%)

**Requête envoyée :**
```json
{
  "Je veux...": "Je veux travailler sur: charisme",
  "Combien de défi à tu relevé": "20",
  "progression_par_problematique": "{\"charisme\": {\"completed\": 12, \"percentage\": 24}, \"lâcher-prise\": {\"completed\": 5, \"percentage\": 10}, \"revenus\": {\"completed\": 3, \"percentage\": 6}}",
  "niveau_actuel": "intermédiaire"
}
```

**Défi généré :**
```json
{
  "defis": [
    {
      "numero": 13,
      "nom": "Leadership conversationnel",
      "mission": "Animez une discussion de groupe en posant des questions ouvertes et en rebondissant sur les réponses",
      "pourquoi": "À ce stade de progression (24%), passer de participant à animateur développe votre charisme avancé",
      "duree_estimee": "25"
    }
  ]
}
```

## 🔄 Mise à Jour du Workflow

1. **Ajouter le nœud "Parser Progression"** après la réception webhook
2. **Modifier le prompt Google Sheets** avec les nouvelles variables
3. **Mettre à jour la validation** pour inclure les métadonnées
4. **Tester** avec différents profils de progression

Le workflow devient ainsi capable de générer des défis véritablement personnalisés basés sur la progression réelle de l'utilisateur dans chaque problématique.
