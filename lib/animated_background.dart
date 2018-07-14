library animated_background;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

export 'particles.dart';
export 'rectangles.dart';

class AnimatedBackground extends RenderObjectWidget {
  final Widget child;
  final TickerProvider vsync;
  final Behaviour behaviour;

  AnimatedBackground({
    Key key,
    @required this.child,
    @required this.vsync,
    @required this.behaviour,
  })  : assert(child != null),
        assert(vsync != null),
        assert(behaviour != null),
        super(key: key);
  @override
  createRenderObject(BuildContext context) => RenderAnimatedBackground(
      vsync: vsync,
      behaviour: behaviour,
    );

  @override
  void updateRenderObject(BuildContext context, RenderAnimatedBackground renderObject) {
    renderObject
      ..behaviour = behaviour;
  }

  @override
  _AnimatedBackgroundElement createElement() => _AnimatedBackgroundElement(this);

  Widget builder(BuildContext context, BoxConstraints constraints) {
    return behaviour.builder(context, constraints, child);
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

  Behaviour _behaviour;
  Behaviour get behaviour => _behaviour;
  set behaviour(value) {
    assert(value != null);
    Behaviour oldBehaviour = _behaviour;
    _behaviour = value;

    _behaviour.renderObject = this;
    _behaviour.initFrom(oldBehaviour);
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
    @required Behaviour behaviour,
  })  : assert(vsync != null),
        assert(behaviour != null),
        _behaviour = behaviour {
    _behaviour.renderObject = this;

    _ticker = vsync.createTicker(_tick);
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    double delta = (elapsed.inMilliseconds - lastTimeMs) / 1000.0;
    lastTimeMs = elapsed.inMilliseconds;

    if (_behaviour.tick(delta, elapsed))
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
    if (!behaviour.isInitialized)
      behaviour.init();

    Canvas canvas = context.canvas;
    canvas.translate(offset.dx, offset.dy);
    behaviour.paint(context, offset);
    canvas.translate(-offset.dx, -offset.dy);

    super.paint(context, offset);
  }
}

abstract class Behaviour {
  RenderAnimatedBackground renderObject;
  @protected
  Size get size => renderObject?.size;

  bool get isInitialized;

  @protected
  void init();

  @protected
  void initFrom(Behaviour oldBehaviour);

  @protected
  bool tick(double delta, Duration elapsed);

  @protected
  void paint(PaintingContext context, Offset offset);

  @protected
  @mustCallSuper
  Widget builder(BuildContext context, BoxConstraints constraints, Widget child) {
    return child;
  }
}
