import 'dart:math' as math;

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
  int _counter = 40;
  double _spawnOpacity = 0.0;
  double _opacityChangeRate = 0.25;
  double _minOpacity = 0.1;
  double _maxOpacity = 0.4;
  double _minRadius = 7.0;
  double _maxRadius = 15.0;
  double _minSpeed = 30.0;
  double _maxSpeed = 70.0;
  ParticleBehaviour _behaviour = const RandomMovementBehavior();
  bool _showSettings = false;
  ParticleType _particleType = ParticleType.Image;
  bool _paintFill = false;
  double _strokeWidth = 1.0;
  Image _image = Image.asset('assets/images/star_stroke.png');

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
        particleOptions: ParticleOptions(
          image: _particleType == ParticleType.Image ? _image : null,
          baseColor: Colors.blue,
          spawnOpacity: _spawnOpacity,
          opacityChangeRate: _opacityChangeRate,
          minOpacity: _minOpacity,
          maxOpacity: _maxOpacity,
          spawnMinSpeed: _minSpeed,
          spawnMaxSpeed: _maxSpeed,
          spawnMinRadius: _minRadius,
          spawnMaxRadius: _maxRadius,
          particleCount: _counter,
        ),
        particlePaint: Paint()
          ..style = _paintFill ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = _strokeWidth,
        particleBehaviour: _behaviour,
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
      if (_particleType == ParticleType.Image)
        _counter = math.min(_counter, 100);
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
            Text('Count:'),
            Slider(
              value: _counter.toDouble(),
              min: 0.0,
              max: _particleType == ParticleType.Image ? 100.0 : 1000.0,
              divisions: 100,
              onChanged: (value) {
                setState(() {
                  _counter = value.floor();
                });
              },
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Text('Spawn opacity:'),
            Slider(
              value: _spawnOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: (value) => setState(() => _spawnOpacity = value),
            ),
            Text('${_spawnOpacity.toStringAsFixed(1)}'),
          ],
        ),
        Row(
          children: <Widget>[
            Text('Opacity rate:'),
            Slider(
              value: _opacityChangeRate,
              min: -2.0,
              max: 2.0,
              divisions: 80,
              onChanged: (value) => setState(() => _opacityChangeRate = value),
            ),
            Text('${_opacityChangeRate.toStringAsFixed(2)}'),
          ],
        ),
        Row(
          children: <Widget>[
            Text('Min opacity:'),
            Slider(
              value: _minOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _minOpacity = value;
                  _maxOpacity = math.max(_maxOpacity, _minOpacity);
                });
              },
            ),
            Text('${_minOpacity.toStringAsFixed(2)}'),
          ],
        ),
        Row(
          children: <Widget>[
            Text('Max opacity:'),
            Slider(
              value: _maxOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _maxOpacity = value;
                  _minOpacity = math.min(_minOpacity, _maxOpacity);
                });
              },
            ),
            Text('${_maxOpacity.toStringAsFixed(2)}'),
          ],
        ),
        Row(
          children: <Widget>[
            Text('Min radius:'),
            Slider(
              value: _minRadius,
              min: 1.0,
              max: 100.0,
              divisions: 99,
              onChanged: (value) {
                setState(() {
                  _minRadius = value;
                  _maxRadius = math.max(_maxRadius, _minRadius);
                });
              },
            ),
            Text('${_minRadius.toInt()}'),
          ],
        ),
        Row(
          children: <Widget>[
            Text('Max radius:'),
            Slider(
              value: _maxRadius,
              min: 1.0,
              max: 100.0,
              divisions: 99,
              onChanged: (value) {
                setState(() {
                  _maxRadius = value;
                  _minRadius = math.min(_minRadius, _maxRadius);
                });
              },
            ),
            Text('${_maxRadius.toInt()}'),
          ],
        ),
        Row(
          children: <Widget>[
            Text('Min speed:'),
            Slider(
              value: _minSpeed,
              min: 1.0,
              max: 100.0,
              divisions: 99,
              onChanged: (value) {
                setState(() {
                  _minSpeed = value;
                  _maxSpeed = math.max(_maxSpeed, _minSpeed);
                });
              },
            ),
            Text('${_minSpeed.toInt()}'),
          ],
        ),
        Row(
          children: <Widget>[
            Text('Max speed:'),
            Slider(
              value: _maxSpeed,
              min: 1.0,
              max: 100.0,
              divisions: 99,
              onChanged: (value) {
                setState(() {
                  _maxSpeed = value;
                  _minSpeed = math.min(_minSpeed, _maxSpeed);
                });
              },
            ),
            Text('${_maxSpeed.toInt()}'),
          ],
        ),
        SizedBox(height: 10.0),
        Row(
          children: <Widget>[
            RaisedButton(
              child: Text('Next'),
              onPressed: () {
                setState(() {
                  switch (_behaviour.runtimeType) {
                    case RainBehaviour:
                      _behaviour = const RandomMovementBehavior();
                      break;
                    case RandomMovementBehavior:
                      _behaviour = const RainBehaviour();
                  }
                });
              },
            ),
            SizedBox(width: 10.0),
            Text('Current: ${_behaviour.runtimeType.toString()}'),
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
      ],
    );
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
                  child: Text('Keyboard'),
                  onPressed: () {
                    Clipboard.getData('text/plain').then((ClipboardData value) {
                      if (value == null)
                        return;
                      setState(() {
                        _image = Image.network(value.text);
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
                  onChanged: (value) => setState(() => _paintFill = value),
                  value: _paintFill,
                ),
                Text('Fill Shape')
              ],
            ),
            Row(
             children: <Widget>[
               Text('Stroke Width:'),
               Slider(
                 value: _strokeWidth,
                 min: 1.0,
                 max: 50.0,
                 divisions: 49,
                 onChanged: (value) => setState(() => _strokeWidth = value),
               ),
               Text('${_strokeWidth.toInt()}'),
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
              color: _image.image == image.image ? Colors.amber : Colors.transparent,
            ),
          ),
          child: image,
        ),
        width: 40.0,
        height: 40.0,
      ),
      onTap: () => setState(() => _image = image),
    );
  }
}

