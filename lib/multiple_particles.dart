import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:animated_background/animated_background.dart';
import 'package:animated_background/image_helper.dart';
import 'package:flutter/material.dart';

class RainMultipleImagesParticleBehaviour
    extends RandomMultipleImagesParticleBehavior {
  static final math.Random random = math.Random();

  bool enabled;

  RainMultipleImagesParticleBehaviour({
    MultipleImagesPartialOptions options = const MultipleImagesPartialOptions(
      images: [],
    ),
    Paint? paint,
    this.enabled = true,
  }) : super(options: options, paint: paint);

  @override
  void initPosition(Particle p) {
    p.cx = random.nextDouble() * size.width;
    if (p.cy == 0.0) {
      p.cy = random.nextDouble() * size.height;
    } else {
      p.cy = random.nextDouble() * size.width * 0.2;
    }
  }

  @override
  void initDirection(Particle p, double speed) {
    final double dirX = random.nextDouble() - 0.5;
    final double dirY = random.nextDouble() * 0.5 + 0.5;
    final double magSq = dirX * dirX + dirY * dirY;
    final double mag = magSq <= 0 ? 1 : math.sqrt(magSq);

    p.dx = dirX / mag * speed;
    p.dy = dirY / mag * speed;
  }

  @override
  Widget builder(
      BuildContext context, BoxConstraints constraints, Widget child) {
    return GestureDetector(
      onPanUpdate: enabled
          ? (details) => _updateParticles(context, details.globalPosition)
          : null,
      onTapDown: enabled
          ? (details) => _updateParticles(context, details.globalPosition)
          : null,
      child: ConstrainedBox(
        // necessary to force gesture detector to cover screen
        constraints: const BoxConstraints(
            minHeight: double.infinity, minWidth: double.infinity),
        child: super.builder(context, constraints, child),
      ),
    );
  }

  void _updateParticles(BuildContext context, Offset offsetGlobal) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.globalToLocal(offsetGlobal);
    for (final particle in particles ?? <Particle>[]) {
      final delta = Offset(particle.cx, particle.cy) - offset;
      if (delta.distanceSquared < 70 * 70) {
        var speed = particle.speed;
        final mag = delta.distance;
        speed *= (70 - mag) / 70.0 * 2.0 + 0.5;
        speed = math.max(
            options.spawnMinSpeed, math.min(options.spawnMaxSpeed, speed));
        particle.dx = delta.dx / mag * speed;
        particle.dy = delta.dy / mag * speed;
      }
    }
  }
}

