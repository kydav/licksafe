enum Severity { critical, high, moderate, caution }

class Toxin {
  const Toxin({
    required this.id,
    required this.name,
    required this.aliases,
    required this.severity,
    required this.notes,
  });

  final String id;
  final String name;
  final List<String> aliases;
  final Severity severity;
  final String notes;

  factory Toxin.fromJson(Map<String, dynamic> json) => Toxin(
    id: json['id'] as String,
    name: json['name'] as String,
    aliases: List<String>.from(json['aliases'] as List),
    severity: Severity.values.firstWhere((s) => s.name == json['severity']),
    notes: json['notes'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'aliases': aliases,
    'severity': severity.name,
    'notes': notes,
  };
}

class ToxinMatch {
  const ToxinMatch({required this.toxin, required this.matchedAlias});
  final Toxin toxin;
  final String matchedAlias;
}

class ScanResult {
  const ScanResult({
    required this.rawText,
    required this.ingredientsList,
    required this.matches,
  });

  final String rawText;
  final List<String> ingredientsList;
  final List<ToxinMatch> matches;

  bool get isSafe => matches.isEmpty;

  Severity? get highestSeverity {
    if (matches.isEmpty) return null;
    return matches.map((m) => m.toxin.severity).reduce(
      (a, b) => a.index < b.index ? a : b,
    );
  }
}
