import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum CommitmentMode { normal, schoolFirst }

class Milestone {
  String id;
  String title;
  DateTime dueDate;
  bool done;

  Milestone({
    String? id,
    required this.title,
    required this.dueDate,
    this.done = false,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dueDate': dueDate.toIso8601String(),
        'done': done,
      };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'],
        title: json['title'],
        dueDate: DateTime.parse(json['dueDate']),
        done: json['done'] ?? false,
      );
}

class Commitment {
  String id;
  String title;
  String result; // clear definition of "done"
  DateTime? deadline;
  String contingencyPlan; // what happens if move / school starts
  List<Milestone> milestones;
  CommitmentMode mode;
  DateTime createdAt;

  Commitment({
    String? id,
    required this.title,
    required this.result,
    this.deadline,
    this.contingencyPlan = '',
    List<Milestone>? milestones,
    this.mode = CommitmentMode.normal,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        milestones = milestones ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'result': result,
        'deadline': deadline?.toIso8601String(),
        'contingencyPlan': contingencyPlan,
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'mode': mode.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Commitment.fromJson(Map<String, dynamic> json) => Commitment(
        id: json['id'],
        title: json['title'],
        result: json['result'],
        deadline:
            json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
        contingencyPlan: json['contingencyPlan'] ?? '',
        milestones: (json['milestones'] as List? ?? [])
            .map((m) => Milestone.fromJson(m))
            .toList(),
        mode: CommitmentMode.values.firstWhere(
          (e) => e.name == json['mode'],
          orElse: () => CommitmentMode.normal,
        ),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class DailyCheckIn {
  String dateKey; // yyyy-MM-dd
  String? mostImportantTask;
  bool mostImportantDone;
  int? sleepHours;
  int? foodQuality; // 1-5, self rated
  int? mindset; // 1-5
  String? note;

  DailyCheckIn({
    required this.dateKey,
    this.mostImportantTask,
    this.mostImportantDone = false,
    this.sleepHours,
    this.foodQuality,
    this.mindset,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'mostImportantTask': mostImportantTask,
        'mostImportantDone': mostImportantDone,
        'sleepHours': sleepHours,
        'foodQuality': foodQuality,
        'mindset': mindset,
        'note': note,
      };

  factory DailyCheckIn.fromJson(Map<String, dynamic> json) => DailyCheckIn(
        dateKey: json['dateKey'],
        mostImportantTask: json['mostImportantTask'],
        mostImportantDone: json['mostImportantDone'] ?? false,
        sleepHours: json['sleepHours'],
        foodQuality: json['foodQuality'],
        mindset: json['mindset'],
        note: json['note'],
      );
}

class RecipeVersion {
  String id;
  int versionNumber;
  DateTime date;
  String changesFromLast;
  int tasteRating; // 1-10
  double costSar;
  String notes;

  RecipeVersion({
    String? id,
    required this.versionNumber,
    DateTime? date,
    this.changesFromLast = '',
    required this.tasteRating,
    required this.costSar,
    this.notes = '',
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'versionNumber': versionNumber,
        'date': date.toIso8601String(),
        'changesFromLast': changesFromLast,
        'tasteRating': tasteRating,
        'costSar': costSar,
        'notes': notes,
      };

  factory RecipeVersion.fromJson(Map<String, dynamic> json) => RecipeVersion(
        id: json['id'],
        versionNumber: json['versionNumber'],
        date: DateTime.parse(json['date']),
        changesFromLast: json['changesFromLast'] ?? '',
        tasteRating: json['tasteRating'],
        costSar: (json['costSar'] as num).toDouble(),
        notes: json['notes'] ?? '',
      );
}

class Recipe {
  String id;
  String name; // e.g. "Popeyes-style wrap"
  String fastFoodEquivalent; // e.g. "Popeyes"
  double fastFoodCostSar;
  List<RecipeVersion> versions;

  Recipe({
    String? id,
    required this.name,
    this.fastFoodEquivalent = '',
    this.fastFoodCostSar = 0,
    List<RecipeVersion>? versions,
  })  : id = id ?? _uuid.v4(),
        versions = versions ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fastFoodEquivalent': fastFoodEquivalent,
        'fastFoodCostSar': fastFoodCostSar,
        'versions': versions.map((v) => v.toJson()).toList(),
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'],
        name: json['name'],
        fastFoodEquivalent: json['fastFoodEquivalent'] ?? '',
        fastFoodCostSar: (json['fastFoodCostSar'] as num? ?? 0).toDouble(),
        versions: (json['versions'] as List? ?? [])
            .map((v) => RecipeVersion.fromJson(v))
            .toList(),
      );
}

enum SpendCategory { urgentNeed, monthlyNeed, useful, want, fastFood }

class MoneyEntry {
  String id;
  DateTime date;
  String label;
  double amountSar;
  SpendCategory category;

  MoneyEntry({
    String? id,
    DateTime? date,
    required this.label,
    required this.amountSar,
    required this.category,
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'label': label,
        'amountSar': amountSar,
        'category': category.name,
      };

  factory MoneyEntry.fromJson(Map<String, dynamic> json) => MoneyEntry(
        id: json['id'],
        date: DateTime.parse(json['date']),
        label: json['label'],
        amountSar: (json['amountSar'] as num).toDouble(),
        category: SpendCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => SpendCategory.want,
        ),
      );
}

class SavingsDeposit {
  String id;
  DateTime date;
  double amountSar;

  SavingsDeposit({String? id, DateTime? date, required this.amountSar})
      : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amountSar': amountSar,
      };

  factory SavingsDeposit.fromJson(Map<String, dynamic> json) =>
      SavingsDeposit(
        id: json['id'],
        date: DateTime.parse(json['date']),
        amountSar: (json['amountSar'] as num).toDouble(),
      );
}

enum HobbyType { photography, coffee, music }

class HobbyEntry {
  String id;
  HobbyType type;
  DateTime date;
  String title;
  Map<String, String> fields; // flexible per-type fields
  String notes;

  HobbyEntry({
    String? id,
    required this.type,
    DateTime? date,
    required this.title,
    Map<String, String>? fields,
    this.notes = '',
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now(),
        fields = fields ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'date': date.toIso8601String(),
        'title': title,
        'fields': fields,
        'notes': notes,
      };

  factory HobbyEntry.fromJson(Map<String, dynamic> json) => HobbyEntry(
        id: json['id'],
        type: HobbyType.values.firstWhere((e) => e.name == json['type']),
        date: DateTime.parse(json['date']),
        title: json['title'],
        fields: Map<String, String>.from(json['fields'] ?? {}),
        notes: json['notes'] ?? '',
      );
}
