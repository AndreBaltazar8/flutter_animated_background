import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'animated_background.dart';

/// Holds the information of a line used in a [RacingLinesBehaviour].
class Line {
  /// The position of the start of this line.
  Offset position;

  /// The speed of this line.
  double speed;

  /// The thickness of this line.
  int thickness;

  /// The color of this line.
  Color color;
}

/// Renders moving lines on an [AnimatedBackground].
class RacingLinesBehaviour extends Behaviour {
  static final math.Random random = math.Random();

  /// The list of particles used by the particle behaviour to hold the spawned particles.
  @protected
  List<Line> lines;

  /// Generates an amount of lines and initializes them.
  @protected
  List<Line> generateLines(int numLines) => List<Line>.generate(numLines, (i) {
        final Line line = Line();
        initLine(line);
        return line;
      });

  /// Initializes a line for this behaviour.
  @protected
  void initLine(Line line) {
    line.speed = random.nextDouble() * 400 + 200;

    double y = random.nextInt(100) * (size.height / 100);
    if (line.position == null)
      line.position = Offset(random.nextDouble() * size.width, y);
    else
      line.position = Offset(-line.speed / 2.0, y);
    line.thickness = random.nextInt(2) + 2;
    line.color = HSVColor
        .fromAHSV(
          random.nextDouble() * 0.3 + 0.2,
          random.nextInt(45) * 8.0,
          random.nextDouble() * 0.6 + 0.3,
          random.nextDouble() * 0.6 + 0.3,
        )
        .toColor();
  }

  @override
  void init() {
    lines = generateLines(50);
  }

  @override
  void initFrom(Behaviour oldBehaviour) {
    if (oldBehaviour is RacingLinesBehaviour) {
      lines = oldBehaviour.lines;
    }
  }

  @override
  bool get isInitialized => lines != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    Canvas canvas = context.canvas;
    Paint paint = Paint()..strokeCap = StrokeCap.round;
    for (var line in lines) {
      final target = line.position + Offset(line.speed / 2.0, 0.0);
      paint
        ..shader = ui.Gradient.linear(line.position, target - Offset(20.0, 0.0),
            <Color>[line.color.withAlpha(0), line.color])
        ..strokeWidth = line.thickness.toDouble();
      canvas.drawLine(line.position, target, paint);
    }
  }

  @override
  bool tick(double delta, Duration elapsed) {
    for (var line in lines) {
      line.position = line.position.translate(delta * line.speed, 0.0);
      if (line.position.dx > size.width) initLine(line);
    }
    return true;
  }
}
