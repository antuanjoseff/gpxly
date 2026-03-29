import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String sexo = 'M';
  int altura = 170;
  int peso = 70;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButton<String>(
              value: sexo,
              items: const [
                DropdownMenuItem(value: 'M', child: Text("Masculino")),
                DropdownMenuItem(value: 'F', child: Text("Femenino")),
              ],
              onChanged: (v) {
                setState(() {
                  sexo = v!;
                });
              },
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Altura (cm)"),
              onChanged: (v) => altura = int.tryParse(v) ?? altura,
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Peso (kg)"),
              onChanged: (v) => peso = int.tryParse(v) ?? peso,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Guardar perfil aquí o amb Riverpod després
                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }
}
