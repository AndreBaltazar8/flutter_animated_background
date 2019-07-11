# Animated Backgrounds for Flutter

[![pub package](https://img.shields.io/pub/v/animated_background.svg)](https://pub.dev/packages/animated_background)

Animated Backgrounds for Flutter. Easily extended to paint whatever you want on the canvas.

![Screenshot](https://raw.githubusercontent.com/AndreBaltazar8/flutter_animated_background/master/screenshots/example_fill.gif)
![Screenshot](https://raw.githubusercontent.com/AndreBaltazar8/flutter_animated_background/master/screenshots/example_star.gif)

Note: These examples are laggy because they were recorded from the emulator. Other examples available in the [screenshots](https://github.com/AndreBaltazar8/flutter_animated_background/tree/master/screenshots) folder.

## How to use

In your pubspec.yaml:
```yaml
dependencies:
  animated_background: ^1.0.5
```

In your Dart file:
```dart
import 'package:animated_background/animated_background.dart';
```

Use in a Stateful Widget with mixin `TickerProviderStateMixin` or pass a ticker provider in `vsync`.

```dart
AnimatedBackground(
  behaviour: RandomParticleBehaviour(),
  vsync: this,
  child: Text('Hello'),
);
```
