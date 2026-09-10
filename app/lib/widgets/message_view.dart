import 'package:flutter/material.dart';

/// Poruka preko celog ekrana: ikonica, kratak tekst, po potrebi objašnjenje.
///
/// Koristi se za sva stanja u kojima nema šta da se prikaže — nema porudžbina,
/// učitava se, ili je pukla veza sa bazom.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.text,
    this.detail,
    this.color,
  });

  final IconData icon;
  final String text;
  final String? detail;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boja = color ?? theme.colorScheme.outline;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: boja),
            const SizedBox(height: 12),
            Text(
              text,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (detail != null && detail!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Poruka „učitava se", sa vrteškom umesto ikonice.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.text = 'Učitavanje porudžbina...'});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
