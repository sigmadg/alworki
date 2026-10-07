import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/service_card.dart';
import '../../services/catalog_service.dart';
import '../../services/exchange_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/alworki_image.dart';
import '../widgets/category_picker.dart';
import '../widgets/home_header.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _query;
  final _requirements = TextEditingController();
  Timer? _debounce;
  bool _nearest = true;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runRemoteSearch());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _requirements.dispose();
    super.dispose();
  }

  List<String> get _requirementList => _requirements.text
      .split(RegExp(r'[,;]+'))
      .map((e) => e.trim())
      .where((e) => e.length >= 2)
      .toList();

  void _onQueryChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runRemoteSearch);
  }

  Future<void> _runRemoteSearch() async {
    if (!mounted) return;
    await context.read<CatalogService>().searchCardsRemote(
          _query.text,
          requirements: _requirementList,
          nearest: _nearest,
        );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final q = _query.text.trim();
    final results = q.isEmpty
        ? catalog.searchCards('')
        : (catalog.remoteSearchResults.isNotEmpty ? catalog.remoteSearchResults : catalog.searchCards(q));
    final hasQuery = _query.text.trim().isNotEmpty;
    final proximityOn = _nearest || catalog.proximityEnabled;
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: canPop
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: const Text('Buscar'),
            )
          : null,
      body: ColoredBox(
        color: AppColors.scaffold,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!canPop)
              const HomeHeader(
                title: 'Buscar',
                subtitle: 'Encuentra profesionales y servicios',
              ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _query,
              autofocus: widget.initialQuery.isNotEmpty,
              decoration: InputDecoration(
                hintText: 'Ej. carpintero más cercano',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _query.clear();
                          context.read<CatalogService>().searchCardsRemote('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => _onQueryChanged(),
            ),
          ),
          CategorySearchChips(
            onCategoryTap: (cat) {
              _query.text = cat.label;
              _onQueryChanged();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              controller: _requirements,
              decoration: const InputDecoration(
                hintText: 'Requisitos: muebles, madera, herramientas',
                prefixIcon: Icon(Icons.checklist_outlined),
                filled: true,
              ),
              onChanged: (_) => _onQueryChanged(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              value: _nearest,
              onChanged: (v) {
                setState(() => _nearest = v);
                _runRemoteSearch();
              },
              title: const Text('Más cercano primero'),
              subtitle: Text(
                _nearest
                    ? 'Prioriza quien esté cerca y cumpla los requisitos'
                    : 'Sin filtrar por distancia',
                style: AppTypography.caption,
              ),
            ),
          ),
          if (!hasQuery)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                proximityOn
                    ? 'Ejemplo: carpintero + muebles a medida. Sale primero el más cercano que cumpla.'
                    : 'Prueba buscar: carpintero, plomería, limpieza…',
                style: AppTypography.caption,
              ),
            ),
          Expanded(
            child: (catalog.isLoading || catalog.isSearching) && results.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasQuery ? Icons.search_off : Icons.explore_outlined,
                                size: 56,
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                hasQuery ? 'Sin resultados' : 'Explora servicios',
                                style: AppTypography.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasQuery
                                    ? 'Intenta con otra palabra clave o categoría'
                                    : 'Escribe en la barra de búsqueda o elige una categoría',
                                style: AppTypography.sectionSubtitle,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: results.length,
                        itemBuilder: (context, i) =>                         _ProviderCard(
                          card: results[i],
                          distanceKm: results[i].distanceKm ??
                              (proximityOn ? catalog.distanceKmTo(results[i]) : null),
                        ),
                      ),
          ),
        ],
      ),
    ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.card, this.distanceKm});

  final ServiceCard card;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final isLocal = card.id.isEven;

    return GestureDetector(
      onTap: () => context.push(
        '/user/${card.id}?name=${Uri.encodeComponent(card.title)}&avatar=${Uri.encodeComponent('users/${(card.id % 5) + 1}.jpg')}',
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AlworkiAvatar(avatarKey: 'users/${(card.id % 5) + 1}.jpg', radius: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.title, style: AppTypography.titleSmall.copyWith(fontSize: 15)),
                      Text(card.category, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                if (distanceKm != null)
                  _Badge(
                    label: '${distanceKm!.toStringAsFixed(1)} km',
                    color: AppColors.proximity,
                  )
                else if (isLocal)
                  _Badge(label: 'LOCAL', color: AppColors.localBadge)
                else if (!isLocal)
                  _Badge(label: 'REMOTO', color: AppColors.remoteBadge),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AlworkiImage(imageKey: card.imageKey, height: 120),
            ),
            const SizedBox(height: 10),
            Text(
              card.description,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (card.matchedRequirements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (card.meetsRequirements)
                    _Badge(label: 'Cumple requisitos', color: AppColors.proximity),
                  for (final req in card.matchedRequirements)
                    _Badge(label: req, color: AppColors.localBadge),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  '${card.rating.toStringAsFixed(1)} (${card.reviewsCount})',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '\$${card.price * 50}/hora',
                  style: AppTypography.titleSmall.copyWith(fontSize: 15, color: AppColors.navBar),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final req = await context.read<ExchangeRepository>().create(
                        title: 'Favor con ${card.title}',
                        description: 'Quiero intercambiar un favor por «${card.title}».',
                        cardId: card.id,
                        offerTitle: card.title,
                        targetUserId: card.ownerUserId,
                      );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        req != null
                            ? 'Solicitud enviada a ${card.title}'
                            : context.read<ExchangeRepository>().error ?? 'No se pudo enviar',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Proponer favor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
