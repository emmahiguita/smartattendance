// ============================================================================
// ARCHIVO: serviciudad_campaign_card.dart
// QUÉ HACE: Carrusel Frosted Glass de comunicación y campañas institucionales
//           de Serviciudad E.S.P. (Acueducto, Alcantarillado, Aseo y Zonas).
// CÓMO FUNCIONA: Muestra banners oficiales 16:9 con paginación interactiva,
//                categoría institucional y tarjeta desplegable de detalles.
// POR QUÉ: Comunica campañas públicas sin interferir con la asistencia (< 190 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ServiciudadCampaign {
  const ServiciudadCampaign({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.descripcion,
    required this.bannerAsset,
    required this.iconAsset,
  });

  final String id, titulo, categoria, descripcion, bannerAsset, iconAsset;
}

class ServiciudadCampaignCard extends StatefulWidget {
  const ServiciudadCampaignCard({super.key});

  @override
  State<ServiciudadCampaignCard> createState() => _ServiciudadCampaignCardState();
}

class _ServiciudadCampaignCardState extends State<ServiciudadCampaignCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<ServiciudadCampaign> _campaigns = [
    ServiciudadCampaign(
      id: 'acueducto',
      titulo: 'Cuidemos el Agua',
      categoria: 'ACUEDUCTO',
      descripcion: 'Uso eficiente y protección de las fuentes hídricas en Dosquebradas.',
      bannerAsset: AppAssets.bannerAcueducto,
      iconAsset: AppAssets.iconoAcueducto,
    ),
    ServiciudadCampaign(
      id: 'aseo',
      titulo: 'Compromiso Ambiental',
      categoria: 'ASEO',
      descripcion: 'Separación adecuada en la fuente y respeto a los horarios de recolección.',
      bannerAsset: AppAssets.bannerAseo,
      iconAsset: AppAssets.iconoAseo,
    ),
    ServiciudadCampaign(
      id: 'alcantarillado',
      titulo: 'Redes Sanitarias Limpias',
      categoria: 'ALCANTARILLADO',
      descripcion: 'No arrojes residuos sólidos ni grasas a los sumideros comunitarios.',
      bannerAsset: AppAssets.bannerAlcantarillado,
      iconAsset: AppAssets.iconoAlcantarillado,
    ),
    ServiciudadCampaign(
      id: 'zonas',
      titulo: 'Operación en Territorio',
      categoria: 'CUADRILLAS',
      descripcion: 'Supervisión geoespacial de cuadrillas activas en acueducto y redes.',
      bannerAsset: AppAssets.bannerZonas,
      iconAsset: AppAssets.iconoZonas,
    ),
  ];

  void _showDetail(ServiciudadCampaign c) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(c.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        message: Text('${c.categoria} · ${c.descripcion}\n\nServiciudad E.S.P. comprometida con la prestación eficiente de servicios domiciliarios.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _campaigns[_currentPage];

    return IosGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(c.iconAsset, width: 16, height: 16, errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.info, size: 16, color: AppColors.primary)),
              const SizedBox(width: 6),
              Text('COMUNICACIÓN INSTITUCIONAL', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: context.cTextSecondary)),
              const Spacer(),
              Text('${_currentPage + 1}/${_campaigns.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.cTextSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _campaigns.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _showDetail(_campaigns[i]),
                  child: Image.asset(_campaigns[i].bannerAsset, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.titulo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                    Text(c.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: context.cTextSecondary)),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 28),
                onPressed: () => _showDetail(c),
                child: const Text('Detalles', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
