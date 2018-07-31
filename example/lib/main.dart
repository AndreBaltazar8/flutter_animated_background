import 'dart:math' as math;

import './helpers/fade_route.dart';
import './views/space_splash.dart';
import 'package:flutter/material.dart';

import 'package:animated_background/animated_background.dart';
import 'package:flutter/services.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Animated Background Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Animated Background Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  static const numBehaviours = 6;

  // Particles
  ParticleType _particleType = ParticleType.Image;
  Image _image = Image.asset('assets/images/star_stroke.png');

  ParticleOptions particleOptions = ParticleOptions(
    image: Image.asset('assets/images/star_stroke.png'),
    baseColor: Colors.blue,
    spawnOpacity: 0.0,
    opacityChangeRate: 0.25,
    minOpacity: 0.1,
    maxOpacity: 0.4,
    spawnMinSpeed: 30.0,
    spawnMaxSpeed: 70.0,
    spawnMinRadius: 7.0,
    spawnMaxRadius: 15.0,
    particleCount: 40,
  );

  var particlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  // Lines

  var _lineDirection = LineDirection.Ltr;
  int _lineCount = 50;

  // Bubbles
  BubbleOptions _bubbleOptions = BubbleOptions();

  // General Variables
  int _behaviourIndex = 0;
  Behaviour _behaviour;

  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings_input_component),
            color: _showSettings ? Colors.amber : Colors.white,
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
        ],
      ),
      body: AnimatedBackground(
        behaviour: _behaviour = _buildBehaviour(),
        vsync: this,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _showSettings ? _buildSettings() : Container(),
          ),
        ),
      ),
    );
  }

  void _onTypeChange(ParticleType type) {
    setState(() {
      _particleType = type;
      if (_particleType == ParticleType.Image) {
        particleOptions = particleOptions.copyWith(
          image: _image,
          particleCount: math.min(particleOptions.particleCount, 100),
        );
      } else {
        particleOptions = particleOptions.copyWith(
          image: null,
        );
      }
    });
  }

  Widget _buildParticleTypeSelector(ParticleType type) {
    return Row(
      children: <Widget>[
        Radio<ParticleType>(
          onChanged: _onTypeChange,
          value: type,
          groupValue: _particleType,
        ),
        GestureDetector(
          child: Text(type.toString().split('.')[1]),
          onTap: () => _onTypeChange(type),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            RaisedButton(
              child: Text('Next'),
              onPressed: () {
                setState(() {
                  _behaviourIndex = (_behaviourIndex + 1) % numBehaviours;
                });
              },
            ),
            SizedBox(width: 10.0),
            Text('Current: ${_behaviourIndex + 1} out of $numBehaviours'),
          ],
        ),
        SizedBox(height: 10.0),
        Text('Behaviour: ${_behaviour.runtimeType.toString()}'),
        SizedBox(height: 10.0),
      ]..addAll(_behaviour is ParticleBehaviour ? _buildParticleSettings() : Iterable.empty())
        ..addAll(_behaviour is RacingLinesBehaviour ? _buildLinesSettings() : Iterable.empty())
        ..addAll(_behaviour is BubblesBehaviour ? _buildBubblesSettings() : Iterable.empty())
        ..addAll(_behaviour is SpaceBehaviour ? _buildSpaceSettings() : Iterable.empty()),
    );
  }

  List<Widget> _buildParticleSettings() {
    return <Widget>[
      Row(
        children: <Widget>[
          Text('Count:'),
          Slider(
            value: particleOptions.particleCount.toDouble(),
            min: 0.0,
            max: _particleType == ParticleType.Image ? 100.0 : 1000.0,
            divisions: 100,
            onChanged: (value) {
              setState(() {
                particleOptions = particleOptions.copyWith(
                  particleCount: value.floor(),
                );
              });
            },
          ),
          Text(
            '${particleOptions.particleCount}',
            style: Theme.of(context).textTheme.display1,
          ),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Spawn opacity:'),
          Slider(
            value: particleOptions.spawnOpacity,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              setState(() {
                particleOptions = particleOptions.copyWith(
                  spawnOpacity: value,
                );
              });
            },
          ),
          Text('${particleOptions.spawnOpacity.toStringAsFixed(1)}'),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Opacity rate:'),
          Slider(
            value: particleOptions.opacityChangeRate,
            min: -2.0,
            max: 2.0,
            divisions: 80,
            onChanged: (value) {
              setState(() {
                particleOptions = particleOptions.copyWith(
                  opacityChangeRate: value,
                );
              });
            },
          ),
          Text('${particleOptions.opacityChangeRate.toStringAsFixed(2)}'),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Min opacity:'),
          Slider(
            value: particleOptions.minOpacity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                particleOptions = particleOptions.copyWith(
                  minOpacity: value,
                  maxOpacity: math.max(particleOptions.maxOpacity, value),
                );
              });
            },
          ),
          Text('${particleOptions.minOpacity.toStringAsFixed(2)}'),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Max opacity:'),
          Slider(
            value: particleOptions.maxOpacity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                particleOptions = particleOptions.copyWith(
                  maxOpacity: value,
                  minOpacity: math.min(particleOptions.minOpacity, value),
                );
              });
            },
          ),
          Text('${particleOptions.maxOpacity.toStringAsFixed(2)}'),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Min radius:'),
          Slider(
            value: particleOptions.spawnMinRadius,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                particleOptions = particleOptions.copyWith(
                  spawnMinRadius: value,
                  spawnMaxRadius: math.max(particleOptions.spawnMaxRadius, value),
                );
              });
            },
          ),
          Text('${particleOptions.spawnMinRadius.toInt()}'),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Max radius:'),
          Slider(
            value: particleOptions.spawnMaxRadius,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                particleOptions = particleOptions.copyWith(
                  spawnMaxRadius: value,
                  spawnMinRadius: math.min(particleOptions.spawnMinRadius, value),
                );
              });
            },
          ),
          Text('${particleOptions.spawnMaxRadius.toInt()}'),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Min speed:'),
          Slider(
            value: particleOptions.spawnMinSpeed,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                particleOptions = particleOptions.copyWith(
                  spawnMinSpeed: value,
                  spawnMaxSpeed: math.max(particleOptions.spawnMaxSpeed, value),
                );
              });
            },
          ),
          Text('${particleOptions.spawnMinSpeed.toInt()}'),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Max speed:'),
          Slider(
            value: particleOptions.spawnMaxSpeed,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                particleOptions = particleOptions.copyWith(
                  spawnMaxSpeed: value,
                  spawnMinSpeed: math.min(particleOptions.spawnMinSpeed, value),
                );
              });
            },
          ),
          Text('${particleOptions.spawnMaxSpeed.toInt()}'),
        ],
      ),
      SizedBox(height: 10.0),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildParticleTypeSelector(ParticleType.Shape),
          _buildParticleTypeSelector(ParticleType.Image),
        ],
      ),
      _buildTypeSettings(),
    ];
  }

  Widget _buildTypeSettings() {
    switch (_particleType) {
      case ParticleType.Image:
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _buildImageSelector(Image.asset('assets/images/star_stroke.png')),
                _buildImageSelector(Image.asset('assets/images/icy_logo.png')),
                RaisedButton(
                  child: Text('Clipboard'),
                  onPressed: () {
                    Clipboard.getData('text/plain').then((ClipboardData value) {
                      if (value == null)
                        return;
                      setState(() {
                        _image = Image.network(value.text);
                        particleOptions = particleOptions.copyWith(
                          image: _image,
                        );
                      });
                    });
                  },
                ),
              ],
            ),
          ],
        );
      case ParticleType.Shape:
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Checkbox(
                  onChanged: (value) => setState(() {
                    particlePaint.style = value ? PaintingStyle.fill : PaintingStyle.stroke;
                  }),
                  value: particlePaint.style == PaintingStyle.fill,
                ),
                Text('Fill Shape')
              ],
            ),
            Row(
              children: <Widget>[
                Text('Stroke Width:'),
                Slider(
                  value: particlePaint.strokeWidth,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  onChanged: (value) => setState(() => particlePaint.strokeWidth = value),
                ),
                Text('${particlePaint.strokeWidth.toInt()}'),
              ],
            ),
          ],
        );
    }
    return Container();
  }

  Widget _buildImageSelector(Image image) {
    return InkWell(
      child: SizedBox(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.0,
              color: _image.image == image.image ? Colors.amber : Colors
                  .transparent,
            ),
          ),
          child: image,
        ),
        width: 40.0,
        height: 40.0,
      ),
      onTap: () => setState(() {
        _image = image;
        particleOptions = particleOptions.copyWith(
          image: _image,
        );
      }),
    );
  }

  List<Widget> _buildLinesSettings() {
    return <Widget>[
      Row(
        children: <Widget>[
          Text('Count:'),
          Slider(
            value: _lineCount.toDouble(),
            min: 0.0,
            max: 500.0,
            divisions: 100,
            onChanged: (value) {
              setState(() {
                _lineCount = value.floor();
              });
            },
          ),
          Text(
            '$_lineCount',
            style: Theme.of(context).textTheme.display1,
          ),
        ],
      ),
      Row(
        children: <Widget>[
          RaisedButton(
            child: Text('Next Direction'),
            onPressed: () {
              setState(() {
                _lineDirection = LineDirection.values[(_lineDirection.index + 1) % 4];
              });
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildBubblesSettings() {
    return <Widget>[
      Row(
        children: <Widget>[
          Text('Count:'),
          Slider(
            value: _bubbleOptions.bubbleCount.toDouble(),
            min: 0.0,
            max: 400.0,
            divisions: 400,
            onChanged: (value) {
              setState(() {
                _bubbleOptions = _bubbleOptions.copyWith(
                  bubbleCount: value.floor(),
                );
              });
            },
          ),
          Text(
            '${_bubbleOptions.bubbleCount}',
            style: Theme.of(context).textTheme.display1,
          ),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Min radius:'),
          Slider(
            value: _bubbleOptions.minTargetRadius,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                _bubbleOptions = _bubbleOptions.copyWith(
                  minTargetRadius: value,
                  maxTargetRadius: math.max(_bubbleOptions.maxTargetRadius, value),
                );
              });
            },
          ),
          Text('${_bubbleOptions.minTargetRadius.toInt()}'),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Max radius:'),
          Slider(
            value: _bubbleOptions.maxTargetRadius,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                _bubbleOptions = _bubbleOptions.copyWith(
                  maxTargetRadius: value,
                  minTargetRadius: math.min(_bubbleOptions.minTargetRadius, value),
                );
              });
            },
          ),
          Text('${_bubbleOptions.maxTargetRadius.toInt()}'),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Growth Rate:'),
          Slider(
            value: _bubbleOptions.growthRate,
            min: 0.0,
            max: 400.0,
            divisions: 401,
            onChanged: (value) {
              setState(() {
                _bubbleOptions = _bubbleOptions.copyWith(
                  growthRate: value,
                );
              });
            },
          ),
          Text('${_bubbleOptions.growthRate.toInt()}'),
        ],
      ),
      Row(
        children: <Widget>[
          Text('Pop Rate:'),
          Slider(
            value: _bubbleOptions.popRate,
            min: 0.0,
            max: 400.0,
            divisions: 401,
            onChanged: (value) {
              setState(() {
                _bubbleOptions = _bubbleOptions.copyWith(
                  popRate: value,
                );
              });
            },
          ),
          Text('${_bubbleOptions.popRate.toInt()}'),
        ],
      ),
    ];
  }

  List<Widget> _buildSpaceSettings() {
    return <Widget>[
      Row(
        children: <Widget>[
          RaisedButton(
            child: Text('Launch Example Splash'),
            onPressed: () {
              setState(() {
                Navigator.of(context).push(SimpleFadeRoute(
                  child: SpaceSplash(),
                ));
              });
            },
          ),
        ],
      ),
    ];
  }

  Behaviour _buildBehaviour() {
    switch (_behaviourIndex) {
      case 0:
        return RandomParticleBehaviour(
          options: particleOptions,
          paint: particlePaint,
        );
      case 1:
        return RainParticleBehaviour(
          options: particleOptions,
          paint: particlePaint,
          enabled: !_showSettings,
        );
      case 2:
        return RectanglesBehaviour();
      case 3:
        return RacingLinesBehaviour(
          direction: _lineDirection,
          numLines: _lineCount,
        );
      case 4:
        return BubblesBehaviour(
          options: _bubbleOptions,
        );
      case 5:
        return SpaceBehaviour();
    }

    return RandomParticleBehaviour(
      options: particleOptions,
      paint: particlePaint,
    );
  }
}

