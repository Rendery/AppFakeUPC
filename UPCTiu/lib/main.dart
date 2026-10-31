import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // IMPORTACIÓN NECESARIA PARA LA BARRA DE NAVEGACIÓN
import 'package:shared_preferences/shared_preferences.dart';
import 'vista_tiu.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // El splash nativo se queda hasta que el TIU está completo (datos leídos y fotos
  // decodificadas): lo primero que se ve es el TIU ya cargado, sin pantallas a medias.
  binding.deferFirstFrame();

  // CONFIGURACIÓN DE BARRA DE NAVEGACIÓN DEL SISTEMA (NAV-BAR) TRANSPARENTE
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent, // Barra de navegación transparente
    statusBarColor: Colors.transparent, // Barra de estado transparente si se desea
    systemNavigationBarIconBrightness: Brightness.dark, // Iconos oscuros para fondo claro
    statusBarIconBrightness: Brightness.dark, // Iconos oscuros para fondo claro
  ));

  // Única espera antes de dibujar: los datos guardados del TIU
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs, alEstarListo: binding.allowFirstFrame));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  // Se llama cuando el TIU ya puede mostrarse (libera el primer frame)
  final VoidCallback? alEstarListo;

  const MyApp({super.key, required this.prefs, this.alEstarListo});

  static final ThemeData _theme = ThemeData(
    useMaterial3: true,
    // Poppins va declarada en pubspec.yaml: está registrada desde el arranque
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPC TIU Virtual',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      home: VistaTIU(prefs: prefs, alEstarListo: alEstarListo),
    );
  }
}
