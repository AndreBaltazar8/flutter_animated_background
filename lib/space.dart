import 'dart:math' as math;

import 'package:animated_background/animated_background.dart';
import 'package:flutter/widgets.dart';

class Star {
  Offset position;
  Offset targetPosition;
  double distance;
}

// Code inspired by http://www.kevs3d.co.uk/dev/warpfield/
class SpaceBehaviour extends Behaviour {
  static math.Random random = math.Random();

  @protected
  Offset center;

  @protected
  Offset targetCenter;

  @protected
  List<Star> stars;

  @override
  void init() {
    center = Offset(size.width / 2.0, size.height / 2.0);
    targetCenter = center;
    stars = List<Star>.generate(500, (_) {
      var star = Star();
      _initStar(star);
      return star;
    });
  }

  void _initStar(Star star) {
    star.targetPosition = Offset(
      (random.nextDouble() * size.width - size.width / 2) * 1000.0,
      (random.nextDouble() * size.height - size.height / 2) * 1000.0,
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

    canvas.drawPaint(Paint()..color = Color(0xFF000000));

    canvas.translate(center.dx, center.dy);
    int i = 0;
    double time = DateTime.now().millisecondsSinceEpoch.toDouble() / 1000.0;
    for (Star star in stars) {
      if (star.position.dx == 0 || star.distance <= 0.0) continue;
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
        star.position,
        paint,
      );
      i++;
    }
    canvas.translate(-center.dx, -center.dy);
  }

  @override
  bool tick(double delta, Duration elapsed) {
    center = Offset.lerp(center, targetCenter, delta * 5.0);
    for (Star star in stars) {
      star.position = Offset(
        star.targetPosition.dx / star.distance,
        star.targetPosition.dy / star.distance,
      );
      star.distance -= delta * 500;
      if (star.distance <= 0 ||
          star.position.dx > size.width ||
          star.position.dy > size.height) _initStar(star);
    }
    return true;
  }

  @override
  Widget builder(
      BuildContext context, BoxConstraints constraints, Widget child) {
    return GestureDetector(
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
    RenderBox renderBox = context.findRenderObject();
    var localPosition = renderBox.globalToLocal(globalPosition);
    targetCenter = localPosition;
  }
}
