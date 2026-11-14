// QUÉ HACE: Mantiene el nombre histórico GlassCard como sección plana.
// CÓMO: Delega en un contenedor sin marco con un divisor inferior.
// POR QUÉ: Conserva los consumidores existentes durante la limpieza visual.

import '../../core/design_system/ios_glass_card.dart';
export '../../core/design_system/ios_glass_card.dart';

/// Alias canónico hacia la tarjeta oficial Liquid Glass.
typedef GlassCard = IosGlassCard;
