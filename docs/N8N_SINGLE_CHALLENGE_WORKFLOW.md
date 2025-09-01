# Modification du Workflow n8n pour Génération Unique

## Changements requis dans le workflow n8n

### 1. Nœud "Validation & Nettoyage"
Modifier la validation pour accepter 1 seul défi :

```javascript
// Validation : vérifier qu'on a bien 1 défi
if (!data.defis || !Array.isArray(data.defis) || data.defis.length !== 1) {
  throw new Error(`Nombre de défis incorrect: ${data.defis?.length || 0} au lieu de 1`);
}

// Validation de la structure du défi unique
const defi = data.defis[0];
if (!defi.numero || !defi.nom || !defi.mission || !defi.pourquoi) {
  throw new Error(`Défi incomplet - manque: ${!defi.numero ? 'numero ' : ''}${!defi.nom ? 'nom ' : ''}${!defi.mission ? 'mission ' : ''}${!defi.pourquoi ? 'pourquoi' : ''}`);
}

// S'assurer que duree_estimee existe
if (!defi.duree_estimee) {
  defi.duree_estimee = "15";
}
```

### 2. Fallback pour 1 défi
Modifier le fallback pour retourner 1 seul défi adapté au niveau :

```javascript
// En cas d'erreur, retourner un défi par défaut adapté au niveau
const niveau = inputData.niveau;
let defiParDefaut;

if (niveau === 'débutant') {
  defiParDefaut = {
    "numero": 1,
    "nom": "Auto-observation quotidienne",
    "mission": "Notez 3 situations où vous manquez de confiance aujourd'hui",
    "pourquoi": "Identifier les patterns aide à mieux comprendre les déclencheurs",
    "bonus": null,
    "duree_estimee": "10"
  };
} else if (niveau === 'intermédiaire') {
  defiParDefaut = {
    "numero": 1,
    "nom": "Action courageuse",
    "mission": "Faites une chose qui vous intimide légèrement aujourd'hui",
    "pourquoi": "Sortir de sa zone de confort renforce progressivement la confiance",
    "bonus": "Documentez vos sensations avant et après",
    "duree_estimee": "20"
  };
} else { // avancé
  defiParDefaut = {
    "numero": 1,
    "nom": "Défi social complexe",
    "mission": "Initiez une conversation difficile que vous reportez",
    "pourquoi": "Affronter les situations complexes développe la confiance avancée",
    "bonus": "Préparez 3 points clés avant la conversation",
    "duree_estimee": "30"
  };
}

return {
  problematique: inputData.problematique,
  niveau_detecte: inputData.niveau,
  erreur: error.message,
  defis: [defiParDefaut]
};
```

### 3. Prompt Google Sheets
Modifier le prompt pour demander 1 seul défi :
- "Génère 1 défi personnalisé (et non 15)"
- "Le défi doit être adapté au niveau {{ $json.niveau }}"
- "Basé sur {{ $json.nombreDefis }} défis déjà relevés"
