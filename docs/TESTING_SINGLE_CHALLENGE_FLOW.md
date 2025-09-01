# Guide de Test - Nouveau Flux de Génération Unique

## Tests à Effectuer

### 1. Test du Workflow n8n Modifié

**Avant de tester l'app, modifier le workflow n8n :**

```bash
# Test manuel du webhook
curl -X POST https://polaris-ia.app.n8n.cloud/webhook/ui-defis-final \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "Je veux...=Je veux travailler sur: confiance en soi&Combien de défi à tu relevé=3"
```

**Réponse attendue :**
```json
{
  "problematique": "confiance en soi",
  "niveau_detecte": "intermédiaire",
  "defis": [
    {
      "numero": 1,
      "nom": "Nom du défi",
      "mission": "Description de la mission",
      "pourquoi": "Explication du pourquoi",
      "bonus": "Bonus optionnel",
      "duree_estimee": "15"
    }
  ]
}
```

### 2. Test de l'App Flutter

#### Scénario 1: Nouvel utilisateur
1. Créer un nouveau compte
2. Compléter l'onboarding avec une problématique
3. Vérifier qu'un seul défi est généré
4. Vérifier en base que `numero = 1`

#### Scénario 2: Utilisateur existant
1. Marquer quelques défis comme complétés
2. Générer un nouveau défi
3. Vérifier que `numero = nombreDefisComplétés + 1`
4. Vérifier que le défi est adapté au niveau

#### Scénario 3: Fallback local
1. Désactiver temporairement n8n (mauvaise URL)
2. Générer un défi
3. Vérifier que le fallback local fonctionne
4. Vérifier que `source = 'fallback_local'`

### 3. Vérifications Base de Données

```sql
-- Vérifier les micro-défis générés
SELECT 
  numero, 
  nom, 
  source, 
  is_used_as_daily,
  created_at 
FROM user_micro_challenges 
WHERE user_id = 'USER_ID' 
ORDER BY numero;

-- Vérifier la progression
SELECT 
  COUNT(*) as total_defis,
  COUNT(CASE WHEN is_used_as_daily = true THEN 1 END) as defis_utilises
FROM user_micro_challenges 
WHERE user_id = 'USER_ID';
```

### 4. Test de Performance

- Mesurer le temps de génération d'un défi vs 15 défis
- Vérifier que les timeouts n8n sont respectés
- Tester avec plusieurs utilisateurs simultanés

### 5. Test de Robustesse

#### Test des erreurs n8n
- Timeout du webhook
- Réponse invalide
- Quota API dépassé

#### Test des fallbacks
- Génération locale selon problématique
- Adaptation du niveau de difficulté
- Numérotation séquentielle correcte

## Logs à Surveiller

```dart
// Logs de succès attendus
'✅ Generated single challenge successfully: [nom_du_defi]'
'✅ Saved single micro-challenge to database: [nom_du_defi]'
'✅ Using existing micro-challenge: [nom_du_defi]'
'🎯 Generating new challenge for: [problematique] (completed: [nombre])'

// Logs de fallback attendus
'⚠️ N8n webhook failed, using local fallback: [erreur]'
'⚠️ No unused micro-challenges, generating new one via n8n'
```

## Critères de Validation

✅ **Génération unique** : 1 seul défi généré à la fois
✅ **Progression** : Numérotation séquentielle basée sur défis complétés
✅ **Personnalisation** : Défis adaptés à la problématique et au niveau
✅ **Robustesse** : Fallback local en cas d'erreur n8n
✅ **Performance** : Génération plus rapide qu'avant
✅ **Base de données** : Intégrité des données maintenue
