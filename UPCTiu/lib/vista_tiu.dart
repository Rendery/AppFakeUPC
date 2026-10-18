import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vista_configuracion.dart';

class VistaTIU extends StatefulWidget {
  const VistaTIU({super.key});

  @override
  State<VistaTIU> createState() => _VistaTIUState();
}

class _VistaTIUState extends State<VistaTIU> {
  final double _cloudBaseSize = 50.0;
  final double _cloudSizeVariation = 6.0;
  final double _cloudSpawnYBase = 350.0;
  final double _cloudSpawnYVariation = 40.0;

  final List<double> _cloudPositionsX = List.generate(6, (index) => Random().nextDouble() * 380);

  String _currentTime = '';
  String _currentDate = '';

  // Variables de estado con valores por defecto
  String _userName = 'EDERY RENZO A*** V***';
  String _userCode = '201822832';
  String _idBanner = 'N01864219';
  double _nameFontSize = 32.0;
  double _descFontSize = 18.0;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _startClock();
    _startCloudAnimation();
    _loadSavedData();
  }

  // Cargar datos de SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? _userName;
      _userCode = prefs.getString('userCode') ?? _userCode;
      _idBanner = prefs.getString('idBanner') ?? _idBanner;
      _nameFontSize = prefs.getDouble('nameFontSize') ?? _nameFontSize;
      _descFontSize = prefs.getDouble('descFontSize') ?? _descFontSize;
      _imagePath = prefs.getString('imagePath');
    });
  }

  // Guardar datos en SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName);
    await prefs.setString('userCode', _userCode);
    await prefs.setString('idBanner', _idBanner);
    await prefs.setDouble('nameFontSize', _nameFontSize);
    await prefs.setDouble('descFontSize', _descFontSize);

    // CORRECCIÓN: Si es nulo, eliminamos el registro para que de verdad vuelva al de fábrica
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      await prefs.setString('imagePath', _imagePath!);
    } else {
      await prefs.remove('imagePath');
    }
  }

  void _startClock() {
    _updateTime();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
      _currentDate = DateFormat('EEEE, d MMM. yyyy', 'es_ES').format(now);
    });
  }

  void _startCloudAnimation() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _cloudPositionsX.length; i++) {
            _cloudPositionsX[i] -= 0.6 + (i % 2);
            if (_cloudPositionsX[i] < -130) {
              _cloudPositionsX[i] = MediaQuery.of(context).size.width + 100;
            }
          }
        });
      }
    });
  }

  Future<void> _navigateToConfig() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VistaConfiguracion(
          initialName: _userName,
          initialCode: _userCode,
          initialIdBanner: _idBanner,
          initialNameSize: _nameFontSize,
          initialDescSize: _descFontSize,
          initialImagePath: _imagePath,
        ),
      ),
    );

    // CORRECCIÓN AL RECIBIR LOS DATOS
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _userName = result['name'] ?? _userName;
        _userCode = result['code'] ?? _userCode;
        _idBanner = result['idBanner'] ?? _idBanner;
        _nameFontSize = result['nameSize'] ?? _nameFontSize;
        _descFontSize = result['descSize'] ?? _descFontSize;

        // El problema estaba aquí. Ahora forzamos a que acepte el null si viene en el mapa
        _imagePath = result['imagePath'];
      });
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final photoTopPosition = screenHeight * 0.38;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: Stack(
        children: [
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/arbolito.png', height: 350, fit: BoxFit.contain),
            ),
          ),
          ...List.generate(_cloudPositionsX.length, (index) {
            final cloudWidth = _cloudBaseSize + (index * _cloudSizeVariation);
            return Positioned(
              top: _cloudSpawnYBase + (index * _cloudSpawnYVariation),
              left: _cloudPositionsX[index],
              child: Opacity(
                opacity: 0.4,
                child: Image.asset('assets/cloud.png', width: cloudWidth),
              ),
            );
          }),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _navigateToConfig,
                        child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFE33E3E), size: 22),
                      ),
                      const SizedBox(width: 25),
                      Text(
                        'TIU VIRTUAL',
                        style: GoogleFonts.oswald(
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.black.withOpacity(0.09),
                ),
              ],
            ),
          ),
          Positioned(
            top: 135,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E3FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentTime,
                    style: GoogleFonts.roboto(fontSize: 42, fontWeight: FontWeight.w400, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _currentDate,
                  style: const TextStyle(fontSize: 17, color: Color(0xFF5C6B82), fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _userName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.oswald(
                        fontSize: _nameFontSize,
                        color: const Color(0xFFE33E3E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text("Código de alumno:", style: TextStyle(color: Color(0xFF6B778C), fontSize: 13)),
                  Text(
                    _userCode,
                    style: TextStyle(fontSize: _descFontSize, fontWeight: FontWeight.bold, color: const Color(0xFF344563)),
                  ),
                  const SizedBox(height: 8),
                  const Text("ID Banner:", style: TextStyle(color: Color(0xFF6B778C), fontSize: 13)),
                  Text(
                    _idBanner,
                    style: TextStyle(fontSize: _descFontSize, fontWeight: FontWeight.bold, color: const Color(0xFF344563)),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "INGENIERÍA DE SOFTWARE",
                    style: TextStyle(fontSize: _descFontSize, fontWeight: FontWeight.w800, color: const Color(0xFF344563)),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Color(0xFFE33E3E), size: 19),
                      SizedBox(width: 8),
                      Text(
                        "Campus San Miguel",
                        style: TextStyle(fontSize: 15, color: Color(0xFF6B778C), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: photoTopPosition,
            left: 0,
            right: 0,
            child: Center(
              child: ClipOval(
                child: _imagePath != null && File(_imagePath!).existsSync()
                    ? Image.file(
                  File(_imagePath!),
                  width: 175,
                  height: 175,
                  fit: BoxFit.cover,
                )
                    : Image.asset(
                  'assets/profile_picture.jpg',
                  width: 175,
                  height: 175,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}