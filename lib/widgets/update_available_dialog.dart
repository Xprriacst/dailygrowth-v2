import 'package:flutter/material.dart';
import '../services/version_checker_service.dart';

/// Dialog affiché quand une nouvelle version est disponible
class UpdateAvailableDialog extends StatelessWidget {
  final String newVersion;
  final String currentVersion;

  const UpdateAvailableDialog({
    super.key,
    required this.newVersion,
    required this.currentVersion,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Colors.blue, size: 28),
          SizedBox(width: 12),
          Text('Mise à jour disponible'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Une nouvelle version de ChallengeMe est disponible !',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Version actuelle: $currentVersion',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.new_releases, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Nouvelle version: $newVersion',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Rafraîchir maintenant pour profiter des dernières améliorations et corrections.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Plus tard'),
        ),
        FilledButton.icon(
          onPressed: () {
            // Fermer le dialog
            Navigator.of(context).pop();
            
            // Afficher un indicateur de chargement
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Mise à jour en cours...'),
                      ],
                    ),
                  ),
                ),
              ),
            );
            
            // Recharger après un court délai
            Future.delayed(const Duration(milliseconds: 500), () {
              VersionCheckerService.reloadApp();
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Mettre à jour'),
        ),
      ],
    );
  }

  /// Affiche le dialog si une nouvelle version est détectée
  static void showIfNeeded(
    BuildContext context, {
    required String newVersion,
    required String currentVersion,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateAvailableDialog(
        newVersion: newVersion,
        currentVersion: currentVersion,
      ),
    );
  }
}
