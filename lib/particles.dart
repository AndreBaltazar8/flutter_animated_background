import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui' as ui;

import 'animated_background.dart';

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

abstract class ParticleBehaviour {
  @protected
  List<Particle> particles;

  RenderAnimatedBackground renderObject;
  @protected
  Size get size => renderObject?.size;
  @protected
  ParticleOptions get options => renderObject?.particleOptions;

  ParticleBehaviour();

  @protected
  void initBehaviour() {
    particles = generateParticles(options.particleCount);
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
  void onParticleOptionsUpdate(ParticleOptions oldOptions) {
    if (particles.length > options.particleCount)
      particles.removeRange(0, particles.length - options.particleCount);
    else if (particles.length < options.particleCount)
      particles.addAll(generateParticles(options.particleCount - particles.length));
  }

  @protected
  @mustCallSuper
  void onParticleBehaviorUpdate(ParticleBehaviour oldBehaviour) {
    particles = oldBehaviour.particles;
  }

  @protected
  @mustCallSuper
  Widget builder(BuildContext context, BoxConstraints constraints, Widget child) {
    return child;
  }

  @protected
  @mustCallSuper
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
}

class RandomMovementBehavior extends ParticleBehaviour {
  static math.Random random = math.Random();

  RandomMovementBehavior();

  @override
  void initParticle(Particle p) {
    p.cx = random.nextDouble() * size.width;
    p.cy = random.nextDouble() * size.height;
    newRadius(p);

    double speed = random.nextDouble() * (options.spawnMaxSpeed - options.spawnMinSpeed) + options.spawnMinSpeed;
    newDirection(p, speed);

    p.alpha = options.spawnOpacity;
    p.targetAlpha = random.nextDouble() * (options.maxOpacity - options.minOpacity) + options.minOpacity;
  }

  @protected
  void newRadius(Particle p) {
    p.radius = random.nextDouble() * (options.spawnMaxRadius - options.spawnMinRadius) + options.spawnMinRadius;
  }

  @protected
  void newDirection(Particle p, double speed) {
    double dirX = random.nextDouble() - 0.5;
    double dirY = random.nextDouble() - 0.5;
    double magSq = dirX * dirX + dirY * dirY;
    double mag = magSq <= 0 ? 1 : math.sqrt(magSq);

    p.dx = dirX / mag * speed;
    p.dy = dirY / mag * speed;
  }

  @override
  void onParticleOptionsUpdate(ParticleOptions oldOptions) {
    super.onParticleOptionsUpdate(oldOptions);
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
        newRadius(p);
    }
  }

  @override
  void onParticleBehaviorUpdate(ParticleBehaviour oldBehaviour) {
    super.onParticleBehaviorUpdate(oldBehaviour);
    if (oldBehaviour is RandomMovementBehavior)
      return;
    for (Particle particle in particles)
      initParticle(particle);
  }
}