enum ParticleType {
  Shape,
  Image,
}

class RainParticleBehaviour extends RandomParticleBehaviour {
  static math.Random random = math.Random();

  bool enabled;

  RainParticleBehaviour({
    ParticleOptions options = const ParticleOptions(),
    Paint paint,
    this.enabled = true,
  }) : assert(options != null),
        super(options: options, paint: paint);

  @override
  void initPosition(Particle p) {
    p.cx = random.nextDouble() * size.width;
    if (p.cy == 0.0)
      p.cy = random.nextDouble() * size.height;
    else
      p.cy = random.nextDouble() * size.width * 0.2;
  }

  @override
  void initDirection(Particle p, double speed) {
    double dirX = (random.nextDouble() - 0.5);
    double dirY = random.nextDouble() * 0.5 + 0.5;
    double magSq = dirX * dirX + dirY * dirY;
    double mag = magSq <= 0 ? 1 : math.sqrt(magSq);

    p.dx = dirX / mag * speed;
    p.dy = dirY / mag * speed;
  }

  @override
  Widget builder(BuildContext context, BoxConstraints constraints, Widget child) {
    return GestureDetector(
      onPanUpdate: enabled ? (details) => _updateParticles(context, details.globalPosition) : null,
      onTapDown: enabled ? (details) => _updateParticles(context, details.globalPosition) : null,
      child: ConstrainedBox( // necessary to force gesture detector to cover screen
        constraints: BoxConstraints(minHeight: double.infinity, minWidth: double.infinity),
        child: super.builder(context, constraints, child),
      ),
    );
  }

  void _updateParticles(BuildContext context, Offset offsetGlobal) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var offset = renderBox.globalToLocal(offsetGlobal);
    particles.forEach((particle) {
      var delta = (Offset(particle.cx, particle.cy) - offset);
      if (delta.distanceSquared < 70 * 70) {
        var speed = particle.speed;
        var mag = delta.distance;
        speed *= (70 - mag) / 70.0 * 2.0 + 0.5;
        speed = math.max(options.spawnMinSpeed, math.min(options.spawnMaxSpeed, speed));
        particle.dx = delta.dx / mag * speed;
        particle.dy = delta.dy / mag * speed;
      }
    });
  }
}
