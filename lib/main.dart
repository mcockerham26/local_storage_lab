
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'folders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = DatabaseHelper();

  try {
    await database.init();
    runApp(GuestApp(database: database));
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Database error: $error'),
          ),
        ),
      ),
    );
  }
}

class GuestApp extends StatelessWidget {
  final DatabaseHelper database;

  const GuestApp({
    super.key,
    required this.database,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fall Festival Roster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: GuestScreen(database: database),
    );
  }
}

class GuestScreen extends StatefulWidget {
  final DatabaseHelper database;

  const GuestScreen({
    super.key,
    required this.database,
  });

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();

  List<Map<String, dynamic>> guests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadGuests();
  }

  Future<void> loadGuests() async {
    try {
      final rows = await widget.database.queryAllRows();

      if (!mounted) return;

      setState(() {
        guests = rows;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> addGuest() async {
    final name = nameController.text.trim();
    final age = int.tryParse(ageController.text.trim());

    if (name.isEmpty ||
        age == null ||
        age < 0 ||
        age > 130) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid name and age.'),
        ),
      );
      return;
    }

    try {
      await widget.database.insert({
        DatabaseHelper.columnName: name,
        DatabaseHelper.columnAge: age,
      });

      nameController.clear();
      ageController.clear();

      if (!mounted) return;
      FocusScope.of(context).unfocus();

      await loadGuests();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  void openFolders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoldersScreen(
          database: widget.database,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Festival Roster'),
        backgroundColor: Colors.deepPurple.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Guest Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: addGuest,
              child: const Text('Add Guest'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openFolders,
                icon: const Icon(Icons.folder_open),
                label: const Text('My Card Folders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Guests: ${guests.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            if (loading)
              const CircularProgressIndicator()
            else if (guests.isEmpty)
              const Text('No festival guests yet')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: guests.length,
                  itemBuilder: (context, index) {
                    final guest = guests[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text('${guest['name']}'),
                        subtitle: Text(
                          'ID: ${guest['_id']} | Age: ${guest['age']}',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
