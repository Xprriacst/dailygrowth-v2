# Checklist de Déploiement - Nouvelle Logique de Génération

## 🔧 Modifications Workflow n8n (CRITIQUE)

### 1. Nœud "Validation & Nettoyage"
```javascript
// REMPLACER la validation actuelle par :
if (!data.defis || !Array.isArray(data.defis) || data.defis.length !== 1) {
  throw new Error(`Nombre de défis incorrect: ${data.defis?.length || 0} au lieu de 1`);
}

const defi = data.defis[0];
if (!defi.numero || !defi.nom || !defi.mission || !defi.pourquoi) {
  throw new Error(`Défi incomplet - manque: ${!defi.numero ? 'numero ' : ''}${!defi.nom ? 'nom ' : ''}${!defi.mission ? 'mission ' : ''}${!defi.pourquoi ? 'pourquoi' : ''}`);
}
```

### 2. Fallback pour 1 défi
```javascript
// REMPLACER le fallback par défaut par :
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
} else {
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
**MODIFIER le prompt pour :**
- "Génère 1 défi personnalisé (et non 15)"
- "Le défi doit être adapté au niveau {{ $json.niveau }}"
- "Basé sur {{ $json.nombreDefis }} défis déjà relevés"

## 📱 Tests Flutter

### Commandes de test
```bash
# Test avec environnement de développement
cd "/Users/alexandreerrasti/Downloads/dailygrowth v2"
flutter run -d chrome --dart-define-from-file=env.json

# Test de build
flutter build web --dart-define-from-file=env.json
```

### Scénarios de test prioritaires
1. **Nouvel utilisateur** : Premier défi à l'inscription
2. **Utilisateur récurrent** : Génération basée sur progression
3. **Fallback n8n** : Test avec webhook désactivé

## 🗄️ Vérifications Base de Données

```sql
-- Nettoyer les anciens micro-défis de test (optionnel)
DELETE FROM user_micro_challenges WHERE source = 'test';

-- Vérifier la structure
\d user_micro_challenges;

-- Tester l'insertion d'un défi unique
INSERT INTO user_micro_challenges (
  user_id, problematique, numero, nom, mission, pourquoi, source
) VALUES (
  'test-user-id', 'confiance en soi', 1, 'Test défi', 'Test mission', 'Test pourquoi', 'test'
);
```

## 🚀 Déploiement Production

### 1. Commit des changements
```bash
git add .
git commit -m "FEAT: Nouvelle logique génération 1 défi dynamique

✅ CHANGEMENT MAJEUR: Génération à la demande vs 15 défis à l'inscription

MODIFICATIONS:
- N8nChallengeService: generateSingleMicroChallenge()
- ChallengeService: _generateNewMicroChallengeViaAI()
- UI: Mise à jour des appels API
- Workflow n8n: Validation pour 1 défi (à déployer)

AVANTAGES:
- Personnalisation dynamique selon progression
- Réduction charge API initiale
- Défis toujours adaptés au niveau actuel
- Expérience plus progressive"

git push origin main
```

### 2. Déploiement Netlify
```bash
# Build automatique via GitHub webhook
# Ou manuel si nécessaire :
npm run build
```

### 3. Tests post-déploiement
- [ ] Inscription nouvel utilisateur
- [ ] Génération premier défi
- [ ] Progression utilisateur existant
- [ ] Fallback en cas d'erreur n8n

## ⚠️ Rollback Plan

Si problème critique :
```bash
# Revenir à la version précédente
git revert HEAD
git push origin main

# Ou restaurer l'ancienne méthode temporairement
# En renommant generateSingleMicroChallengeWithFallback 
# vers generateMicroChallengesWithFallback
```

## 📊 Monitoring

### Métriques à surveiller
- Temps de génération des défis
- Taux de succès n8n vs fallback
- Engagement utilisateur avec nouveaux défis
- Erreurs de validation

### Logs critiques
```
✅ Generated single challenge successfully
❌ N8n webhook failed, using local fallback
🎯 Generating new challenge for: [problematique]
```
