import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

import 'animated_background.dart';
import 'image_helper.dart';

// We need these classes to use in copyWith, because there is no way to check if
// the argument is set or not using an operator
class _NotSetImageProvider extends ImageProvider<_NotSetImageProvider> {
  const _NotSetImageProvider();
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NotSetImage extends Image {
  const _NotSetImage() : super(image: const _NotSetImageProvider());
}

class ParticleOptions {
  final Image image;
  final Color baseColor;
  final double spawnMinRadius;
  final double spawnMaxRadius;
  final double spawnMinSpeed;
  final double spawnMaxSpeed;
  final double spawnOpacity;
  final double minOpacity;
  final double maxOpacity;
  final double opacityChangeRate;
  final int particleCount;

  const ParticleOptions({
    this.image,
    this.baseColor = Colors.black,
    this.spawnMinRadius = 1.0,
    this.spawnMaxRadius = 10.0,
    this.spawnMinSpeed = 150.0,
    this.spawnMaxSpeed = 300.0,
    this.spawnOpacity = 0.0,
    this.minOpacity = 0.1,
    this.maxOpacity = 0.4,
    this.opacityChangeRate = 0.25,
    this.particleCount = 100,
  })  : assert(baseColor != null),
        assert(spawnMinRadius != null),
        assert(spawnMaxRadius != null),
        assert(spawnMinSpeed != null),
        assert(spawnMaxSpeed != null),
        assert(spawnOpacity != null),
        assert(minOpacity != null),
        assert(maxOpacity != null),
        assert(opacityChangeRate != null),
        assert(particleCount != null),
        assert(spawnMaxRadius >= spawnMinRadius),
        assert(spawnMinRadius >= 1.0),
        assert(spawnMaxRadius >= 1.0),
        assert(spawnOpacity >= 0.0),
        assert(spawnOpacity <= 1.0),
        assert(maxOpacity >= minOpacity),
        assert(minOpacity >= 0.0),
        assert(minOpacity <= 1.0),
        assert(maxOpacity >= 0.0),
        assert(maxOpacity <= 1.0),
        assert(spawnMaxSpeed >= spawnMinSpeed),
        assert(spawnMinSpeed >= 0.0),
        assert(spawnMaxSpeed >= 0.0),
        assert(particleCount >= 0);

  ParticleOptions copyWith({
    Image image = const _NotSetImage(),
    Color baseColor,
    double spawnMinRadius,
    double spawnMaxRadius,
    double spawnMinSpeed,
    double spawnMaxSpeed,
    double spawnOpacity,
    double minOpacity,
    double maxOpacity,
    double opacityChangeRate,
    int particleCount,
  }) {
    return ParticleOptions(
      image: image is _NotSetImage ? this.image : image,
      baseColor: baseColor ?? this.baseColor,
      spawnMinRadius: spawnMinRadius ?? this.spawnMinRadius,
      spawnMaxRadius: spawnMaxRadius ?? this.spawnMaxRadius,
      spawnMinSpeed: spawnMinSpeed ?? this.spawnMinSpeed,
      spawnMaxSpeed: spawnMaxSpeed ?? this.spawnMaxSpeed,
      spawnOpacity: spawnOpacity ?? this.spawnOpacity,
      minOpacity: minOpacity ?? this.minOpacity,
      maxOpacity: maxOpacity ?? this.maxOpacity,
      opacityChangeRate: opacityChangeRate ?? this.opacityChangeRate,
      particleCount: particleCount ?? this.particleCount,
    );
  }
}

class Particle {
  double cx = 0.0;
  double cy = 0.0;
  double dx = 0.0;
  double dy = 1.0;
  double radius = 0.0;
  double alpha = 0.0;
  double targetAlpha = 0.0;
  dynamic data;

  Particle();

  double get speedSqr => dx * dx + dy * dy;
  set speedSqr (double value) {
    speed = math.sqrt(value.abs()) * value.sign;
  }

  double get speed => math.sqrt(speedSqr);
  set speed (double value) {
    double mag = speed;
    if (mag == 0) { // TODO: maybe find a better solution for this case
      dx = 0.0;
      dy = value;
    } else {
      dx = dx / mag * value;
      dy = dy / mag * value;
    }
  }
}

abstract class ParticleBehaviour extends Behaviour {
  @protected
  List<Particle> particles;

  @protected
  ParticleOptions get options => _particleOptions;

  @override
  bool get isInitialized => particles != null;

  Rect _particleImageSrc;
  ui.Image _particleImage;
  Function _pendingConversion;

  Paint _paint;
  Paint get particlePaint => _paint;
  set particlePaint(Paint value) {
    if (value == null) {
      _paint = Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.fill
        ..strokeWidth = 1.0;
    } else {
      _paint = value;
    }

    if (_paint.strokeWidth <= 0)
      _paint.strokeWidth = 1.0;
  }

  ParticleOptions _particleOptions;
  ParticleOptions get particleOptions => _particleOptions;
  set particleOptions(ParticleOptions value) {
    assert(value != null);
    if (value == _particleOptions)
      return;
    ParticleOptions oldOptions = _particleOptions;
    _particleOptions = value;

    if (_particleOptions.image == null)
      _particleImage = null;
    else if (_particleImage == null || oldOptions.image != _particleOptions.image)
      _convertImage(_particleOptions.image);

    onOptionsUpdate(oldOptions);
  }

  ParticleBehaviour({
    ParticleOptions options = const ParticleOptions(),
    Paint paint,
  }) : assert(options != null) {
    _particleOptions = options;
    this.particlePaint = paint;
    if (options.image != null)
      _convertImage(options.image);
  }

