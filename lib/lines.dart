import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'animated_background.dart';

/// Holds the information of a line used in a [RacingLinesBehaviour].
class Line {
  /// The position of the start of this line.
  Offset? position;

  /// The speed of this line.
  late double speed;

  /// The thickness of this line.
  late int thickness;

  /// The color of this line.
  Color? color;
}

/// The direction in which the lines should move
enum LineDirection {
  /// Left to Right
  Ltr,

  /// Right to Left
  Rtl,

  /// Top to Bottom
  Ttb,

  /// Bottom to Top
  Btt,
}

/// Renders moving lines on an [AnimatedBackground].
class RacingLinesBehaviour extends Behaviour {
  static final math.Random random = math.Random();

  /// Creates a new racing lines behaviour
  RacingLinesBehaviour({this.direction = LineDirection.Ltr, int numLines = 50})
      : assert(numLines >= 0) {
    _numLines = numLines;
  }

  /// The list of lines used by the behaviour to hold the spawned lines.
  @protected
  List<Line>? lines;

  int? _numLines;

  /// Gets the number of lines in the background.
  int? get numLines => _numLines;

  /// Sets the number of lines in the background.
  set numLines(value) {
    if (isInitialized) {
      if (value > lines!.length)
        lines!.addAll(generateLines(value - lines!.length));
      else if (value < lines!.length)
        lines!.removeRange(0, lines!.length - value as int);
    }
    _numLines = value;
  }

  /// The direction in which the lines should move
  ///
  /// Changing this will cause all lines to move in this direction, but no
  /// animation will be performed to change the direction. The lines will
  @protected
  LineDirection direction;

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

    final bool axisHorizontal =
        (direction == LineDirection.Ltr || direction == LineDirection.Rtl);
    final bool normalDirection =
        (direction == LineDirection.Ltr || direction == LineDirection.Ttb);
    final double sizeCrossAxis = axisHorizontal ? size!.height : size!.width;
    final double sizeMainAxis = axisHorizontal ? size!.width : size!.height;
    final double spawnCrossAxis = random.nextInt(100) * (sizeCrossAxis / 100);
    double spawnMainAxis = 0.0;

    if (line.position == null) {
      spawnMainAxis = random.nextDouble() * sizeMainAxis;
    } else {
      spawnMainAxis = normalDirection
          ? (-line.speed / 2.0)
          : (sizeMainAxis + line.speed / 2.0);
    }

    line.position = axisHorizontal
        ? Offset(spawnMainAxis, spawnCrossAxis)
        : Offset(spawnCrossAxis, spawnMainAxis);
    line.thickness = random.nextInt(2) + 2;
    line.color = HSVColor.fromAHSV(
      random.nextDouble() * 0.3 + 0.2,
      random.nextInt(45) * 8.0,
      random.nextDouble() * 0.6 + 0.3,
      random.nextDouble() * 0.6 + 0.3,
    ).toColor();
  }

  @override
  void init() {
    lines = generateLines(numLines!);
  }

  @override
  void initFrom(Behaviour oldBehaviour) {
    if (oldBehaviour is RacingLinesBehaviour) {
      lines = oldBehaviour.lines;
      numLines = this._numLines; // causes the lines to update
    }
  }

  @override
  bool get isInitialized => lines != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    Canvas canvas = context.canvas;
    Paint paint = Paint()..strokeCap = StrokeCap.round;
    final bool axisHorizontal =
        (direction == LineDirection.Ltr || direction == LineDirection.Rtl);
    final int sign =
        (direction == LineDirection.Ltr || direction == LineDirection.Ttb)
            ? 1
            : -1;
    for (var line in lines!) {
      final tailDirection = axisHorizontal
          ? Offset(sign * line.speed / 2.0, 0.0)
          : Offset(0.0, sign * line.speed / 2.0);
      final headDelta =
          axisHorizontal ? Offset(20.0 * sign, 0.0) : Offset(0.0, 20.0 * sign);
      final target = line.position! + tailDirection;
      paint
        ..shader = ui.Gradient.linear(line.position!, target - headDelta,
            <Color>[line.color!.withAlpha(0), line.color!])
        ..strokeWidth = line.thickness.toDouble();
      canvas.drawLine(line.position!, target, paint);
    }
  }

  @override
  bool tick(double delta, Duration elapsed) {
    final bool axisHorizontal =
        (direction == LineDirection.Ltr || direction == LineDirection.Rtl);
    final int sign =
        (direction == LineDirection.Ltr || direction == LineDirection.Ttb)
            ? 1
            : -1;
    if (axisHorizontal) {
      for (var line in lines!) {
        line.position =
            line.position!.translate(delta * line.speed * sign, 0.0);
        if ((direction == LineDirection.Ltr &&
                line.position!.dx > size!.width) ||
            (direction == LineDirection.Rtl && line.position!.dx < 0))
          initLine(line);
      }
    } else {
      for (var line in lines!) {
        line.position =
            line.position!.translate(0.0, delta * line.speed * sign);
        if ((direction == LineDirection.Ttb &&
                line.position!.dy > size!.height) ||
            (direction == LineDirection.Btt && line.position!.dy < 0))
          initLine(line);
      }
    }
    return true;
  }
}
