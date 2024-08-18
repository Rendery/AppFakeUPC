import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'vista_configuracion.dart';

class VistaTIU extends StatefulWidget {
  @override
  _VistaTIUState createState() => _VistaTIUState();
}

class _VistaTIUState extends State<VistaTIU> {
  final Random _random = Random();
  List<double> _cloudPositionsX = List.generate(8, (index) => 0.0);
  List<double> _cloudPositionsY = List.generate(8, (index) => 0.0);
  String _currentTime = '';
  String _currentDate = '';
  String _userName = 'EDERY RENZO ABANTO';
  String _userCode = 'U201822832';

  @override
  void initState() {
    super.initState();
    _initializeCloudPositions();
    _moveClouds();
    _updateTime();
  }

  void _initializeCloudPositions() {
    setState(() {
      for (int i = 0; i < _cloudPositionsX.length; i++) {
        _cloudPositionsX[i] = _random.nextDouble() * 300;
        _cloudPositionsY[i] = _random.nextDouble() * 100 + 250;
      }
    });
  }

  void _moveClouds() {
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        for (int i = 0; i < _cloudPositionsX.length; i++) {
          _cloudPositionsX[i] -= _random.nextDouble() * 2 + 1;
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              color: Color(0xFFF3F3FF),
            ),
          ),
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/arbolito.png',
              height: 150,
            ),
          ),
          Positioned(
            top: 50,
            left: 30,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VistaConfiguracion(
                          onNameChanged: (newName) {
                            setState(() {
                              _userName = newName.toUpperCase();
                            });
                          },
                          onCodeChanged: (newCode) {
                            setState(() {
                              _userCode = newCode.toUpperCase();
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Text(
                    '❮',
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                SizedBox(width: 32),
                Text(
                  'TIU VIRTUAL',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 130,
            left: 85,
            right: 85,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Color(0xFFDBD9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _currentTime,
                  style: GoogleFonts.roboto(
                    fontSize: 35,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: 20,
            right: 20,
            child: Center(
              child: Text(
                _currentDate,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF41516A),
                ),
              ),
            ),
          ),
          for (int i = 0; i < _cloudPositionsX.length; i++)
            Positioned(
              top: _cloudPositionsY[i],
              left: _cloudPositionsX[i],
              child: Image.asset('assets/cloud.png', width: 55 + i * 5),
            ),
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
                    _userName,
                    style: GoogleFonts.oswald(
                      fontSize: 31,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _userCode,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF41516A),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '📚  Estudiante  💳  Campus San Miguel',
                    style: TextStyle(fontSize: 14, color: Color(0xFF41516A)),
                  ),
                  Text(
                    '🎓 Ingeniería de Software',
                    style: TextStyle(fontSize: 14, color: Color(0xFF41516A)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 108,
            left: MediaQuery.of(context).size.width / 2 - 90,
            child: CircleAvatar(
              radius: 90,
              backgroundImage: AssetImage('assets/profile_picture.jpg'),
            ),
          ),
        ],
      ),
    );
  }
}
