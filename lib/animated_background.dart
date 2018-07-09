library animated_background;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui' as ui;

import 'image_helper.dart';

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
        assert(particleCount > 0);
}

class _PainterRenderObject extends RenderProxyBox {
  List<_Particle> _particles;
  int lastTimeMs = 0;

  Ticker _ticker;

  ParticleOptions _particleOptions;
  ParticleOptions get particleOptions => _particleOptions;

  Rect _particleImageSrc;
  ui.Image _particleImage;
  Function _pendingConversion;

  set particleOptions(value) {
    assert(value != null);
    if (value == _particleOptions)
      return;
    ParticleOptions oldOptions = value;
    _particleOptions = value;

    if (_particleOptions.image == null)
      _particleImage = null;
    else if (oldOptions.image != _particleOptions.image)
      _convertParticleImage(_particleOptions.image);

    if (_particles == null)
      return;
    if (_particles.length > _particleOptions.particleCount)
      _particles.removeRange(0, _particles.length - particleOptions.particleCount);
    else if (_particles.length < _particleOptions.particleCount)
      _particles.addAll(_generateParticles(_particleOptions.particleCount - _particles.length));


    double minSpeedSqr = particleOptions.spawnMinSpeed * particleOptions.spawnMinSpeed;
    double maxSpeedSqr = particleOptions.spawnMaxSpeed * particleOptions.spawnMaxSpeed;
    for (_Particle p in _particles) {
      // speed assignment is better done this way, to prevent calculation of square roots if not needed
      double speedSqr = p.speedSqr;
      if (speedSqr > maxSpeedSqr)
        p.speed = particleOptions.spawnMaxSpeed;
      else if (speedSqr < minSpeedSqr)
        p.speed = particleOptions.spawnMinSpeed;

      // TODO: handle opacity change

      if (p.radius < particleOptions.spawnMinRadius || p.radius > particleOptions.spawnMaxRadius)
        p.newRadius(particleOptions);
    }
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

    if (_particleOptions.image != null)
      _convertParticleImage(_particleOptions.image);
  }

  void _tick(Duration elapsed) {
    if (_particles == null) return;
    double delta = (elapsed.inMilliseconds - lastTimeMs) / 1000.0;
    lastTimeMs = elapsed.inMilliseconds;

    for (_Particle particle in _particles) {
      if (!size.contains(Offset(particle.cx, particle.cy))) {
        particle.initParticle(size, particleOptions);
        continue;
      }

      particle.cx += particle.dx * delta;
      particle.cy += particle.dy * delta;
      if (particleOptions.opacityChangeRate > 0 && particle.alpha < particle.maxAlpha ||
          particleOptions.opacityChangeRate < 0 && particle.alpha > 0) {
        particle.alpha = math.min(math.max(particle.alpha + delta * particleOptions.opacityChangeRate, 0.0), particle.maxAlpha);
      }
    }
    markNeedsPaint();
  }

  _generateParticles(int numParticles) {
    return List.generate(numParticles, (i) => i).map((i) {
      return _Particle()..initParticle(size, particleOptions);
    }).toList();
  }

  @override
  paint(PaintingContext context, Offset offset) {
    if (_particles == null) {
      _particles = _generateParticles(particleOptions.particleCount);
    }

    Canvas canvas = context.canvas;
    canvas.translate(offset.dx, offset.dy);

    for (_Particle particle in _particles) {
      if (particle.alpha == 0.0)
        continue;
      _particlePaint.color = particleOptions.baseColor.withOpacity(particle.alpha);


      if (_particleImage != null) {
        Rect dst = Rect.fromLTRB(particle.cx - particle.radius, particle.cy - particle.radius, particle.cx + particle.radius, particle.cy + particle.radius);
        canvas.drawImageRect(_particleImage, _particleImageSrc, dst, _particlePaint);
      } else
        canvas.drawCircle(Offset(particle.cx, particle.cy), particle.radius, _particlePaint);
    }
    canvas.translate(-offset.dx, -offset.dy);

    super.paint(context, offset);
  }

  void _convertParticleImage(Image image) async {
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

class _Particle {
  static math.Random random = math.Random();
  double cx;
  double cy;
  double dx;
  double dy;
  double radius;
  double alpha;
  double maxAlpha;

  _Particle();
  initParticle(Size size, ParticleOptions options) {
    cx = random.nextDouble() * size.width;
    cy = random.nextDouble() * size.height;
    newRadius(options);

    double speed = random.nextDouble() * (options.spawnMaxSpeed - options.spawnMinSpeed) + options.spawnMinSpeed;
    newDirection(speed);

    alpha = options.spawnOpacity;
    maxAlpha = random.nextDouble() * (options.maxOpacity - options.minOpacity) + options.minOpacity;
  }

  newRadius(ParticleOptions options) {
    radius = random.nextDouble() * (options.spawnMaxRadius - options.spawnMinRadius) + options.spawnMinRadius;
  }

  newDirection(double speed) {
    double dirX = random.nextDouble() - 0.5;
    double dirY = random.nextDouble() - 0.5;
    double magSq = dirX * dirX + dirY * dirY;
    double mag = magSq <= 0 ? 1 : math.sqrt(magSq);

    dx = dirX / mag * speed;
    dy = dirY / mag * speed;
  }

  double get speedSqr => dx * dx + dy * dy;
  set speedSqr (double value) {
    speed = math.sqrt(value.abs()) * value.sign;
  }

  double get speed => math.sqrt(speedSqr);
  set speed (double value) {
    double mag = speed;
    if (mag == 0) {
      newDirection(value);
    } else {
      dx = dx / mag * value;
      dy = dy / mag * value;
    }
  }
}