class RandomMultipleImagesParticleBehavior
    extends MultipleImagesParticleBehavior {
  static math.Random random = math.Random();

  /// Creates a new random particle behaviour.
  RandomMultipleImagesParticleBehavior({
    MultipleImagesPartialOptions options = const MultipleImagesPartialOptions(
      images: [],
    ),
    Paint? paint,
  }) : super(options: options, paint: paint);

  @override
  void initFrom(Behaviour oldBehaviour) {
    super.initFrom(oldBehaviour);
    if (oldBehaviour is RandomParticleBehaviour || particles == null) return;
    for (Particle particle in particles ?? []) {
      initParticle(particle);
    }
  }

  @override
  void initParticle(Particle p) {
    super.initParticle(p);
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
  void onOptionsUpdate(MultipleImagesPartialOptions? oldOptions) {
    super.onOptionsUpdate(oldOptions);
    double minSpeedSqr = options.spawnMinSpeed * options.spawnMinSpeed;
    double maxSpeedSqr = options.spawnMaxSpeed * options.spawnMaxSpeed;
    if (particles == null) return;
    for (Particle p in particles ?? []) {
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

abstract class MultipleImagesParticleBehavior extends Behaviour {
  /// The list of particles used by the particle behaviour to hold the spawned particles.
  @protected
  List<Particle>? particles;
  Map<Particle, ui.Image> _particlesImagesMapper = {};

  @override
  bool get isInitialized => particles != null;

  Map<ui.Image, Rect?> _particleImageSrcs = {};
  Function? _pendingConversion;

  Paint? _paint;

  Paint? get particlePaint => _paint;

  set particlePaint(Paint? value) {
    if (value == null) {
      _paint = Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.fill
        ..strokeWidth = 1.0;
    } else {
      _paint = value;
    }

    if (_paint!.strokeWidth <= 0) _paint!.strokeWidth = 1.0;
  }

  MultipleImagesPartialOptions? _options;

  /// Gets the particle options used to configure this behaviour.
  MultipleImagesPartialOptions get options => _options!;

  /// Set the particle options used to configure this behaviour.
  ///
  /// Changing this value will cause the currently spawned particles to update.
  set options(MultipleImagesPartialOptions value) {
    if (value == _options) return;
    MultipleImagesPartialOptions? oldOptions = _options;
    _options = value;

    // if (_options!.image == null) {
    //   _particleImage = null;
    // } else if (_particleImage == null ||
    //     oldOptions!.images != _options!.images) {
    //   _convertImage(_options!.image!);
    // }

    if (_particleImageSrcs.isEmpty || oldOptions?.images != options.images) {
      _convertImages(options.images);
    }

    onOptionsUpdate(oldOptions);
  }

  /// Creates a new particle behaviour.
  ///
  /// Default values will be assigned to the parameters if not specified.
  MultipleImagesParticleBehavior({
    MultipleImagesPartialOptions options = const MultipleImagesPartialOptions(
      images: [],
    ),
    Paint? paint,
  }) {
    _options = options;
    particlePaint = paint;
    if (options.images.isNotEmpty) _convertImages(options.images);
  }

  @override
  void init() {
    particles = generateParticles(options.particleCount);
  }

  @override
  void initFrom(Behaviour oldBehaviour) {
    if (oldBehaviour is MultipleImagesParticleBehavior) {
      particles = oldBehaviour.particles;

      // keep old image if waiting for a new one
      if (options.images.isNotEmpty && _particleImageSrcs.isEmpty) {
        _particleImageSrcs = oldBehaviour._particleImageSrcs;
      }

      onOptionsUpdate(oldBehaviour.options);
    }
  }

  @override
  bool tick(double delta, Duration elapsed) {
    if (particles == null) return false;

    for (Particle particle in particles!) {
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
    for (Particle particle in particles!) {
      if (particle.alpha == 0.0) continue;
      _paint!.color = options.baseColor.withOpacity(particle.alpha);
      if (_particleImageSrcs.isNotEmpty) {
        final image = _particlesImagesMapper[particle];
        final source = _particleImageSrcs[image];
        if (source != null && image != null) {
          Rect dst = Rect.fromLTRB(
            particle.cx - particle.radius,
            particle.cy - particle.radius,
            particle.cx + particle.radius,
            particle.cy + particle.radius,
          );
          canvas.drawImageRect(
            image,
            source,
            dst,
            _paint!,
          );
        }
      } else {
        canvas.drawCircle(
          Offset(particle.cx, particle.cy),
          particle.radius,
          _paint!,
        );
      }
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
  @mustCallSuper
  void initParticle(Particle particle) {
    if (_particleImageSrcs.isNotEmpty) {
      _particlesImagesMapper[particle] = _particleImageSrcs.keys
          .elementAt(math.Random().nextInt(_particleImageSrcs.length));
    }
  }

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
              particle.alpha < particle.targetAlpha) {
        particle.alpha = particle.targetAlpha;
      }
    }
  }

  @protected
  @mustCallSuper
  void onOptionsUpdate(MultipleImagesPartialOptions? oldOptions) {
    if (particles == null) return;
    if (particles!.length > options.particleCount) {
      particles!.removeRange(0, particles!.length - options.particleCount);
    } else if (particles!.length < options.particleCount) {
      final int particlesToSpawn = options.particleCount - particles!.length;
      final newParticles = generateParticles(particlesToSpawn);
      particles!.addAll(newParticles);
    }
  }

  void _convertImages(List<Image> images) async {
    for (final image in images
        .where((element) => !_particleImageSrcs.containsKey(element))) {
      _pendingConversion?.call();
      _pendingConversion = convertImage(image, (ui.Image outImage) {
        _pendingConversion = null;
        _particleImageSrcs[outImage] = (Rect.fromLTRB(
          0.0,
          0.0,
          outImage.width.toDouble(),
          outImage.height.toDouble(),
        ));
        if (_particleImageSrcs.length < images.length) {
          _convertImages(images);
        }
      });
    }
  }
}

class MultipleImagesPartialOptions {
  final List<Image> images;

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
  const MultipleImagesPartialOptions({
    required this.images,
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
  });
}
