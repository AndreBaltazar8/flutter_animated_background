import 'package:flutter/material.dart';

class FadeRoute<T> extends MaterialPageRoute<T> {
  FadeRoute({required WidgetBuilder builder, RouteSettings? settings}) : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class SimpleFadeRoute<T> extends FadeRoute<T> {
  SimpleFadeRoute({required Widget child, RouteSettings? settings}) : super(builder: (_) => child, settings: settings);
}
