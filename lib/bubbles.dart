import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'animated_background.dart';

/// Holds the information of a bubble used in a [BubblesBehaviour].
class Bubble {
  /// The position of this bubble.
  Offset position;

  /// The radius of this bubble.
  double radius;

  /// The target radius of this bubble.
  double targetRadius;

  /// The color of this bubble.
  Color color;

  /// The state of the bubble. Is it popping?
  bool popping;
}

/// Renders bubbles on an [AnimatedBackground].
class BubblesBehaviour extends Behaviour {
  static math.Random random = math.Random();
  List<Bubble> _bubbles;
  static const int numBubbles = 20;
  static const double minTargetRadius = 10.0;
  static const double maxTargetRadius = 50.0;
  static const double deltaTargetRadius = maxTargetRadius - minTargetRadius;
  static const double growthRate = 10.0;
  static const double sqrtInverse = 0.707;

  @override
  void init() {
    _bubbles = List<Bubble>.generate(numBubbles, (_) {
      Bubble bubble = Bubble();
      _initBubble(bubble);
      return bubble;
    });
  }

  void _initBubble(Bubble bubble) {
    bubble.position = Offset(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
    );

    bubble.targetRadius =
        random.nextDouble() * deltaTargetRadius + minTargetRadius;

    if (bubble.radius == null) {
      bubble.radius = random.nextDouble() * bubble.targetRadius;
    } else {
      bubble.radius = 0.0;
    }

    bubble.color = HSVColor
        .fromAHSV(
          random.nextDouble() * 0.3 + 0.2,
          random.nextInt(45) * 8.0,
          random.nextDouble() * 0.6 + 0.3,
          random.nextDouble() * 0.6 + 0.3,
        )
        .toColor();
    bubble.popping = false;
  }

  void _popBubble(Bubble bubble) {
    bubble.popping = true;
    bubble.radius = 0.2 * bubble.targetRadius;
    bubble.targetRadius *= 0.5;
  }

  @override
  void initFrom(Behaviour oldBehaviour) {
    if (oldBehaviour is BubblesBehaviour) {
      _bubbles = oldBehaviour._bubbles;
    }
  }

  @override
  bool get isInitialized => _bubbles != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    Paint paint = Paint()
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    for (var bubble in _bubbles) {
      paint.color = bubble.color;
      if (!bubble.popping) {
        canvas.drawCircle(bubble.position, bubble.radius, paint);
      } else {
        final double radiusSqrt = bubble.radius * sqrtInverse;
        final double targetRadiusSqrt = bubble.targetRadius * sqrtInverse;
        canvas.drawLine(
          bubble.position + Offset(radiusSqrt, radiusSqrt),
          bubble.position + Offset(targetRadiusSqrt, targetRadiusSqrt),
          paint,
        );
        canvas.drawLine(
          bubble.position + Offset(radiusSqrt, -radiusSqrt),
          bubble.position + Offset(targetRadiusSqrt, -targetRadiusSqrt),
          paint,
        );
        canvas.drawLine(
          bubble.position + Offset(-radiusSqrt, radiusSqrt),
          bubble.position + Offset(-targetRadiusSqrt, targetRadiusSqrt),
          paint,
        );
        canvas.drawLine(
          bubble.position + Offset(-radiusSqrt, -radiusSqrt),
          bubble.position + Offset(-targetRadiusSqrt, -targetRadiusSqrt),
          paint,
        );
        canvas.drawLine(bubble.position + Offset(0.0, bubble.radius),
            bubble.position + Offset(0.0, bubble.targetRadius), paint);
        canvas.drawLine(bubble.position + Offset(0.0, -bubble.radius),
            bubble.position + Offset(0.0, -bubble.targetRadius), paint);
        canvas.drawLine(bubble.position + Offset(bubble.radius, 0.0),
            bubble.position + Offset(bubble.targetRadius, 0.0), paint);
        canvas.drawLine(bubble.position + Offset(-bubble.radius, 0.0),
            bubble.position + Offset(-bubble.targetRadius, 0.0), paint);
      }
    }
  }

  @override
  bool tick(double delta, Duration elapsed) {
    if (!isInitialized) return false;
    for (var bubble in _bubbles) {
      bubble.radius += growthRate * delta * (bubble.popping ? 15 : 1);

      if (bubble.radius >= bubble.targetRadius) {
        if (bubble.popping)
          _initBubble(bubble);
        else
          _popBubble(bubble);
      }
    }
    return true;
  }

  @override
  Widget builder(
      BuildContext context, BoxConstraints constraints, Widget child) {
    return GestureDetector(
      onTapDown: (details) => _onTap(context, details.globalPosition),
      child: ConstrainedBox(
        // necessary to force gesture detector to cover screen
        constraints: BoxConstraints(
            minHeight: double.infinity, minWidth: double.infinity),
        child: super.builder(context, constraints, child),
      ),
    );
  }

  void _onTap(BuildContext context, Offset globalPosition) {
    RenderBox renderBox = context.findRenderObject();
    var localPosition = renderBox.globalToLocal(globalPosition);
    for (var bubble in _bubbles) {
      if ((bubble.position - localPosition).distanceSquared <
          bubble.radius * bubble.radius * 1.2) {
        _popBubble(bubble);
      }
    }
  }
}
