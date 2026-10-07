import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/service_categories.dart';
import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/alworki_image.dart';

export '../../data/service_categories.dart' show ServiceCategory, kAllServiceCategories, kFeaturedServiceCategories;

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.onCategoryTap,
    this.categories,
  });

  final void Function(ServiceCategory category) onCategoryTap;
  final List<ServiceCategory>? categories;

  @override
  Widget build(BuildContext context) {
    final items = categories ?? kAllServiceCategories;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final cat = items[i];
        return GestureDetector(
          onTap: () => onCategoryTap(cat),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AlworkiImage(imageKey: cat.imageKey, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        cat.group,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProximityBanner extends StatelessWidget {
  const ProximityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final active = catalog.proximityEnabled;

    void toggle(bool value) {
      catalog.setProximityEnabled(value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Mostrando favores dentro de ${CatalogService.defaultRadiusKm.toInt()} km'
                : 'Mostrando todos los servicios disponibles',
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: active
            ? AppColors.proximity.withValues(alpha: 0.1)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => toggle(!active),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  active ? Icons.location_on : Icons.location_off_outlined,
                  color: active ? AppColors.proximity : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active ? 'Cercanía activada' : 'Servicios cercanos',
                        style: AppTypography.titleSmall.copyWith(fontSize: 14),
                      ),
                      Text(
                        active
                            ? 'Favores más próximos primero (zona CDMX demo)'
                            : 'Toca para ver solo servicios en tu radio',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: active,
                  onChanged: toggle,
                  activeThumbColor: AppColors.proximity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.textSecondary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Buscar plomeros, enfermeras, veterinarios…',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
