import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:upctiu/main.dart';
import 'package:upctiu/perfil.dart';
import 'package:upctiu/vista_tiu.dart';

void main() {
  Future<void> abrirApp(WidgetTester tester, Map<String, Object> datos) async {
    SharedPreferences.setMockInitialValues(datos);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MyApp(prefs: prefs));
  }

  testWidgets('Sin datos guardados el TIU arranca vacío', (WidgetTester tester) async {
    await abrirApp(tester, {});

    expect(find.text('TIU VIRTUAL'), findsOneWidget);
    expect(find.text('TU TIU ESTÁ VACÍO'), findsOneWidget);
    expect(find.text('Ingresar datos'), findsOneWidget);
    expect(find.text('Importar perfil'), findsOneWidget);

    // Desmonta la pantalla para que se cancelen los timers del reloj.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Con datos guardados el TIU muestra el perfil', (WidgetTester tester) async {
    await abrirApp(tester, {
      'userName': 'ANA PÉREZ',
      'userCode': '202312345',
      'idBanner': 'N00000001',
      'carrera': 'ARQUITECTURA',
      'campus': 'Campus Monterrico',
    });

    expect(find.text('ANA PÉREZ'), findsOneWidget);
    expect(find.text('202312345'), findsOneWidget);
    expect(find.text('N00000001'), findsOneWidget);
    expect(find.text('ARQUITECTURA'), findsOneWidget);
    expect(find.text('Campus Monterrico'), findsOneWidget);
    expect(find.text('TU TIU ESTÁ VACÍO'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  test('Exportar e importar un perfil conserva sus datos', () async {
    const original = Perfil(
      id: 'x',
      nombrePerfil: 'Principal',
      nombre: 'ANA PÉREZ',
      codigo: '202312345',
      idBanner: 'N00000001',
      carrera: 'ARQUITECTURA',
      campus: 'Campus Monterrico',
      nameSize: 30,
      descSize: 16,
    );

    final bytes = await PerfilArchivo.codificar([original]);
    final importados = await PerfilArchivo.decodificar(bytes);

    expect(importados, hasLength(1));
    final p = importados.single;
    expect(p.nombrePerfil, 'Principal');
    expect(p.nombre, 'ANA PÉREZ');
    expect(p.codigo, '202312345');
    expect(p.idBanner, 'N00000001');
    expect(p.carrera, 'ARQUITECTURA');
    expect(p.campus, 'Campus Monterrico');
    expect(p.nameSize, 30);
    expect(p.descSize, 16);
    expect(p.imagePath, isNull);
    expect(p.id, isNotEmpty);
  });

  test('Importar un archivo que no es de la app falla con un mensaje', () async {
    final otro = Uint8List.fromList(utf8.encode('{"hola": 1}'));
    expect(() => PerfilArchivo.decodificar(otro), throwsFormatException);

    final roto = Uint8List.fromList(utf8.encode('no es json'));
    expect(() => PerfilArchivo.decodificar(roto), throwsFormatException);
  });

  test('Hora y fecha en español con el mismo formato que antes', () {
    final t = DateTime(2026, 10, 31, 2, 8, 5);
    expect(formatearHora(t), '02:08:05');
    expect(formatearFecha(t), 'sábado, 31 oct. 2026');
    expect(formatearFecha(DateTime(2026, 9, 2)), 'miércoles, 2 sept. 2026');
    expect(formatearFecha(DateTime(2027, 1, 3)), 'domingo, 3 ene. 2027');
  });

  testWidgets('Avisa que el TIU está listo para el primer frame', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'userName': 'ANA PÉREZ'});
    final prefs = await SharedPreferences.getInstance();
    var avisos = 0;

    await tester.pumpWidget(MyApp(prefs: prefs, alEstarListo: () => avisos++));
    // Aunque las imágenes no terminen de decodificarse, el aviso llega como máximo a los 400 ms
    await tester.pump(const Duration(milliseconds: 500));
    expect(avisos, 1);

    await tester.pumpWidget(const SizedBox());
  });
}
