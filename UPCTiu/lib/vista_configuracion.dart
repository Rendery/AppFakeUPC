import 'package:flutter/material.dart';

class VistaConfiguracion extends StatefulWidget {
  final Function(String) onNameChanged;
  final Function(String) onCodeChanged;

  VistaConfiguracion({required this.onNameChanged, required this.onCodeChanged});

  @override
  _VistaConfiguracionState createState() => _VistaConfiguracionState();
}

class _VistaConfiguracionState extends State<VistaConfiguracion> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Cambiar Nombre'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: 'Cambiar Código'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onNameChanged(_nameController.text.toUpperCase());
                widget.onCodeChanged(_codeController.text.toUpperCase());
                Navigator.pop(context);
              },
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