  @override
  void init() {
    particles = generateParticles(options.particleCount);
  }

  @protected
  void initFrom(Behaviour oldBehaviour) {
    if (oldBehaviour is ParticleBehaviour) {
      particles = oldBehaviour.particles;

      // keep old image if waiting for a new one
      if (options.image != null && _particleImage == null) {
        _particleImage = oldBehaviour._particleImage;
        _particleImageSrc = oldBehaviour._particleImageSrc;
      }

      onOptionsUpdate(oldBehaviour.options);
    }
  }

  @override
  bool tick(double delta, Duration elapsed) {
    if (particles == null)
      return false;

    for (Particle particle in particles) {
      if (!size.contains(Offset(particle.cx, particle.cy))) {
        initParticle(particle);
        continue;
      }

      updateParticle(particle, delta, elapsed);
    }

    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    for (Particle particle in particles) {
      if (particle.alpha == 0.0)
        continue;
      _paint.color = options.baseColor.withOpacity(particle.alpha);

      if (_particleImage != null) {
        Rect dst = Rect.fromLTRB(particle.cx - particle.radius, particle.cy - particle.radius, particle.cx + particle.radius, particle.cy + particle.radius);
        canvas.drawImageRect(_particleImage, _particleImageSrc, dst, _paint);
      } else
        canvas.drawCircle(Offset(particle.cx, particle.cy), particle.radius, _paint);
    }
  }

  @protected
  List<Particle> generateParticles(int numParticles) {
    return List.generate(numParticles, (i) => i).map((i) {
      Particle p = Particle();
      initParticle(p);
      return p;
    }).toList();
  }

  @protected
  void initParticle(Particle particle);

  @protected
  void updateParticle(Particle particle, double delta, Duration elapsed) {
    particle.cx += particle.dx * delta;
    particle.cy += particle.dy * delta;
    if (options.opacityChangeRate > 0 && particle.alpha < particle.targetAlpha ||
        options.opacityChangeRate < 0 && particle.alpha > particle.targetAlpha) {
      particle.alpha = particle.alpha + delta * options.opacityChangeRate;

      if (options.opacityChangeRate > 0 && particle.alpha > particle.targetAlpha ||
          options.opacityChangeRate < 0 && particle.alpha < particle.targetAlpha)
        particle.alpha = particle.targetAlpha;
    }
  }

  @protected
  @mustCallSuper
  void onOptionsUpdate(ParticleOptions oldOptions) {
    if (particles.length > options.particleCount)
      particles.removeRange(0, particles.length - options.particleCount);
    else if (particles.length < options.particleCount)
      particles.addAll(generateParticles(options.particleCount - particles.length));
  }

  void _convertImage(Image image) async {
    if (_pendingConversion != null)
      _pendingConversion();
    _pendingConversion = convertImage(image, (ui.Image outImage) {
      _pendingConversion = null;
      if (outImage != null)
        _particleImageSrc = Rect.fromLTRB(0.0, 0.0, outImage.width.toDouble(), outImage.height.toDouble());
      _particleImage = outImage;
    });
  }
}

class RandomParticleBehaviour extends ParticleBehaviour {
  static math.Random random = math.Random();

  RandomParticleBehaviour({
    ParticleOptions options = const ParticleOptions(),
    Paint paint,
  }) : super(options: options, paint: paint);

  @override
  void initFrom(Behaviour oldBehaviour) {
    super.initFrom(oldBehaviour);
    if (oldBehaviour is RandomParticleBehaviour || particles == null)
      return;
    for (Particle particle in particles)
      initParticle(particle);
  }

  @override
  void initParticle(Particle p) {
    initPosition(p);
    initRadius(p);

    double speed = random.nextDouble() * (options.spawnMaxSpeed - options.spawnMinSpeed) + options.spawnMinSpeed;
    initDirection(p, speed);

    p.alpha = options.spawnOpacity;
    p.targetAlpha = random.nextDouble() * (options.maxOpacity - options.minOpacity) + options.minOpacity;
  }

  @protected
  void initPosition(Particle p) {
    p.cx = random.nextDouble() * size.width;
    p.cy = random.nextDouble() * size.height;
  }

  @protected
  void initRadius(Particle p) {
    p.radius = random.nextDouble() * (options.spawnMaxRadius - options.spawnMinRadius) + options.spawnMinRadius;
  }

  @protected
  void initDirection(Particle p, double speed) {
    double dirX = random.nextDouble() - 0.5;
    double dirY = random.nextDouble() - 0.5;
    double magSq = dirX * dirX + dirY * dirY;
    double mag = magSq <= 0 ? 1 : math.sqrt(magSq);

    p.dx = dirX / mag * speed;
    p.dy = dirY / mag * speed;
  }

  @override
  void onOptionsUpdate(ParticleOptions oldOptions) {
    super.onOptionsUpdate(oldOptions);
    double minSpeedSqr = options.spawnMinSpeed * options.spawnMinSpeed;
    double maxSpeedSqr = options.spawnMaxSpeed * options.spawnMaxSpeed;
    for (Particle p in particles) {
      // speed assignment is better done this way, to prevent calculation of square roots if not needed
      double speedSqr = p.speedSqr;
      if (speedSqr > maxSpeedSqr)
        p.speed = options.spawnMaxSpeed;
      else if (speedSqr < minSpeedSqr)
        p.speed = options.spawnMinSpeed;

      // TODO: handle opacity change

      if (p.radius < options.spawnMinRadius || p.radius > options.spawnMaxRadius)
        initRadius(p);
    }
  }
}
