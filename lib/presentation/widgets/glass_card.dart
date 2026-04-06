import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';

/// Card reutilizable con aspecto "glass" para pantallas de perfil/ajustes.
///
/// - Fondo semi-transparente sobre el `surface` actual
/// - Bordes redondeados (por defecto 20)
/// - Borde sutil y sombra ligera
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(borderRadius);

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: scheme.overlayOnSurface(0.10),
        borderRadius: radius,
        border: Border.all(
          color: scheme.overlayOnSurface(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: scheme.brightness == Brightness.dark ? 0.35 : 0.15,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
