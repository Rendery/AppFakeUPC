import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Vista1(),
    );
  }
}

class Vista1 extends StatefulWidget {
  @override
  _Vista1State createState() => _Vista1State();
}

class _Vista1State extends State<Vista1> {
  final Random _random = Random();
  List<double> _cloudPositionsX = List.generate(8, (index) => 0.0); // Lista para posiciones X de las nubes
  List<double> _cloudPositionsY = List.generate(8, (index) => 0.0); // Lista para posiciones Y de las nubes
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _initializeCloudPositions(); // Inicializar las posiciones de las nubes
    _moveClouds();
    _updateTime();
  }

  void _initializeCloudPositions() {
    setState(() {
      for (int i = 0; i < _cloudPositionsX.length; i++) {
        _cloudPositionsX[i] = _random.nextDouble() * 300; // Posición X aleatoria entre 0 y 300
        _cloudPositionsY[i] = _random.nextDouble() * 100 + 250; // Posición Y aleatoria entre 250 y 350
      }
    });
  }

  void _moveClouds() {
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        for (int i = 0; i < _cloudPositionsX.length; i++) {
          _cloudPositionsX[i] -= _random.nextDouble() * 2 + 1; // Movimiento aleatorio de las nubes
          if (_cloudPositionsX[i] <= -200) {
            _cloudPositionsX[i] = 300;
          }
        }
      });
    });
  }

  void _updateTime() {
    setState(() {
      final now = DateTime.now();
      _currentTime = DateFormat('HH:mm:ss').format(now);
      _currentDate = DateFormat('EEEE, d MMM. yyyy', 'es_ES').format(now);
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      setState(() {
        _currentTime = DateFormat('HH:mm:ss').format(now);
        _currentDate = DateFormat('EEEE, d MMM. yyyy', 'es_ES').format(now);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo azul en la parte baja de la pantalla
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              color: Color(0xFFF3F3FF),
            ),
          ),
          // Imagen arbolito.png arriba del contenedor
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/arbolito.png',
              height: 150,
            ),
          ),
          // Texto < TIU VIRTUAL en la parte superior izquierda
          Positioned(
            top: 40,
            left: 30,
            child: Row(
              children: [
                Text(
                  '❮',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(width: 35),
                Text(
                  'TIU VIRTUAL',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Contenedor morado con el texto de la hora
          Positioned(
            top: 124,
            left: 95,
            right: 95,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFDBD9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _currentTime, // Hora actualizada
                  style: GoogleFonts.roboto(
                    fontSize: 39,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          // Texto "hoy es sábado" debajo del contenedor morado
          Positioned(
            top: 200,
            left: 20,
            right: 20,
            child: Center(
              child: Text(
                _currentDate, // Fecha actualizada
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF41516A),
                ),
              ),
            ),
          ),
          // Nubes en diferentes posiciones y tamaños
          for (int i = 0; i < _cloudPositionsX.length; i++)
            Positioned(
              top: _cloudPositionsY[i],
              left: _cloudPositionsX[i],
              child: Image.asset('assets/cloud.png', width: 60 + i * 8),
            ),
          // Contenedor principal con contenido
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EDERY RENZO ABANTO',
                    style: GoogleFonts.oswald(
                      fontSize: 35,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'U201822832',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF41516A),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '📚 Estudiante  🪪 Campus San Miguel',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  Text(
                    '🎓 Ingeniería de Software',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          // CircleAvatar fuera del contenedor
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 120,
            left: MediaQuery.of(context).size.width / 2 - 100,
            child: CircleAvatar(
              radius: 100,
              backgroundImage: AssetImage('assets/profile_picture.jpg'),
            ),
          ),
        ],
      ),
    );
  }
}
