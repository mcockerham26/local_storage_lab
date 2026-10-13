
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models/folder.dart';
import 'models/card_record.dart';

class FoldersScreen extends StatefulWidget {
  final DatabaseHelper database;

  const FoldersScreen({
    super.key,
    required this.database,
  });

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Folder> folders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  Future<void> loadFolders() async {
    try {
      final rows = await widget.database.getFolders();
      if (!mounted) return;
      setState(() {
        folders = rows.map(Folder.fromMap).toList();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage('Error loading folders: $error');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> addFolder() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      await widget.database.insertFolder(name);
      await loadFolders();
      showMessage('Folder created!');
    } catch (error) {
      showMessage('Could not create folder: $error');
    }
  }

  Future<void> deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
          'Delete "${folder.name}" and its cards?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || folder.id == null) return;

    try {
      await widget.database.deleteFolder(folder.id!);
      await loadFolders();
      showMessage('Folder deleted');
    } catch (error) {
      showMessage('Could not delete folder: $error');
    }
  }

  Future<void> openFolder(Folder folder) async {
    if (folder.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardsScreen(
          database: widget.database,
          folder: folder,
        ),
      ),
    );

    await loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Card Folders'),
        backgroundColor: Colors.deepPurple.shade100,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addFolder,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : folders.isEmpty
          ? const Center(
        child: Text(
          'No folders yet. Tap + to add one.',
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];

          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.folder,
                color: Colors.deepPurple,
              ),
              title: Text(folder.name),
              subtitle: Text(
                '${folder.cardCount} cards',
              ),
              onTap: () => openFolder(folder),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                ),
                onPressed: () => deleteFolder(folder),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final DatabaseHelper database;
  final Folder folder;

  const CardsScreen({
    super.key,
    required this.database,
    required this.folder,
  });

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<CardRecord> cards = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  Future<void> loadCards() async {
    try {
      final rows = await widget.database.getCards(
        widget.folder.id!,
      );

      if (!mounted) return;
      setState(() {
        cards = rows.map(CardRecord.fromMap).toList();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage('Error loading cards: $error');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> editCard([CardRecord? existing]) async {
    final titleController = TextEditingController(
      text: existing?.title ?? '',
    );
    final notesController = TextEditingController(
      text: existing?.notes ?? '',
    );
    final imageController = TextEditingController(
      text: existing?.imageRef ?? '',
    );
    String suit = existing?.suit ?? 'Hearts';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Add Card' : 'Edit Card',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Card Title',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: suit,
                  decoration: const InputDecoration(
                    labelText: 'Suit',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Hearts',
                      child: Text('Hearts'),
                    ),
                    DropdownMenuItem(
                      value: 'Diamonds',
                      child: Text('Diamonds'),
                    ),
                    DropdownMenuItem(
                      value: 'Clubs',
                      child: Text('Clubs'),
                    ),
                    DropdownMenuItem(
                      value: 'Spades',
                      child: Text('Spades'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => suit = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'Image Reference (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                Navigator.pop(dialogContext, {
                  'title': title,
                  'suit': suit,
                  'notes': notesController.text.trim(),
                  'image_ref':
                  imageController.text.trim().isEmpty
                      ? null
                      : imageController.text.trim(),
                  'folder_id': widget.folder.id!,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      if (existing == null) {
        await widget.database.insertCard(result);
      } else {
        await widget.database.updateCard(
          existing.id!,
          result,
        );
      }
      await loadCards();
      showMessage('Card saved!');
    } catch (error) {
      showMessage('Could not save card: $error');
    }
  }

  Future<void> deleteCard(CardRecord card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Card?'),
        content: Text('Delete "${card.title}"?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || card.id == null) return;

    try {
      await widget.database.deleteCard(card.id!);
      await loadCards();
      showMessage('Card deleted');
    } catch (error) {
      showMessage('Could not delete card: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
        backgroundColor: Colors.deepPurple.shade100,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => editCard(),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cards.isEmpty
          ? const Center(
        child: Text(
          'No cards yet. Tap + to add one.',
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];

          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.style,
                color: Colors.deepPurple,
              ),
              title: Text(card.title),
              subtitle: Text(
                '${card.suit}\n${card.notes}',
              ),
              isThreeLine: true,
              onTap: () => editCard(card),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                ),
                onPressed: () => deleteCard(card),
              ),
            ),
          );
        },
      ),
    );
  }
}
