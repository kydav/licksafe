import 'package:flutter/material.dart';
import 'package:licksafe/core/models/toxin.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result});
  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safe = result.isSafe;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusBanner(safe: safe, severity: result.highestSeverity),
              const SizedBox(height: 24),
              if (!safe) ...[
                Text(
                  'Flagged Ingredients',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...result.matches.map((m) => _ToxinCard(match: m)),
                const SizedBox(height: 24),
                _PoisonControlCard(),
                const SizedBox(height: 24),
              ],
              Text(
                'Detected Ingredients',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (result.ingredientsList.isEmpty)
                Text(
                  'Could not parse an ingredients list. Try a clearer photo.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.ingredientsList
                      .map((i) => Chip(label: Text(i, style: const TextStyle(fontSize: 12))))
                      .toList(),
                ),
              const SizedBox(height: 32),
              Text(
                'LickSafe is for informational purposes only. Always consult a veterinarian for medical advice about your pet.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withAlpha(153)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.safe, required this.severity});
  final bool safe;
  final Severity? severity;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, title, subtitle) = safe
        ? (
            const Color(0xFF1B4332),
            const Color(0xFF6FCF97),
            Icons.check_circle_rounded,
            'No toxins detected',
            'No known dog toxins were found in the scanned ingredients.',
          )
        : severity == Severity.critical
            ? (
                const Color(0xFF4A0000),
                const Color(0xFFFF6B6B),
                Icons.warning_rounded,
                'Critical — Toxic ingredients found',
                'This product contains ingredients that are highly dangerous to dogs.',
              )
            : (
                const Color(0xFF3D2000),
                const Color(0xFFFFB347),
                Icons.info_rounded,
                'Caution — Potentially harmful',
                'This product contains ingredients that may be harmful to dogs.',
              );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: fg.withAlpha(204), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToxinCard extends StatelessWidget {
  const _ToxinCard({required this.match});
  final ToxinMatch match;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (match.toxin.severity) {
      Severity.critical => (const Color(0xFFFF6B6B), 'CRITICAL'),
      Severity.high => (const Color(0xFFFF8C42), 'HIGH'),
      Severity.moderate => (const Color(0xFFFFB347), 'MODERATE'),
      Severity.caution => (const Color(0xFFFFD93D), 'CAUTION'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(76)),
        borderRadius: BorderRadius.circular(12),
        color: color.withAlpha(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.toxin.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Found: "${match.matchedAlias}"',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(match.toxin.notes, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _PoisonControlCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A2E),
        border: Border.all(color: const Color(0xFF6B21A8).withAlpha(76)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('If your dog ate this food:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          const Text(
            'Call the ASPCA Animal Poison Control Center immediately. Available 24/7.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => launchUrl(Uri.parse('tel:8884264435')),
            icon: const Icon(Icons.phone),
            label: const Text('Call 888-426-4435'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6B21A8)),
          ),
        ],
      ),
    );
  }
}
