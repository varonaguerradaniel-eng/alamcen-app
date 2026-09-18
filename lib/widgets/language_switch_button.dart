import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_language.dart';
import '../theme/app_colors.dart';

class LanguageSwitchButton extends StatelessWidget {
  const LanguageSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguage>();
    return PopupMenuButton<String>(
      tooltip: language.isSpanish ? 'Cambiar idioma' : 'Change language',
      onSelected: language.setLanguage,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => const [
        PopupMenuItem(value: AppLanguage.spanish, child: Text('Español')),
        PopupMenuItem(value: AppLanguage.english, child: Text('English')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 18, color: AppColors.navyDark),
            const SizedBox(width: 6),
            Text(
              language.isSpanish ? 'ES' : 'EN',
              style: const TextStyle(
                color: AppColors.navyDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
