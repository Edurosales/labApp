import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'db/database_helper.dart';
import 'models/dog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // obligatorio antes de usar DB
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dogs SQLite',
      home: kIsWeb ? const WebUnsupportedPage() : const DogsPage(),
    );
  }
}

class WebUnsupportedPage extends StatelessWidget {
  const WebUnsupportedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Esta app usa SQLite local con sqflite y en Chrome no está soportado de forma directa.\n\nEjecuta la app en Android, iOS, Windows, macOS o Linux, o cambia la capa de almacenamiento para web.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class DogsPage extends StatefulWidget {
  const DogsPage({super.key});

  @override
  State<DogsPage> createState() => _DogsPageState();
}

class _DogsPageState extends State<DogsPage> {
  final db = DatabaseHelper.instance;
  List<Dog> dogs = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    try {
      final list = await db.getDogs();
      if (!mounted) return;
      setState(() {
        dogs = list;
        loading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = 'No se pudo cargar la base de datos: $error';
      });
    }
  }

  Future<void> _showDogDialog({Dog? dog}) async {
    final nameController = TextEditingController(text: dog?.name ?? '');
    final ageController = TextEditingController(
      text: dog?.age.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dog == null ? 'Agregar perro' : 'Editar perro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Edad'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final age = int.tryParse(ageController.text.trim());

                if (name.isEmpty || age == null) {
                  return;
                }

                if (dog == null) {
                  await db.insertDog(
                    Dog(
                      id: DateTime.now().millisecondsSinceEpoch,
                      name: name,
                      age: age,
                    ),
                  );
                } else {
                  await db.updateDog(Dog(id: dog.id, name: name, age: age));
                }

                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                await _loadDogs();
              },
              child: Text(dog == null ? 'Guardar' : 'Actualizar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addDog() async {
    await _showDogDialog();
  }

  Future<void> _deleteDog(int id) async {
    await db.deleteDog(id);
    await _loadDogs();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dogs')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorMessage!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dogs CRUD')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: dogs.length,
        itemBuilder: (ctx, i) {
          final dog = dogs[i];

          return ListTile(
            onTap: () => _showDogDialog(dog: dog),
            title: Text(dog.name),
            subtitle: Text('Edad: ${dog.age}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showDogDialog(dog: dog),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteDog(dog.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
