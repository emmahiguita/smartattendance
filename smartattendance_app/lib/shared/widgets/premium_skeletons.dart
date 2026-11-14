// ============================================================================
// ARCHIVO: premium_skeletons.dart
// QUÉ HACE: Widgets skeleton (placeholder animados) que se muestran mientras
//           cargan datos reales. Imitan la estructura visual del contenido final.
// CÓMO FUNCIONA: Cada skeleton usa LoadingSkeleton como bloque base, que aplica
//                un efecto shimmer (brillo deslizante) infinito con RepaintBoundary
//                para aislar los repaints del resto del árbol de widgets.
// POR QUÉ: Mejora la percepción de velocidad (patrón "skeleton screen" de UX).
//           Separado de premium_animations.dart para mantener archivos < 200 líneas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

// QUÉ HACE: Bloque rectangular animado con efecto shimmer (brillo deslizante).
// CÓMO: Container con color semitransparente + flutter_animate .shimmer() infinito.
//       RepaintBoundary aísla el repaint del shimmer del resto de la UI.
// POR QUÉ: Es el bloque base que compone todos los skeletons (cards, tablas, etc).
class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.cBorder.withValues(alpha: 0.3),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: const Duration(milliseconds: 1500),
            color: context.cBorder.withValues(alpha: 0.5),
          ),
    );
  }
}

// QUÉ HACE: Skeleton que imita una tarjeta KPI con ícono, valor y barra.
// CÓMO: Combina varios LoadingSkeleton en un Container con bordes redondeados.
// POR QUÉ: Placeholder visual para las KPI cards del dashboard mientras cargan.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cSurface,
        border: Border.all(color: context.cBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: ícono + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LoadingSkeleton(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              LoadingSkeleton(
                width: 80,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Valor numérico grande
          LoadingSkeleton(width: 120, height: 36),
          SizedBox(height: 8),
          // Subtítulo
          LoadingSkeleton(width: 100, height: 16),
          SizedBox(height: 16),
          // Barra de progreso
          LoadingSkeleton(width: double.infinity, height: 40),
        ],
      ),
    );
  }
}

// QUÉ HACE: Skeleton que imita una fila de tabla de datos con columnas.
// CÓMO: Row con LoadingSkeletons que representan avatar + columnas de texto.
// POR QUÉ: Placeholder para la tabla de asistencias mientras carga del servidor.
class TableRowSkeleton extends StatelessWidget {
  const TableRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: const Row(
        children: [
          // Avatar circular
          LoadingSkeleton(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(width: 16),
          // Columna: nombre
          Expanded(flex: 2, child: LoadingSkeleton(width: 150, height: 16)),
          SizedBox(width: 16),
          // Columna: cédula
          Expanded(flex: 1, child: LoadingSkeleton(width: 100, height: 16)),
          SizedBox(width: 16),
          // Columna: hora
          Expanded(flex: 1, child: LoadingSkeleton(width: 100, height: 16)),
          SizedBox(width: 16),
          // Columna: badge de estado
          Expanded(
            flex: 1,
            child: LoadingSkeleton(
              width: 80,
              height: 24,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          SizedBox(width: 16),
          // Columna: tipo
          Expanded(flex: 1, child: LoadingSkeleton(width: 80, height: 16)),
          SizedBox(width: 80),
        ],
      ),
    );
  }
}

// QUÉ HACE: Envuelve cualquier widget en un efecto shimmer infinito.
// CÓMO: flutter_animate .shimmer() con repeat + RepaintBoundary.
// POR QUÉ: Útil para crear skeletons custom sobre widgets existentes.
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: const Duration(milliseconds: 1500),
            color: context.cBorder.withValues(alpha: 0.3),
          ),
    );
  }
}
