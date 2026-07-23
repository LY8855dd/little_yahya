import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class CommitmentScreen extends StatelessWidget {
  const CommitmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = state.commitment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commitment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openEditor(context, c),
          ),
        ],
      ),
      body: c == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pick the one thing that gives structure to everything else.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _openEditor(context, null),
                      child: const Text('Set primary commitment'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Result: ${c.result}'),
                        if (c.deadline != null) ...[
                          const SizedBox(height: 8),
                          Text(
                              'Deadline: ${DateFormat.yMMMd().format(c.deadline!)}'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('School-first mode'),
                        subtitle: const Text(
                            'Protects school time above everything else'),
                        value: c.mode == CommitmentMode.schoolFirst,
                        onChanged: (v) {
                          c.mode = v
                              ? CommitmentMode.schoolFirst
                              : CommitmentMode.normal;
                          state.setCommitment(c);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Milestones', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...c.milestones.map((m) => Card(
                      child: CheckboxListTile(
                        title: Text(
                          m.title,
                          style: TextStyle(
                            decoration:
                                m.done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(DateFormat.yMMMd().format(m.dueDate)),
                        value: m.done,
                        onChanged: (_) => state.toggleMilestone(m.id),
                      ),
                    )),
                TextButton.icon(
                  onPressed: () => _addMilestone(context, c),
                  icon: const Icon(Icons.add),
                  label: const Text('Add milestone'),
                ),
                const SizedBox(height: 16),
                Text('If things change',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      c.contingencyPlan.isEmpty
                          ? 'No plan set for what happens if you move or school starts. Add one via edit.'
                          : c.contingencyPlan,
                      style: TextStyle(
                        color: c.contingencyPlan.isEmpty
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _addMilestone(BuildContext context, Commitment c) {
    final controller = TextEditingController();
    DateTime due = DateTime.now().add(const Duration(days: 7));
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add milestone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Milestone title'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Due: ${DateFormat.yMMMd().format(due)}'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: due,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) setState(() => due = picked);
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                c.milestones.add(Milestone(title: controller.text.trim(), dueDate: due));
                context.read<AppState>().setCommitment(c);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, Commitment? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => _CommitmentEditor(existing: existing),
    );
  }
}

class _CommitmentEditor extends StatefulWidget {
  final Commitment? existing;
  const _CommitmentEditor({this.existing});

  @override
  State<_CommitmentEditor> createState() => _CommitmentEditorState();
}

class _CommitmentEditorState extends State<_CommitmentEditor> {
  late TextEditingController title;
  late TextEditingController result;
  late TextEditingController contingency;
  DateTime? deadline;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    title = TextEditingController(text: e?.title ?? '');
    result = TextEditingController(text: e?.result ?? '');
    contingency = TextEditingController(text: e?.contingencyPlan ?? '');
    deadline = e?.deadline;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existing == null ? 'Set primary commitment' : 'Edit commitment',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'What is it?'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: result,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'What does "done" look like?'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(deadline == null
                    ? 'No deadline set'
                    : 'Deadline: ${DateFormat.yMMMd().format(deadline!)}'),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: deadline ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => deadline = picked);
                  },
                  child: const Text('Pick date'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contingency,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'If you move or school starts, then what?'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (title.text.trim().isEmpty) return;
                  final c = widget.existing ??
                      Commitment(title: '', result: '');
                  c.title = title.text.trim();
                  c.result = result.text.trim();
                  c.contingencyPlan = contingency.text.trim();
                  c.deadline = deadline;
                  context.read<AppState>().setCommitment(c);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
