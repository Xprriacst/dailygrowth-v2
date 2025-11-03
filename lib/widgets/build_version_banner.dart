import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/build_version_helper.dart';

class BuildVersionBanner extends StatelessWidget {
  const BuildVersionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    final buildVersion = getAppBuildVersion();
    if (buildVersion.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        'Build $buildVersion',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              fontStyle: FontStyle.italic,
            ) ??
            TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}
