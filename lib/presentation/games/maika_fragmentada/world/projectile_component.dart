import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'enemy_component.dart';
import 'player_component.dart';
import 'rpg_game_world.dart';
import 'shield_component.dart';

class ProjectileComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference<RpgGameWorld> {
  ProjectileComponent({
    required this.velocity,
    required this.owner,
    required Vector2 position,
    double radius = 6,
    Sprite? sprite,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  Vector2 velocity;
  bool hasBounced = false;
  final EnemyComponent owner;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    paint.filterQuality = FilterQuality.none;

    add(
      CircleHitbox()..collisionType = CollisionType.active,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Substeps simples para reducir tunelizacion a altas velocidades.
    final halfDt = dt * 0.5;
    position += velocity * halfDt;
    position += velocity * halfDt;

    // Eliminar cuando sale del mapa jugable, no solo del viewport.
    final bounds = game.mapBounds;
    if (bounds != null &&
        (position.x < bounds.left - 32 ||
            position.y < bounds.top - 32 ||
            position.x > bounds.right + 32 ||
            position.y > bounds.bottom + 32)) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is ShieldComponent) {
      if (hasBounced) {
        return;
      }

      final player = other.player;

      if (!hasBounced && player.hasShield) {
        final facing = player.facingDirection.length2 == 0
            ? Vector2(0, 1)
            : player.facingDirection.normalized();
        final toProjectile = (position - player.position).normalized();

        final dot = facing.dot(toProjectile);

        if (dot > 0.6) {
          final shieldCenter = other.absolutePosition;
          final normal = (position - shieldCenter).normalized();
          final vDotN = velocity.dot(normal);
          velocity = velocity - normal * (2 * vDotN);
          velocity *= 1.15;
          hasBounced = true;

          add(
            ScaleEffect.to(
              Vector2.all(1.2),
              EffectController(
                duration: 0.08,
                reverseDuration: 0.08,
              ),
            ),
          );
          add(
            RotateEffect.by(
              pi / 4,
              EffectController(duration: 0.1),
            ),
          );

          return;
        }
      }

      removeFromParent();
      return;
    }

    if (other is EnemyComponent) {
      if (hasBounced && other == owner) {
        other.takeDamage(1);
      }
      removeFromParent();
      return;
    }

    if (other is PlayerComponent) {
      other.takeHit();
      removeFromParent();
      return;
    }

    if (hasBounced) {
      removeFromParent();
    }
  }
}
