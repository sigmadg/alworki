import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/provider_demo_data.dart';
import '../../../theme/app_colors.dart';
import 'widgets/profile_chrome_label.dart';
import '../widgets/alworki_image.dart';

/// Paso 1: elegir imagen de la galería (Figma «Publicar nuevo trabajo»).
class PublishPortfolioGalleryScreen extends StatefulWidget {
  const PublishPortfolioGalleryScreen({super.key});

  @override
  State<PublishPortfolioGalleryScreen> createState() => _PublishPortfolioGalleryScreenState();
}

class _PublishPortfolioGalleryScreenState extends State<PublishPortfolioGalleryScreen> {
  String _selected = ProviderDemoData.portfolioImages.first;

  @override
  Widget build(BuildContext context) {
    final images = ProviderDemoData.portfolioImages;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProfileChromeLabel(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Publicar nuevo trabajo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AlworkiImage(imageKey: _selected, fit: BoxFit.cover),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Galería', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: images.length,
                itemBuilder: (context, i) {
                  final key = images[i];
                  final selected = key == _selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = key),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? AppColors.navBar : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: AlworkiImage(imageKey: key, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => context.push('/publish-portfolio/details', extra: _selected),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navBar,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
