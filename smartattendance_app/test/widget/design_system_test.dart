import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/theme/app_theme.dart';

void main() {
  group('Design System - GlassSurface', () {
    testWidgets('GlassSurface renderiza con bordes y contenido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: GlassSurface(
                child: Text('Contenido Glass'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Contenido Glass'), findsOneWidget);
      expect(find.byType(GlassSurface), findsOneWidget);
    });

    testWidgets('GlassSurface responde a toques cuando onTap está definido', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: GlassSurface(
                onTap: () => tapped = true,
                child: const Text('Toca aquí'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Toca aquí'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('GlassSurface activa fallback sólido bajo alto contraste', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MediaQuery(
            data: MediaQueryData(highContrast: true),
            child: Scaffold(
              body: GlassSurface(
                child: Text('Alto Contraste'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Alto Contraste'), findsOneWidget);
      // En modo alto contraste, no se utiliza BackdropFilter para evitar costos gráficos
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });

  group('Design System - PerspectiveFlipCard', () {
    testWidgets('PerspectiveFlipCard muestra cara frontal inicialmente y gira a cara posterior', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: PerspectiveFlipCard(
                front: Text('CARA FRONTAL'),
                back: Text('CARA POSTERIOR'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('CARA FRONTAL'), findsOneWidget);

      // Toque para girar
      await tester.tap(find.byType(PerspectiveFlipCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CARA POSTERIOR'), findsOneWidget);
    });

    testWidgets('PerspectiveFlipCard respeta reducción de movimiento (disableAnimations)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: PerspectiveFlipCard(
                  front: Text('FRENTE ESTATICO'),
                  back: Text('REVERSO ESTATICO'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('FRENTE ESTATICO'), findsOneWidget);
      await tester.tap(find.byType(PerspectiveFlipCard));
      await tester.pump();

      // Cambia de inmediato sin interpolación intermedia
      expect(find.text('REVERSO ESTATICO'), findsOneWidget);
    });
  });

  group('Design System - Interactive3DTurntable', () {
    testWidgets('Interactive3DTurntable responde al arrastre horizontal', (tester) async {
      double lastAngle = 0.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: Interactive3DTurntable(
                onAngleChanged: (angle) => lastAngle = angle,
                child: Container(
                  width: 200,
                  height: 120,
                  color: Colors.blue,
                  child: const Text('Pieza 3D'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pieza 3D'), findsOneWidget);

      // Realizar arrastre horizontal
      await tester.drag(find.text('Pieza 3D'), const Offset(80, 0));
      await tester.pump();

      expect(lastAngle, isNonZero);
    });
  });

  group('Design System - EmployeeCredentialCard', () {
    testWidgets('EmployeeCredentialCard muestra datos y gira con botón accesible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: EmployeeCredentialCard(
                employeeName: 'Carlos Mendoza',
                employeeId: '1098765432',
                role: 'Supervisor de Planta',
                department: 'Operaciones e Industria',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Carlos Mendoza'), findsOneWidget);
      expect(find.text('ID: 1098765432'), findsOneWidget);
      expect(find.text('Supervisor de Planta'), findsOneWidget);
      expect(find.text('ACTIVO'), findsOneWidget);

      // Usar botón accesible para voltear
      final flipButton = find.text('Girar credencial (Frente / Reverso)');
      expect(flipButton, findsOneWidget);

      await tester.tap(flipButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('INFORMACIÓN LABORAL'), findsOneWidget);
      expect(find.text('Operaciones e Industria'), findsOneWidget);
    });
  });

  group('Design System - StatusStatesView', () {
    testWidgets('AppLoadingState muestra indicador y texto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoadingState(message: 'Verificando datos…'),
          ),
        ),
      );

      expect(find.text('Verificando datos…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppEmptyState muestra icono, mensaje y acción', (tester) async {
      var clicked = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppEmptyState(
              title: 'Sin marcaciones',
              message: 'No se encontraron registros hoy.',
              actionLabel: 'Actualizar',
              onAction: () => clicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Sin marcaciones'), findsOneWidget);
      expect(find.text('No se encontraron registros hoy.'), findsOneWidget);
      await tester.tap(find.text('Actualizar'));
      expect(clicked, isTrue);
    });

    testWidgets('AppErrorState permite reintentar', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppErrorState(
              message: 'Fallo de almacenamiento',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Fallo de almacenamiento'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      expect(retried, isTrue);
    });
  });
}
