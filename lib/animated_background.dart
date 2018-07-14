library animated_background;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui' as ui;

import 'image_helper.dart';
import 'particles.dart';
export 'particles.dart';

class AnimatedBackground extends RenderObjectWidget {
  final Widget child;
  final TickerProvider vsync;
  final ParticleOptions particleOptions;
  final Paint particlePaint;
  final ParticleBehaviour particleBehaviour;

  AnimatedBackground({
    Key key,
    @required this.child,
    @required this.vsync,
    this.particleOptions = const ParticleOptions(),
    this.particlePaint,
    this.particleBehaviour,
  })  : assert(child != null),
        assert(vsync != null),
        assert(particleOptions != null),
        super(key: key);
  @override
  createRenderObject(BuildContext context) => RenderAnimatedBackground(
        vsync: vsync,
        particleOptions: particleOptions,
        particlePaint: particlePaint,
        particleBehaviour: particleBehaviour ?? RandomMovementBehavior(),
      );

  @override
  void updateRenderObject(BuildContext context, RenderAnimatedBackground renderObject) {
    renderObject
      ..particleOptions = particleOptions
      ..particleBehaviour = particleBehaviour
      ..particlePaint = particlePaint;
  }

  @override
  _AnimatedBackgroundElement createElement() => _AnimatedBackgroundElement(this);

  Widget builder(BuildContext context, BoxConstraints constraints) {
    return particleBehaviour.builder(context, constraints, child);
  }
}

class _AnimatedBackgroundElement extends RenderObjectElement {
  _AnimatedBackgroundElement(AnimatedBackground widget) : super(widget);

  @override
  AnimatedBackground get widget => super.widget;

  @override
  RenderAnimatedBackground get renderObject => super.renderObject;

  Element _child;

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
  }

  @override
  void insertChildRenderObject(RenderObject child, slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject = this.renderObject;
    assert(slot == null);
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    final RenderAnimatedBackground renderObject = this.renderObject;
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  @override
  void mount(Element parent, newSlot) {
    super.mount(parent, newSlot);
    renderObject.callback = _layoutCallback;
  }

  @override
  void update(AnimatedBackground newWidget) {
    assert(widget != newWidget);
    super.update(newWidget);
    assert(widget == newWidget);
    renderObject.callback = _layoutCallback;
    renderObject.markNeedsLayout();
  }

  @override
  void performRebuild() {
    renderObject.markNeedsLayout();
    super.performRebuild();
  }

  @override
  void unmount() {
    renderObject.callback = null;
    super.unmount();
  }

  void _layoutCallback(BoxConstraints constraints) {
    owner.buildScope(this, () {
      Widget built;
      try {
        built = widget.builder(this, constraints);
        debugWidgetBuilderValue(widget, built);
      } catch (e, stack) {
        built = ErrorWidget.builder(_debugReportException('building $widget', e, stack));
      }

      try {
        _child = updateChild(_child, built, null);
        assert(_child != null);
      } catch (e, stack) {
        built = ErrorWidget.builder(_debugReportException('building $widget', e, stack));
        _child = updateChild(null, built, slot);
      }
    });
  }

  FlutterErrorDetails _debugReportException(
      String context,
      exception,
      StackTrace stack,
      ) {

    final FlutterErrorDetails details = FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: 'animated background library',
      context: context,
    );

    FlutterError.reportError(details);
    return details;
  }
}

class RenderAnimatedBackground extends RenderProxyBox {
  int lastTimeMs = 0;
  Ticker _ticker;

  ParticleOptions _particleOptions;
  Paint _particlePaint;
  ParticleBehaviour _particleBehaviour;

  Rect _particleImageSrc;
  ui.Image _particleImage;
  Function _pendingConversion;

  ParticleOptions get particleOptions => _particleOptions;
  set particleOptions(value) {
    assert(value != null);
    if (value == _particleOptions)
      return;
    ParticleOptions oldOptions = _particleOptions;
    _particleOptions = value;

    if (_particleOptions.image == null)
      _particleImage = null;
    else if (_particleImage == null || oldOptions.image != _particleOptions.image)
      _convertParticleImage(_particleOptions.image);

    _particleBehaviour.onParticleOptionsUpdate(oldOptions);
  }

  ParticleBehaviour get particleBehaviour => _particleBehaviour;
  set particleBehaviour(value) {
    assert(value != null);
    ParticleBehaviour oldBehaviour = _particleBehaviour;
    _particleBehaviour = value;

    _particleBehaviour.renderObject = this;
    _particleBehaviour.onParticleBehaviorUpdate(oldBehaviour);
  }

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

  LayoutCallback<BoxConstraints> get callback => _callback;
  LayoutCallback<BoxConstraints> _callback;
  set callback(LayoutCallback<BoxConstraints> value) {
    if (value == _callback)
      return;
    _callback = value;
    markNeedsLayout();
  }

  RenderAnimatedBackground({
    @required TickerProvider vsync,
    @required ParticleOptions particleOptions,
    @required Paint particlePaint,
    @required ParticleBehaviour particleBehaviour,
  })  : assert(vsync != null),
        assert(particleOptions != null),
        assert(particleBehaviour != null),
        _particleOptions = particleOptions,
        _particleBehaviour = particleBehaviour {
    this.particlePaint = particlePaint;
    _particleBehaviour.renderObject = this;

    _ticker = vsync.createTicker(_tick);
    _ticker.start();

    if (_particleOptions.image != null)
      _convertParticleImage(_particleOptions.image);
  }

  void _tick(Duration elapsed) {
    double delta = (elapsed.inMilliseconds - lastTimeMs) / 1000.0;
    lastTimeMs = elapsed.inMilliseconds;

    if (_particleBehaviour.tick(delta, elapsed))
      markNeedsPaint();
  }

  @override
  void performLayout() {
    assert(callback != null);
    invokeLayoutCallback(callback);
    if (child != null)
      child.layout(constraints, parentUsesSize: true);
    size = constraints.biggest;
  }

  @override
  paint(PaintingContext context, Offset offset) {
    if (particleBehaviour.particles == null)
      particleBehaviour.initBehaviour();

    Canvas canvas = context.canvas;
    canvas.translate(offset.dx, offset.dy);

    for (Particle particle in particleBehaviour.particles) {
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