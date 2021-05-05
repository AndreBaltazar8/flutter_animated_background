import 'dart:math' as math;

import 'package:animated_background/animated_background.dart';
import 'package:flutter/widgets.dart';

/// Holds the information of a star used in a [SpaceBehaviour].
class Star {
  /// The position of the star
  Offset? position;

  /// The target position of the star
  late Offset targetPosition;

  /// The distance of the start to the screen
  late double distance;
}

/// Renders a warp field on a [AnimatedBackground].
///
/// Code inspired by http://www.kevs3d.co.uk/dev/warpfield/
class SpaceBehaviour extends Behaviour {
  static math.Random random = math.Random();

  /// The center of the warp field.
  @protected
  Offset? center;

  /// The target center of the warp field.
  ///
  /// Changing this value will cause the [center] to animate to this value.
  @protected
  Offset? targetCenter;

  /// The list of stars spawned by the behaviour
  @protected
  List<Star>? stars;

  late Color _backgroundColor;

  SpaceBehaviour({
    Color backgroundColor = const Color(0xFF000000),
  }) {
    _backgroundColor = backgroundColor;
  }

  @override
  void init() {
    center = Offset(size!.width / 2.0, size!.height / 2.0);
    targetCenter = center;
    stars = List<Star>.generate(500, (_) {
      var star = Star();
      _initStar(star);
      return star;
    });
  }

  void _initStar(Star star) {
    star.targetPosition = Offset(
      (random.nextDouble() * size!.width - size!.width / 2) * 1000.0,
      (random.nextDouble() * size!.height - size!.height / 2) * 1000.0,
    );

    if (star.position != null) {
      star.distance = 1000.0;
      star.position = Offset.zero;
    } else {
      star.distance = random.nextDouble() * 1000.0;
      star.position = Offset(
        star.targetPosition.dx / star.distance,
        star.targetPosition.dy / star.distance,
      );
    }
  }

  @override
  void initFrom(Behaviour oldBehaviour) {
    if (oldBehaviour is SpaceBehaviour) {
      stars = oldBehaviour.stars;
      center = oldBehaviour.center;
      targetCenter = oldBehaviour.targetCenter;
    }
  }

  @override
  bool get isInitialized => stars != null && center != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    var paint = Paint()..style = PaintingStyle.fill;

    canvas.drawPaint(Paint()..color = _backgroundColor);

    canvas.translate(center!.dx, center!.dy);
    int i = 0;
    double time = DateTime.now().millisecondsSinceEpoch.toDouble() / 1000.0;
    for (Star star in stars!) {
      if (star.position!.dx == 0 || star.distance <= 0.0) continue;
      paint.color = Color.fromARGB(
        0x80,
        (math.sin(0.3 * i + 0 + time) * 64.0 + 190.0).floor(),
        (math.sin(0.3 * i + 2 + time) * 64.0 + 190.0).floor(),
        (math.sin(0.3 * i + 4 + time) * 64.0 + 190.0).floor(),
      );

      var x = star.targetPosition.dx / star.distance * 1.02;
      var y = star.targetPosition.dy / star.distance * 1.02;
      double z = 1.0 / star.distance * 6.0 + 1.0;
      paint.strokeWidth = z;
      canvas.drawLine(
        Offset(x, y),
        star.position!,
        paint,
      );
      i++;
    }
    canvas.translate(-center!.dx, -center!.dy);
  }

  @override
  bool tick(double delta, Duration elapsed) {
    center = Offset.lerp(center, targetCenter, delta * 5.0);
    for (Star star in stars!) {
      star.position = Offset(
        star.targetPosition.dx / star.distance,
        star.targetPosition.dy / star.distance,
      );
      star.distance -= delta * 500;
      if (star.distance <= 0 ||
          star.position!.dx > size!.width ||
          star.position!.dy > size!.height) _initStar(star);
    }
    return true;
  }

  @override
  Widget builder(
      BuildContext context, BoxConstraints constraints, Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) => _updateCenter(context, details.globalPosition),
      onTapDown: (details) => _updateCenter(context, details.globalPosition),
      child: ConstrainedBox(
        // necessary to force gesture detector to cover screen
        constraints: BoxConstraints(
            minHeight: double.infinity, minWidth: double.infinity),
        child: super.builder(context, constraints, child),
      ),
    );
  }

  void _updateCenter(BuildContext context, Offset globalPosition) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var localPosition = renderBox.globalToLocal(globalPosition);
    targetCenter = localPosition;
  }
}

/// Render a wrap field like [SpaceBehaviour] but animated the child as a star.
///
/// This is an very experimental behaviour, which could be implemented as a
/// normal Flutter animation. It can be removed at any time.
///
/// Known issues:
///  - Gesture detection does not work properly while is animating.
class ChildFlySpaceBehaviour extends SpaceBehaviour {
  bool _flying = true;
  double _childZ = 100.0;

  @override
  bool tick(double delta, Duration elapsed) {
    if (_flying) {
      _childZ = math.max(0.0, _childZ - 50 * delta);
      renderObject!.markNeedsLayout();
      if (_childZ == 0.0) _flying = false;
    }

    return super.tick(delta, elapsed);
  }

  @override
  Widget builder(
      BuildContext context, BoxConstraints constraints, Widget child) {
    double widgetX = 0.0, widgetY = 0.0;
    if (renderObject!.hasSize) {
      widgetX = size!.width / 2 * _childZ;
      widgetY = size!.height / 2 * _childZ;
    }

    return Opacity(
      opacity: (100 - _childZ) / 100,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 1.0)
          ..translate(widgetX, widgetY, _childZ),
        child: super.builder(context, constraints, child),
      ),
    );
  }
}
