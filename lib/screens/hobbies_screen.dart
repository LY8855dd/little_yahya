import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class HobbiesScreen extends StatefulWidget {
  const HobbiesScreen({super.key});

  @override
  State<HobbiesScreen> createState() => _HobbiesScreenState();
}

class _HobbiesScreenState extends State<HobbiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hobbies'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Photography'),
            Tab(text: 'Coffee'),
            Tab(text: 'Music'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addEntry(context, _typeForIndex(_tab.index)),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _HobbyList(type: HobbyType.photography),
          _HobbyList(type: HobbyType.coffee),
          _HobbyList(type: HobbyType.music),
        ],
      ),
    );
  }

  HobbyType _typeForIndex(int i) =>
      [HobbyType.photography, HobbyType.coffee, HobbyType.music][i];

  void _addEntry(BuildContext context, HobbyType type) {
    final title = TextEditingController();
    final notes = TextEditingController();
    final fieldControllers = <String, TextEditingController>{
      for (final f in _fieldsFor(type)) f: TextEditingController(),
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New ${_typeLabel(type)} entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title')),
              ...fieldControllers.entries.map((e) => TextField(
                    controller: e.value,
                    decoration: InputDecoration(labelText: e.key),
                  )),
              TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (title.text.trim().isEmpty) return;
              context.read<AppState>().addHobbyEntry(HobbyEntry(
                    type: type,
                    title: title.text.trim(),
                    fields: {
                      for (final e in fieldControllers.entries)
                        e.key: e.value.text.trim(),
                    },
                    notes: notes.text.trim(),
                  ));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

List<String> _fieldsFor(HobbyType type) {
  switch (type) {
    case HobbyType.photography:
      return ['Location', 'Film/camera', 'What you learned'];
    case HobbyType.coffee:
      return ['Origin', 'Process', 'Brew method', 'Tasting notes'];
    case HobbyType.music:
      return ['Country', 'Language', 'Mood'];
  }
}

String _typeLabel(HobbyType type) {
  switch (type) {
    case HobbyType.photography:
      return 'photography';
    case HobbyType.coffee:
      return 'coffee';
    case HobbyType.music:
      return 'music';
  }
}

class _HobbyList extends StatelessWidget {
  final HobbyType type;
  const _HobbyList({required this.type});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.hobbyEntriesOf(type);

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No ${_typeLabel(type)} entries yet. Tap + to log real evidence of progress.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final e = entries[i];
        return Card(
          child: ListTile(
            title: Text(e.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat.yMMMd().format(e.date)),
                ...e.fields.entries
                    .where((f) => f.value.isNotEmpty)
                    .map((f) => Text('${f.key}: ${f.value}')),
                if (e.notes.isNotEmpty) Text(e.notes),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              onPressed: () => context.read<AppState>().deleteHobbyEntry(e.id),
            ),
          ),
        );
      },
    );
  }
}
