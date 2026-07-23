import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late TextEditingController _taskController;
  late DailyCheckIn _checkIn;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _checkIn = state.checkInFor(DateTime.now());
    _taskController = TextEditingController(text: _checkIn.mostImportantTask);
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _save() {
    context.read<AppState>().saveCheckIn(_checkIn);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final commitment = state.commitment;

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.returningAfterGap) _ReturnBanner(state: state),
          _CommitmentCard(commitment: commitment),
          const SizedBox(height: 16),
          Text('What is the most important thing you need to move forward today?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _taskController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'One task. Be specific.',
            ),
            onChanged: (v) => _checkIn.mostImportantTask = v,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _checkIn.mostImportantDone,
                onChanged: (v) {
                  setState(() => _checkIn.mostImportantDone = v ?? false);
                  _save();
                },
              ),
              const Text('Done'),
              const Spacer(),
              TextButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  color: state.currentStreak > 0
                      ? AppTheme.warn
                      : AppTheme.textSecondary,
                  size: 18),
              const SizedBox(width: 4),
              Text('${state.currentStreak} day streak'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Body & mind check-in',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _RatingRow(
            label: 'Sleep (hours)',
            value: _checkIn.sleepHours,
            max: 12,
            onChanged: (v) {
              setState(() => _checkIn.sleepHours = v);
              _save();
            },
          ),
          _RatingRow(
            label: 'Food quality',
            value: _checkIn.foodQuality,
            max: 5,
            onChanged: (v) {
              setState(() => _checkIn.foodQuality = v);
              _save();
            },
          ),
          _RatingRow(
            label: 'Mindset',
            value: _checkIn.mindset,
            max: 5,
            onChanged: (v) {
              setState(() => _checkIn.mindset = v);
              _save();
            },
          ),
        ],
      ),
    );
  }
}

class _ReturnBanner extends StatelessWidget {
  final AppState state;
  const _ReturnBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceAlt,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("You've been away a few days.",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
                'Nothing is broken. Answer honestly: does the commitment below still matter? If yes, pick one next action today.'),
          ],
        ),
      ),
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  final Commitment? commitment;
  const _CommitmentCard({required this.commitment});

  @override
  Widget build(BuildContext context) {
    if (commitment == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No primary commitment set.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                  'Everything else in this app orbits one thing. Set it on the Commitment tab.'),
            ],
          ),
        ),
      );
    }
    final c = commitment!;
    final daysLeft = c.deadline?.difference(DateTime.now()).inDays;
    final totalMilestones = c.milestones.length;
    final doneMilestones = c.milestones.where((m) => m.done).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                if (c.mode == CommitmentMode.schoolFirst)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('School-first',
                        style: TextStyle(fontSize: 12, color: AppTheme.accent)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(c.result, style: const TextStyle(color: AppTheme.textSecondary)),
            if (daysLeft != null) ...[
              const SizedBox(height: 8),
              Text(
                daysLeft >= 0 ? '$daysLeft days left' : '${-daysLeft} days overdue',
                style: TextStyle(
                    color: daysLeft < 0 ? AppTheme.danger : AppTheme.warn),
              ),
            ],
            if (totalMilestones > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: doneMilestones / totalMilestones,
                backgroundColor: AppTheme.surfaceAlt,
                color: AppTheme.accent,
              ),
              const SizedBox(height: 4),
              Text('$doneMilestones / $totalMilestones milestones'),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final int? value;
  final int max;
  final ValueChanged<int> onChanged;

  const _RatingRow({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: List.generate(max, (i) {
                final v = i + 1;
                final selected = value == v;
                return GestureDetector(
                  onTap: () => onChanged(v),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.accent : AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$v',
                        style: TextStyle(
                            color: selected ? Colors.black : AppTheme.textPrimary,
                            fontSize: 12)),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
