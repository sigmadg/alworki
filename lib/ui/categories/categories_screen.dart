import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../home/category_grid.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_screen_insets.dart';
import '../widgets/shell_tab_header.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.scaffold,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ShellTabHeader(
              title: 'Categorías',
              subtitle: 'Explora servicios por tipo de trabajo',
              onMenuTap: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SliverToBoxAdapter(child: ProximityBanner()),
          SliverToBoxAdapter(
            child: HomeSearchBar(onTap: () => context.push('/search')),
          ),
          const SliverToBoxAdapter(
            child: AppSectionHeader(
              title: 'Todos los oficios',
              subtitle: 'Salud, mascotas, hogar, educación, gastronomía y más',
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            ),
          ),
          SliverToBoxAdapter(
            child: CategoryGrid(
              onCategoryTap: (cat) => context.push(
                '/search?q=${Uri.encodeComponent(cat.query)}',
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppScreenInsets.shellBottom(context))),
        ],
      ),
    );
  }
}
