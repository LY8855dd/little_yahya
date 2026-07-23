import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class TodayScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const TodayScreen({super.key, this.onNavigate});

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
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (state.returningAfterGap) ...[
            _ReturnBanner(state: state),
            const SizedBox(height: 14),
          ],
          _CommitmentHero(commitment: commitment),
          const SizedBox(height: 16),
          _DashboardGrid(state: state, onNavigate: widget.onNavigate),
          const SizedBox(height: 24),
          const SectionHeader(title: "TODAY'S ONE THING"),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _checkIn.mostImportantDone
                    ? AppTheme.accent
                    : Colors.white.withValues(alpha: 0.06),
                width: _checkIn.mostImportantDone ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What is the most important thing you need to move forward today?',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _taskController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'One task. Be specific.',
                  ),
                  onChanged: (v) => _checkIn.mostImportantTask = v,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() =>
                            _checkIn.mostImportantDone = !_checkIn.mostImportantDone);
                        _save();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _checkIn.mostImportantDone
                              ? AppTheme.accent
                              : AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _checkIn.mostImportantDone
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: _checkIn.mostImportantDone
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _checkIn.mostImportantDone ? 'Done' : 'Mark done',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _checkIn.mostImportantDone
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(onPressed: _save, child: const Text('Save')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'BODY & MIND CHECK-IN'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _RatingRow(
                  label: 'Sleep (hrs)',
                  value: _checkIn.sleepHours,
                  max: 12,
                  onChanged: (v) {
                    setState(() => _checkIn.sleepHours = v);
                    _save();
                  },
                ),
                const Divider(height: 1, color: AppTheme.surfaceAlt),
                _RatingRow(
                  label: 'Food',
                  value: _checkIn.foodQuality,
                  max: 5,
                  onChanged: (v) {
                    setState(() => _checkIn.foodQuality = v);
                    _save();
                  },
                ),
                const Divider(height: 1, color: AppTheme.surfaceAlt),
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
          ),
        ],
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  final AppState state;
  final ValueChanged<int>? onNavigate;
  const _DashboardGrid({required this.state, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final streakActive = state.currentStreak > 0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${state.currentStreak}d',
                color: streakActive ? AppTheme.accentGold : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.savings,
                label: 'Saved this month',
                value: '${state.thisMonthSavings.toStringAsFixed(0)} SAR',
                color: AppTheme.violet,
                onTap: () => onNavigate?.call(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.fastfood,
                label: 'Fast food this month',
                value: '${state.thisMonthFastFoodSpend.toStringAsFixed(0)} SAR',
                color: AppTheme.warn,
                onTap: () => onNavigate?.call(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.restaurant,
                label: 'Recipe versions',
                value: '${state.recipeVersionsLogged}',
                color: AppTheme.accent,
                onTap: () => onNavigate?.call(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.camera_alt,
                label: 'Hobby entries this week',
                value: '${state.hobbyEntriesThisWeek}',
                color: AppTheme.violet,
                onTap: () => onNavigate?.call(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.flag,
                label: 'Milestones done',
                value: state.commitment == null
                    ? '—'
                    : '${state.commitment!.milestones.where((m) => m.done).length}/${state.commitment!.milestones.length}',
                color: AppTheme.accent,
                onTap: () => onNavigate?.call(1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: AppTheme.textSecondary, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _ReturnBanner extends StatelessWidget {
  final AppState state;
  const _ReturnBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.violet.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.violet.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_twilight, color: AppTheme.violet, size: 20),
              const SizedBox(width: 8),
              const Text("You've been away a few days.",
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
              'Nothing is broken. Answer honestly: does the commitment below still matter? If yes, pick one next action today.'),
        ],
      ),
    );
  }
}

class _CommitmentHero extends StatelessWidget {
  final Commitment? commitment;
  const _CommitmentHero({required this.commitment});

  @override
  Widget build(BuildContext context) {
    if (commitment == null) {
      return GradientCard(
        gradient: AppTheme.violetGradient,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No primary commitment set',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            SizedBox(height: 8),
            Text(
              'Everything else in this app orbits one thing. Set it on the Commitment tab.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    final c = commitment!;
    final daysLeft = c.deadline?.difference(DateTime.now()).inDays;
    final totalMilestones = c.milestones.length;
    final doneMilestones = c.milestones.where((m) => m.done).length;

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 22, height: 1.1)),
              ),
              if (c.mode == CommitmentMode.schoolFirst)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('SCHOOL-FIRST',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(c.result, style: const TextStyle(color: Colors.white70, height: 1.3)),
          if (daysLeft != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                daysLeft >= 0 ? '$daysLeft DAYS LEFT' : '${-daysLeft} DAYS OVERDUE',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
            ),
          ],
          if (totalMilestones > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: doneMilestones / totalMilestones,
                backgroundColor: Colors.black.withValues(alpha: 0.25),
                color: Colors.white,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text('$doneMilestones / $totalMilestones milestones',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: List.generate(max, (i) {
                final v = i + 1;
                final selected = value == v;
                return GestureDetector(
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: selected ? AppTheme.heroGradient : null,
                      color: selected ? null : AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$v',
                        style: TextStyle(
                            color: selected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.w800,
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
