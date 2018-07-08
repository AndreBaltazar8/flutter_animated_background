library animated_background;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

class AnimatedBackground extends SingleChildRenderObjectWidget {
  final TickerProvider vsync;
  final ParticleOptions particleOptions;
  final Paint particlePaint;

  AnimatedBackground({
    @required Widget child,
    @required this.vsync,
    this.particleOptions = const ParticleOptions(),
    this.particlePaint,
  })  : assert(child != null),
        assert(vsync != null),
        assert(particleOptions != null),
        super(child: child);
  @override
  createRenderObject(BuildContext context) => _PainterRenderObject(
        vsync: vsync,
        particleOptions: particleOptions,
        particlePaint: particlePaint,
      );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    _PainterRenderObject painterRenderObject = renderObject as _PainterRenderObject;
    if (painterRenderObject.particleOptions != particleOptions)
      painterRenderObject.particleOptions = particleOptions;
    if (painterRenderObject.particlePaint != particlePaint)
      painterRenderObject.particlePaint = particlePaint;
  }
}

class ParticleOptions {
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
        assert(particleCount > 0);
}

class _PainterRenderObject extends RenderProxyBox {
  Random _random;
  List<_Particle> _particles;
  int lastTimeMs = 0;

  Ticker _ticker;

  ParticleOptions _particleOptions;
  ParticleOptions get particleOptions => _particleOptions;
  set particleOptions(value) {
    assert(value != null);
    _particleOptions = value;
    _particles = null;
  }

  Paint _particlePaint;
  Paint get particlePaint => _particlePaint;
  set particlePaint(value) {
    if (value == null) {
      _particlePaint = Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.fill
        ..strokeWidth = 1.0;
    } else {
      _particlePaint = value;
    }

    if (_particlePaint.strokeWidth <= 0)
      _particlePaint.strokeWidth = 1.0;

    _particles = null;
  }

  _PainterRenderObject({
    @required TickerProvider vsync,
    @required ParticleOptions particleOptions,
    @required Paint particlePaint,
  })  : assert(vsync != null),
        assert(particleOptions != null),
        _particleOptions = particleOptions {
    this.particlePaint = particlePaint;
    _ticker = vsync.createTicker(_tick);
    _ticker.start();
    _random = Random();
  }

  void _tick(Duration elapsed) {
    if (_particles == null) return;
    double delta = (elapsed.inMilliseconds - lastTimeMs) / 1000.0;
    lastTimeMs = elapsed.inMilliseconds;

    for (_Particle particle in _particles) {
      if (!size.contains(Offset(particle.cx, particle.cy))) {
        particle.initParticle(_random, size, particleOptions);
        continue;
      }

      particle.cx += particle.dx * delta;
      particle.cy += particle.dy * delta;
      if (particleOptions.opacityChangeRate > 0 && particle.alpha < particle.maxAlpha ||
          particleOptions.opacityChangeRate < 0 && particle.alpha > 0) {
        particle.alpha = min(max(particle.alpha + delta * particleOptions.opacityChangeRate, 0.0), particle.maxAlpha);
      }
    }
    markNeedsPaint();
  }

  @override
  paint(PaintingContext context, Offset offset) {
    if (_particles == null) {
      _particles = List.generate(particleOptions.particleCount, (i) => i).map((i) {
        return _Particle()..initParticle(_random, size, particleOptions);
      }).toList();
    }

    Canvas canvas = context.canvas;
    canvas.translate(offset.dx, offset.dy);

    for (_Particle particle in _particles) {
      if (particle.alpha == 0.0)
        continue;
      _particlePaint.color = particleOptions.baseColor.withOpacity(particle.alpha);

      canvas.drawCircle(Offset(particle.cx, particle.cy), particle.radius, _particlePaint);
    }
    canvas.translate(-offset.dx, -offset.dy);

    super.paint(context, offset);
  }
}

class _Particle {
  double cx;
  double cy;
  double dx;
  double dy;
  double radius;
  double alpha;
  double maxAlpha;

  _Particle();
  initParticle(Random r, Size size, ParticleOptions options) {
    cx = r.nextDouble() * size.width;
    cy = r.nextDouble() * size.height;
    radius = r.nextDouble() * (options.spawnMaxRadius - options.spawnMinRadius) + options.spawnMinRadius;

    double dirX = r.nextDouble() - 0.5;
    double dirY = r.nextDouble() - 0.5;
    double magSq = dirX * dirX + dirY * dirY;
    double mag = magSq <= 0 ? 1 : sqrt(magSq);
    double speed = r.nextDouble() * (options.spawnMaxSpeed - options.spawnMinSpeed) + options.spawnMinSpeed;

    dx = dirX / mag * speed;
    dy = dirY / mag * speed;
    alpha = options.spawnOpacity;
    maxAlpha = r.nextDouble() * (options.maxOpacity - options.minOpacity) + options.minOpacity;
  }
}
