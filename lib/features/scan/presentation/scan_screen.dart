import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:licksafe/core/services/ocr_service.dart';
import 'package:licksafe/core/services/toxin_service.dart';
import 'package:licksafe/features/result/presentation/result_screen.dart';

class ScanScreen extends HookConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = useState(false);
    final error = useState<String?>(null);
    final cs = Theme.of(context).colorScheme;

    Future<void> process(XFile picked) async {
      loading.value = true;
      error.value = null;
      try {
        final ocrService = OcrService();
        final text = await ocrService.extractText(File(picked.path));
        ocrService.dispose();
        if (text.trim().isEmpty) {
          error.value = 'No text detected. Try a clearer photo of the ingredients list.';
          return;
        }
        final result = await ref.read(toxinServiceProvider).scan(text);
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
        );
      } catch (e) {
        error.value = 'Something went wrong. Please try again.';
      } finally {
        loading.value = false;
      }
    }

    Future<void> pickImage(ImageSource source) async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked != null) await process(picked);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'LickSafe',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: cs.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Scan a food label to check for ingredients that are toxic to dogs.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _BigButton(
                icon: Icons.camera_alt_rounded,
                label: 'Scan Label',
                sublabel: 'Take a photo',
                onTap: loading.value ? null : () => pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 16),
              _BigButton(
                icon: Icons.photo_library_rounded,
                label: 'Choose Photo',
                sublabel: 'From your library',
                onTap: loading.value ? null : () => pickImage(ImageSource.gallery),
                outlined: true,
              ),
              if (loading.value) ...[
                const SizedBox(height: 32),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                Text(
                  'Reading ingredients…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
              if (error.value != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error.value!,
                    style: TextStyle(color: cs.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'LickSafe is for informational purposes only and is not a substitute for veterinary advice. If your dog has ingested something harmful, call the ASPCA Poison Control: 888-426-4435.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withAlpha(153),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback? onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: outlined ? Colors.transparent : cs.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: outlined
              ? BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, size: 32, color: outlined ? cs.primary : cs.onPrimary),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: outlined ? cs.primary : cs.onPrimary,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: outlined ? cs.onSurfaceVariant : cs.onPrimary.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
