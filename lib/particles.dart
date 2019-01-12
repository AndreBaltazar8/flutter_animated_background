import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

import 'animated_background.dart';
import 'image_helper.dart';

/// Dummy [Image] that represents a parameter not set. Used by
/// [ParticleOptions.copyWith] to check if the parameter was set or not.
class _NotSetImage extends Image {
  const _NotSetImage() : super(image: const _NotSetImageProvider());
}

/// Dummy [ImageProvider] used by [_NotSetImage].
class _NotSetImageProvider extends ImageProvider<_NotSetImageProvider> {
  const _NotSetImageProvider();
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Holds the particle configuration information for a [ParticleBehaviour].
class ParticleOptions {
  /// The image used by the particle. It is mutually exclusive with [baseColor].
  final Image image;

  /// The color used by the particle. It is mutually exclusive with [image].
  final Color baseColor;

  /// The minimum radius of a spawned particle. Changing this value should cause
  /// the particles to update, in case their current radius is smaller than the
  /// new value. The concrete effects depends on the instance of
  /// [ParticleBehaviour] used.
  final double spawnMinRadius;

  /// The maximum radius of a spawned particle. Changing this value should cause
  /// the particles to update, in case their current radius is bigger than the
  /// new value. The concrete effects depends on the instance of
  /// [ParticleBehaviour] used.
  final double spawnMaxRadius;

  /// The minimum speed of a spawned particle. Changing this value should cause
  /// the particles to update, in case their current speed is smaller than the
  /// new value. The concrete effects depends on the instance of
  /// [ParticleBehaviour] used.
  final double spawnMinSpeed;

  /// The maximum speed of a spawned particle. Changing this value should cause
  /// the particles to update, in case their current speed is bigger than the
  /// new value. The concrete effects depends on the instance of
  /// [ParticleBehaviour] used.
  final double spawnMaxSpeed;

  /// The opacity of a spawned particle.
  final double spawnOpacity;

  /// The minimum opacity of a particle. It is used to compute the target
  /// opacity after spawning. Implementation may differ by [ParticleBehaviour].
  final double minOpacity;

  /// The maximum opacity of a particle. It is used to compute the target
  /// opacity after spawning. Implementation may differ by [ParticleBehaviour].
  final double maxOpacity;

  /// The opacity change rate of a particle over its lifetime.
  final double opacityChangeRate;

  /// The total count of particles that should be spawned.
  final int particleCount;

  /// Creates a [ParticleOptions] given a set of preferred values.
  ///
  /// Default values are assigned for arguments that are omitted.
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

  /// Creates a copy of this [ParticleOptions] but with the given fields
  /// replaced with new values.
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

/// Holds the information of a particle used in a [ParticleBehaviour].
class Particle {
  /// The X coordinate of the center of this particle.
  double cx = 0.0;

  /// The Y coordinate of the center of this particle.
  double cy = 0.0;

  /// The X component of the direction of this particle. This is usually scaled
  /// by the speed of the particle, make it a non-normalized component of direction.
  double dx = 0.0;

  /// The Y component of the direction of this particle This is usually scaled
  /// by the speed of the particle, make it a non-normalized component of direction.
  double dy = 1.0;

  /// The radius of this particle.
  ///
  /// If a [ParticleBehaviour] draws particles with images this value represents
  /// half the width and height of this particle.
  double radius = 0.0;

  /// The current alpha value of this particle.
  double alpha = 0.0;

  /// The target alpha of this particle.
  double targetAlpha = 0.0;

  /// Dynamic data that can be used by [ParticleBehaviour] classes to store
  /// other information related to the particles.
  dynamic data;

  /// Constructs a new [Particle] with its default values.
  Particle();

  /// Gets the square of the speed of this particle.
  double get speedSqr => dx * dx + dy * dy;

  /// Sets the square of the speed of this particle.
  ///
  /// If a negative value is provided the direction is flipped and the absolute
  /// value is used to calculate the square root.
  set speedSqr(double value) {
    speed = math.sqrt(value.abs()) * value.sign;
  }

  /// Gets the speed of this particle.
  double get speed => math.sqrt(speedSqr);

  /// Sets the speed of this particle.
  ///
  /// In case the value is 0, the Y component of the direction will be set to 1
  /// making the speed of the particle 1, instead of 0. The logic behind this
  /// implementation is as follows: The [ParticleBahaviour] needs to the
  /// smallest amount of work for each particle as possible. If a speed field
  /// was provided to specify the velocity of the particle, it would require the
  /// 2 additional multiplications (one for each component of direction) when
  /// updating a particle.
  set speed(double value) {
    double mag = speed;
    if (mag == 0) {
      // TODO: maybe find a better solution for this case
      dx = 0.0;
      dy = value;
    } else {
      dx = dx / mag * value;
      dy = dy / mag * value;
    }
  }
}

/// The base for behaviours that render particles on an [AnimatedBackground].
abstract class ParticleBehaviour extends Behaviour {
  /// The list of particles used by the particle behaviour to hold the spawned particles.
  @protected
  List<Particle> particles;

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

    if (_paint.strokeWidth <= 0) _paint.strokeWidth = 1.0;
  }

  ParticleOptions _options;

  /// Gets the particle options used to configure this behaviour.
  ParticleOptions get options => _options;

