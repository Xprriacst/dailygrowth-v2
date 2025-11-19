# Correction du problème d'affichage des badges de réussite

## Problème identifié

Les badges de réussite n'apparaissaient pas correctement sur le dashboard en raison d'une **colonne manquante** dans la table `user_achievements`.

### Détails techniques

Le code Flutter essayait de lire et écrire la colonne `icon_name` dans la table `user_achievements`, mais cette colonne n'existait pas dans la base de données.

**Fichiers concernés :**
- `lib/services/gamification_service.dart:292` - Lecture de `achievement['icon_name']`
- `lib/services/user_service.dart:214` - Insertion de `icon_name`
- `lib/presentation/home_dashboard/home_dashboard.dart:282` - Mapping des icônes
- `lib/presentation/home_dashboard/widgets/achievements_section_widget.dart:129` - Affichage des icônes

**Cause :**
La migration initiale `20250927092300_create_missing_tables.sql` créait la table `user_achievements` sans la colonne `icon_name`.

## Solution appliquée

### 1. Migration de correction
Création de la migration `20251119000000_add_icon_name_to_user_achievements.sql` qui :
- Ajoute la colonne `icon_name TEXT` à la table `user_achievements`
- Crée un index pour améliorer les performances
- Ajoute la documentation de la colonne

### 2. Mise à jour de la migration initiale
Modification de `20250927092300_create_missing_tables.sql` pour :
- Inclure la colonne `icon_name` dès la création de la table
- Ajouter l'index correspondant
- Garantir la cohérence pour les nouvelles installations

## Application de la correction

### Sur Supabase (Production)

1. **Via le Dashboard Supabase :**
   - Aller dans le projet Supabase
   - Ouvrir l'éditeur SQL
   - Exécuter le contenu de `supabase/migrations/20251119000000_add_icon_name_to_user_achievements.sql`

2. **Via CLI Supabase :**
   ```bash
   supabase db push
   ```

### Vérification

Pour vérifier que la correction est appliquée, exécutez :

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'user_achievements'
AND column_name = 'icon_name';
```

Vous devriez voir :
```
column_name | data_type
------------|----------
icon_name   | text
```

## Impact

Une fois la migration appliquée :
- ✅ Les badges de réussite s'afficheront correctement sur le dashboard
- ✅ Les icônes des achievements seront visibles
- ✅ Les nouveaux achievements créés auront leurs icônes sauvegardées
- ✅ Aucun autre changement de code n'est nécessaire

## Test après application

1. Connectez-vous à l'application
2. Allez sur le dashboard
3. Vérifiez que la section "Réussites récentes" affiche les badges avec leurs icônes
4. Complétez un défi pour déclencher un nouveau badge et vérifier qu'il s'affiche correctement

## Fichiers modifiés

```
supabase/migrations/20251119000000_add_icon_name_to_user_achievements.sql (nouveau)
supabase/migrations/20250927092300_create_missing_tables.sql (modifié)
FIX_DASHBOARD_BADGES.md (nouveau)
```
