# Animated_background

[![pub package](https://img.shields.io/pub/v/animated_background.svg)](https://pub.dartlang.org/packages/animated_background)

Animated backgrounds for Flutter.

<p>
    <img src="./screenshots/example_fill.gif?raw=true"/>
    <img src="./screenshots/example_stroke.gif?raw=true"/>
</p>

## How to use


In your pubspec.yaml:
```yaml
dependencies:
  animated_background: ^0.0.2
```

```dart
import 'package:animated_background/animated_background.dart';
```

Use in a Stateful Widget with mixin `TickerProviderStateMixin` or pass a ticker provider in `vsync`

```dart
AnimatedBackground(
  particleOptions: const ParticleOptions(
    baseColor: Colors.blue,
    minOpacity: 0.1,
    maxOpacity: 0.4,
    spawnMinSpeed: 30.0,
    spawnMaxSpeed: 70.0,
    spawnMinRadius: 2.0,
    spawnMaxRadius: 5.0,
  ),
  particlePaint: Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0,
  vsync: this,
  child: Text('Hello'),
);
```