  /// Set the particle options used to configure this behaviour.
  ///
  /// Changing this value will cause the currently spawned particles to update.
  set options(ParticleOptions value) {
    assert(value != null);
    if (value == _options) return;
    ParticleOptions oldOptions = _options;
    _options = value;

    if (_options.image == null)
      _particleImage = null;
    else if (_particleImage == null || oldOptions.image != _options.image)
      _convertImage(_options.image);

    onOptionsUpdate(oldOptions);
  }

  /// Creates a new particle behaviour.
  ///
  /// Default values will be assigned to the parameters if not specified.
  ParticleBehaviour({
    ParticleOptions options = const ParticleOptions(),
    Paint paint,
  }) : assert(options != null) {
    _options = options;
    this.particlePaint = paint;
    if (options.image != null) _convertImage(options.image);
  }

  @override
  void init() {
    particles = generateParticles(options.particleCount);
  }

  @override
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
    if (particles == null) return false;

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
      if (particle.alpha == 0.0) continue;
      _paint.color = options.baseColor.withOpacity(particle.alpha);

      if (_particleImage != null) {
        Rect dst = Rect.fromLTRB(
          particle.cx - particle.radius,
          particle.cy - particle.radius,
          particle.cx + particle.radius,
          particle.cy + particle.radius,
        );
        canvas.drawImageRect(_particleImage, _particleImageSrc, dst, _paint);
      } else
        canvas.drawCircle(
          Offset(particle.cx, particle.cy),
          particle.radius,
          _paint,
        );
    }
  }

  /// Generates an amount of particles and initializes them.
  ///
  /// This can be used to generate the initial particles or new particles when
  /// the options change
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
    if (options.opacityChangeRate > 0 &&
            particle.alpha < particle.targetAlpha ||
        options.opacityChangeRate < 0 &&
            particle.alpha > particle.targetAlpha) {
      particle.alpha = particle.alpha + delta * options.opacityChangeRate;

      if (options.opacityChangeRate > 0 &&
              particle.alpha > particle.targetAlpha ||
          options.opacityChangeRate < 0 &&
              particle.alpha < particle.targetAlpha)
        particle.alpha = particle.targetAlpha;
    }
  }

  @protected
  @mustCallSuper
  void onOptionsUpdate(ParticleOptions oldOptions) {
    if (particles == null)
      return;
    if (particles.length > options.particleCount)
      particles.removeRange(0, particles.length - options.particleCount);
    else if (particles.length < options.particleCount) {
      final int particlesToSpawn = options.particleCount - particles.length;
      final newParticles = generateParticles(particlesToSpawn);
      particles.addAll(newParticles);
    }
  }

  void _convertImage(Image image) async {
    if (_pendingConversion != null) _pendingConversion();
    _pendingConversion = convertImage(image, (ui.Image outImage) {
      _pendingConversion = null;
      if (outImage != null)
        _particleImageSrc = Rect.fromLTRB(
          0.0,
          0.0,
          outImage.width.toDouble(),
          outImage.height.toDouble(),
        );
      _particleImage = outImage;
    });
  }
}

/// Renders particles that move in a predetermined direction on the [AnimatedBackground].
class RandomParticleBehaviour extends ParticleBehaviour {
  static math.Random random = math.Random();

  /// Creates a new random particle behaviour.
  RandomParticleBehaviour({
    ParticleOptions options = const ParticleOptions(),
    Paint paint,
  }) : super(options: options, paint: paint);

  @override
  void initFrom(Behaviour oldBehaviour) {
    super.initFrom(oldBehaviour);
    if (oldBehaviour is RandomParticleBehaviour || particles == null) return;
    for (Particle particle in particles) {
      initParticle(particle);
    }
  }

  @override
  void initParticle(Particle p) {
    initPosition(p);
    initRadius(p);

    final double deltaSpeed = (options.spawnMaxSpeed - options.spawnMinSpeed);
    double speed = random.nextDouble() * deltaSpeed + options.spawnMinSpeed;
    initDirection(p, speed);

    final double deltaOpacity = (options.maxOpacity - options.minOpacity);
    p.alpha = options.spawnOpacity;
    p.targetAlpha = random.nextDouble() * deltaOpacity + options.minOpacity;
  }

  /// Initializes a new position for the provided [Particle].
  @protected
  void initPosition(Particle p) {
    p.cx = random.nextDouble() * size.width;
    p.cy = random.nextDouble() * size.height;
  }

  /// Initializes a new radius for the provided [Particle].
  @protected
  void initRadius(Particle p) {
    final deltaRadius = (options.spawnMaxRadius - options.spawnMinRadius);
    p.radius = random.nextDouble() * deltaRadius + options.spawnMinRadius;
  }

  /// Initializes a new direction for the provided [Particle].
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
    if (particles == null)
      return;
    for (Particle p in particles) {
      // speed assignment is better done this way, to prevent calculation of square roots if not needed
      double speedSqr = p.speedSqr;
      if (speedSqr > maxSpeedSqr)
        p.speed = options.spawnMaxSpeed;
      else if (speedSqr < minSpeedSqr) p.speed = options.spawnMinSpeed;

      // TODO: handle opacity change

      if (p.radius < options.spawnMinRadius ||
          p.radius > options.spawnMaxRadius) initRadius(p);
    }
  }
}