enum ParticleType {
  Shape,
  Image,
}

class RainBehaviour extends ParticleBehaviour {
  static math.Random random = math.Random();

  const RainBehaviour();

  @override
  void initParticle(Particle particle, Size size, ParticleOptions options) {
    particle.cx = random.nextDouble() * size.width;
    if (particle.cy == 0.0)
      particle.cy = random.nextDouble() * size.height;
    else
      particle.cy = random.nextDouble() * size.width * 0.2;

    double speed = random.nextDouble() * (options.spawnMaxSpeed - options.spawnMinSpeed) + options.spawnMinSpeed;

    double dirX = (random.nextDouble() - 0.5);
    double dirY = random.nextDouble() * 0.5 + 0.5;
    double magSq = dirX * dirX + dirY * dirY;
    double mag = magSq <= 0 ? 1 : math.sqrt(magSq);

    particle.dx = dirX / mag * speed;
    particle.dy = dirY / mag * speed;

    particle.radius = random.nextDouble() * (options.spawnMaxRadius - options.spawnMinRadius) + options.spawnMinRadius;
    particle.alpha = options.spawnOpacity;
    particle.maxAlpha = random.nextDouble() * (options.maxOpacity - options.minOpacity) + options.minOpacity;
  }

  @override
  void onParticleBehaviorUpdate(ParticleBehaviour oldBehaviour, Size size, ParticleOptions options, List<Particle> particles) {
    // TODO: implement onParticleBehaviorUpdate
  }

  @override
  void onParticleOptionsUpdate(ParticleOptions options, ParticleOptions oldOptions, Size size, List<Particle> particles) {
    // TODO: implement onParticleOptionsUpdate
  }

  @override
  Widget builder(BuildContext context, BoxConstraints constraints, Widget child, List<Particle> particles, ParticleOptions options) {
    return GestureDetector(
      onTapDown: (details) {
        RenderBox renderBox = context.findRenderObject() as RenderBox;
        var offset = renderBox.globalToLocal(details.globalPosition);
        particles.forEach((particle) {
          var delta = (Offset(particle.cx, particle.cy) - offset);
          if (delta.distanceSquared < 70 * 70) {
            var speed = particle.speed;
            var mag = delta.distance;
            speed *= (70 - mag) / 70.0 * 2.0 + 1;
            speed = math.min(options.spawnMaxSpeed, speed);
            particle.dx = delta.dx / mag * speed;
            particle.dy = delta.dy / mag * speed;
          }
        });
      },
      child: ConstrainedBox( // necessary to force gesture detector to cover screen
        constraints: BoxConstraints(minHeight: double.infinity, minWidth: double.infinity),
        child: super.builder(context, constraints, child, particles, options),
      ),
    );
  }
}
