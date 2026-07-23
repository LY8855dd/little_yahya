import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addRecipe(context),
          ),
        ],
      ),
      body: state.recipes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Start with your first homemade version of something you usually buy.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _addRecipe(context),
                      child: const Text('Add a recipe'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.recipes.length,
              itemBuilder: (ctx, i) => _RecipeCard(recipe: state.recipes[i]),
            ),
    );
  }

  void _addRecipe(BuildContext context) {
    final name = TextEditingController();
    final equiv = TextEditingController();
    final cost = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New recipe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration:
                    const InputDecoration(labelText: 'Name (e.g. Popeyes-style wrap)')),
            TextField(
                controller: equiv,
                decoration: const InputDecoration(
                    labelText: 'Fast food it replaces (optional)')),
            TextField(
              controller: cost,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Fast food cost, SAR (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              context.read<AppState>().addRecipe(Recipe(
                    name: name.text.trim(),
                    fastFoodEquivalent: equiv.text.trim(),
                    fastFoodCostSar: double.tryParse(cost.text.trim()) ?? 0,
                  ));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final latest = recipe.versions.isEmpty ? null : recipe.versions.last;
    final avgCost = recipe.versions.isEmpty
        ? 0
        : recipe.versions.map((v) => v.costSar).reduce((a, b) => a + b) /
            recipe.versions.length;
    final savings = recipe.fastFoodCostSar > 0 && recipe.versions.isNotEmpty
        ? recipe.fastFoodCostSar - avgCost
        : null;

    return Card(
      child: ExpansionTile(
        title: Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(latest == null
            ? 'No versions logged yet'
            : 'v${latest.versionNumber} · taste ${latest.tasteRating}/10 · ${latest.costSar.toStringAsFixed(0)} SAR'),
        children: [
          if (savings != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  savings >= 0
                      ? 'Saving ~${savings.toStringAsFixed(0)} SAR vs ${recipe.fastFoodEquivalent.isEmpty ? 'fast food' : recipe.fastFoodEquivalent}'
                      : 'Costing ~${(-savings).toStringAsFixed(0)} SAR more than fast food — still worth it for taste/health, or adjust recipe',
                  style: TextStyle(
                      color: savings >= 0 ? AppTheme.accent : AppTheme.warn),
                ),
              ),
            ),
          ...recipe.versions.reversed.map((v) => ListTile(
                dense: true,
                title: Text('v${v.versionNumber} — ${DateFormat.MMMd().format(v.date)}'),
                subtitle: Text(
                    '${v.changesFromLast.isEmpty ? "No notes on changes" : v.changesFromLast}\nTaste ${v.tasteRating}/10 · ${v.costSar.toStringAsFixed(0)} SAR'),
                isThreeLine: true,
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _addVersion(context, recipe),
                  icon: const Icon(Icons.add),
                  label: const Text('Log a version'),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                  onPressed: () =>
                      context.read<AppState>().deleteRecipe(recipe.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addVersion(BuildContext context, Recipe recipe) {
    final changes = TextEditingController();
    final cost = TextEditingController();
    final notes = TextEditingController();
    double taste = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Log version for ${recipe.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: changes,
                  decoration: const InputDecoration(
                      labelText: 'What changed from last time?'),
                ),
                TextField(
                  controller: cost,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cost, SAR'),
                ),
                const SizedBox(height: 8),
                Text('Taste: ${taste.toInt()}/10'),
                Slider(
                  value: taste,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (v) => setState(() => taste = v),
                ),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Other notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                context.read<AppState>().addRecipeVersion(
                      recipe.id,
                      RecipeVersion(
                        versionNumber: recipe.versions.length + 1,
                        changesFromLast: changes.text.trim(),
                        tasteRating: taste.toInt(),
                        costSar: double.tryParse(cost.text.trim()) ?? 0,
                        notes: notes.text.trim(),
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
