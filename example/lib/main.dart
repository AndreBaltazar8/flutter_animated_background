import 'package:animated_background/animated_background.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Animated Background Example',
        ),
      ),
      body: AnimatedBackground(
        vsync: this,
        // behaviour: RandomParticleBehaviour(
        //   options: ParticleOptions(
        //     image: Image.network(
        //       'https://www.pngmart.com/files/8/Cockroach-PNG-Transparent-File.png',
        //     ),
        //     maxOpacity: 1,
        //     spawnMaxRadius: 100,
        //     spawnMaxSpeed: 100,
        //     spawnMinSpeed: 50,
        //   ),
        // ),

        behaviour: RainMultipleImagesParticleBehaviour(
          options: MultipleImagesPartialOptions(
            images: [
              Image.network(
                'https://www.pngmart.com/files/8/Cockroach-PNG-Transparent-File.png',
              ),
              Image.network(
                'https://static.vecteezy.com/system/resources/previews/001/200/028/original/dog-png.png',
              ),
              Image.network(
                'https://www.pngitem.com/pimgs/m/247-2477379_transparent-background-cartoon-house-png-png-download.png',
              ),
            ],
            // particleCount: 5,
            spawnMinRadius: 1,
            spawnMaxRadius: 70,
            spawnMaxSpeed: 100,
            spawnMinSpeed: 50,
          ),
        ),
        child: const SizedBox(),
      ),
    );
  }
}
