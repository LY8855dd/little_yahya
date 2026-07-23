import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'storage_service.dart';

String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

class AppState extends ChangeNotifier {
  final StorageService storage;

  Commitment? commitment;
  Map<String, DailyCheckIn> checkIns = {};
  List<Recipe> recipes = [];
  List<MoneyEntry> moneyEntries = [];
  List<SavingsDeposit> savingsDeposits = [];
  List<HobbyEntry> hobbyEntries = [];
  double monthlySavingsGoalSar = 1000;
  DateTime? lastOpenedAt;

  static const _kCommitment = 'commitment';
  static const _kCheckIns = 'checkIns';
  static const _kRecipes = 'recipes';
  static const _kMoney = 'moneyEntries';
  static const _kSavings = 'savingsDeposits';
  static const _kHobbies = 'hobbyEntries';
  static const _kSavingsGoal = 'monthlySavingsGoal';
  static const _kLastOpened = 'lastOpenedAt';

  AppState(this.storage) {
    _load();
  }

  void _load() {
    final c = storage.readMap(_kCommitment);
    if (c != null) commitment = Commitment.fromJson(c);

    final ci = storage.readMap(_kCheckIns);
    if (ci != null) {
      checkIns = ci.map(
        (k, v) => MapEntry(k, DailyCheckIn.fromJson(v as Map<String, dynamic>)),
      );
    }

    recipes = storage
        .readList(_kRecipes)
        .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
        .toList();

    moneyEntries = storage
        .readList(_kMoney)
        .map((m) => MoneyEntry.fromJson(m as Map<String, dynamic>))
        .toList();

    savingsDeposits = storage
        .readList(_kSavings)
        .map((s) => SavingsDeposit.fromJson(s as Map<String, dynamic>))
        .toList();

    hobbyEntries = storage
        .readList(_kHobbies)
        .map((h) => HobbyEntry.fromJson(h as Map<String, dynamic>))
        .toList();

    final goalRaw = storage.readString(_kSavingsGoal);
    if (goalRaw != null) monthlySavingsGoalSar = double.tryParse(goalRaw) ?? 1000;

    final lastOpenedRaw = storage.readString(_kLastOpened);
    lastOpenedAt = lastOpenedRaw != null ? DateTime.tryParse(lastOpenedRaw) : null;

    // record this open, after capturing the previous value above
    storage.writeString(_kLastOpened, DateTime.now().toIso8601String());

    notifyListeners();
  }

  // ---- Commitment ----
  void setCommitment(Commitment c) {
    commitment = c;
    storage.writeMap(_kCommitment, c.toJson());
    notifyListeners();
  }

  void toggleMilestone(String milestoneId) {
    final c = commitment;
    if (c == null) return;
    final m = c.milestones.firstWhere((m) => m.id == milestoneId);
    m.done = !m.done;
    storage.writeMap(_kCommitment, c.toJson());
    notifyListeners();
  }

  // ---- Daily check-in ----
  DailyCheckIn checkInFor(DateTime date) {
    final key = dateKey(date);
    return checkIns[key] ?? DailyCheckIn(dateKey: key);
  }

  void saveCheckIn(DailyCheckIn checkIn) {
    checkIns[checkIn.dateKey] = checkIn;
    storage.writeMap(
      _kCheckIns,
      checkIns.map((k, v) => MapEntry(k, v.toJson())),
    );
    notifyListeners();
  }

  int get currentStreak {
    int streak = 0;
    var d = DateTime.now();
    while (true) {
      final ci = checkIns[dateKey(d)];
      if (ci != null && ci.mostImportantDone) {
        streak++;
        d = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ---- Recipes ----
  void _persistRecipes() {
    storage.writeList(_kRecipes, recipes.map((r) => r.toJson()).toList());
  }

  void addRecipe(Recipe r) {
    recipes.add(r);
    _persistRecipes();
    notifyListeners();
  }

  void addRecipeVersion(String recipeId, RecipeVersion v) {
    final r = recipes.firstWhere((r) => r.id == recipeId);
    r.versions.add(v);
    _persistRecipes();
    notifyListeners();
  }

  void deleteRecipe(String recipeId) {
    recipes.removeWhere((r) => r.id == recipeId);
    _persistRecipes();
    notifyListeners();
  }

  // ---- Money ----
  void addMoneyEntry(MoneyEntry e) {
    moneyEntries.add(e);
    storage.writeList(_kMoney, moneyEntries.map((m) => m.toJson()).toList());
    notifyListeners();
  }

  void deleteMoneyEntry(String id) {
    moneyEntries.removeWhere((m) => m.id == id);
    storage.writeList(_kMoney, moneyEntries.map((m) => m.toJson()).toList());
    notifyListeners();
  }

  void addSavingsDeposit(SavingsDeposit d) {
    savingsDeposits.add(d);
    storage.writeList(
        _kSavings, savingsDeposits.map((s) => s.toJson()).toList());
    notifyListeners();
  }

  void setSavingsGoal(double goal) {
    monthlySavingsGoalSar = goal;
    storage.writeString(_kSavingsGoal, goal.toString());
    notifyListeners();
  }

  double get thisMonthFastFoodSpend {
    final now = DateTime.now();
    return moneyEntries
        .where((m) =>
            m.category == SpendCategory.fastFood &&
            m.date.year == now.year &&
            m.date.month == now.month)
        .fold(0.0, (sum, m) => sum + m.amountSar);
  }

  double get thisMonthSavings {
    final now = DateTime.now();
    return savingsDeposits
        .where((s) => s.date.year == now.year && s.date.month == now.month)
        .fold(0.0, (sum, s) => sum + s.amountSar);
  }

  // ---- Hobbies ----
  void addHobbyEntry(HobbyEntry e) {
    hobbyEntries.add(e);
    storage.writeList(
        _kHobbies, hobbyEntries.map((h) => h.toJson()).toList());
    notifyListeners();
  }

  void deleteHobbyEntry(String id) {
    hobbyEntries.removeWhere((h) => h.id == id);
    storage.writeList(
        _kHobbies, hobbyEntries.map((h) => h.toJson()).toList());
    notifyListeners();
  }

  List<HobbyEntry> hobbyEntriesOf(HobbyType type) =>
      hobbyEntries.where((h) => h.type == type).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  int get hobbyEntriesThisWeek {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return hobbyEntries.where((h) => h.date.isAfter(weekAgo)).length;
  }

  int get recipeVersionsLogged =>
      recipes.fold(0, (sum, r) => sum + r.versions.length);

  double get thisWeekMoneySpend {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return moneyEntries
        .where((m) => m.date.isAfter(weekAgo))
        .fold(0.0, (sum, m) => sum + m.amountSar);
  }

  // ---- Re-entry ----
  bool get returningAfterGap {
    if (lastOpenedAt == null) return false;
    return DateTime.now().difference(lastOpenedAt!).inDays >= 3;
  }
}
