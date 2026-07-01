import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:licksafe/core/models/toxin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ToxinService {
  ToxinService(this._firestore);
  final FirebaseFirestore _firestore;

  List<Toxin>? _cached;

  Future<List<Toxin>> getToxins() async {
    if (_cached != null) return _cached!;
    _cached = await _loadMerged();
    return _cached!;
  }

  Future<ScanResult> scan(String rawText) async {
    final toxins = await getToxins();
    final lower = rawText.toLowerCase();

    // Extract the ingredients block if labeled
    final ingredientsText = _extractIngredientsBlock(lower);

    // Split on common ingredient delimiters
    final ingredients = ingredientsText
        .split(RegExp(r'[,;()\[\]]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final matches = <ToxinMatch>[];
    final seen = <String>{};

    for (final toxin in toxins) {
      for (final alias in toxin.aliases) {
        if (seen.contains(toxin.id)) break;
        // Whole-word match to avoid false positives (e.g. "garlic" in "sugarlicious")
        final pattern = RegExp(
          r'(^|[\s,;()\[\]])' + RegExp.escape(alias) + r'($|[\s,;()\[\]])',
        );
        if (pattern.hasMatch(ingredientsText)) {
          matches.add(ToxinMatch(toxin: toxin, matchedAlias: alias));
          seen.add(toxin.id);
          break;
        }
      }
    }

    // Sort by severity (critical first)
    matches.sort((a, b) => a.toxin.severity.index.compareTo(b.toxin.severity.index));

    return ScanResult(
      rawText: rawText,
      ingredientsList: ingredients,
      matches: matches,
    );
  }

  String _extractIngredientsBlock(String text) {
    final patterns = [
      RegExp(r'ingredients?:?\s*(.+?)(?:contains?|allergen|nutrition|amount per|$)', dotAll: true),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(1) ?? text;
    }
    return text;
  }

  // Merges bundled JSON with Firestore overrides/additions
  Future<List<Toxin>> _loadMerged() async {
    final bundled = await _loadBundled();
    try {
      final remote = await _loadRemote();
      final merged = Map<String, Toxin>.fromEntries(
        bundled.map((t) => MapEntry(t.id, t)),
      );
      for (final t in remote) {
        merged[t.id] = t;
      }
      await _cache(merged.values.toList());
      return merged.values.toList();
    } catch (e) {
      debugPrint('ToxinService: remote load failed, using bundled — $e');
      return _loadCachedOrBundled(bundled);
    }
  }

  Future<List<Toxin>> _loadBundled() async {
    final raw = await rootBundle.loadString('assets/data/toxins.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => Toxin.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Toxin>> _loadRemote() async {
    final snap = await _firestore.collection('toxic_ingredients').get();
    return snap.docs.map((d) => Toxin.fromJson(d.data())).toList();
  }

  Future<List<Toxin>> _loadCachedOrBundled(List<Toxin> bundled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('toxins_cache');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        return list.map((e) => Toxin.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return bundled;
  }

  Future<void> _cache(List<Toxin> toxins) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'toxins_cache',
        jsonEncode(toxins.map((t) => t.toJson()).toList()),
      );
    } catch (_) {}
  }
}

final toxinServiceProvider = Provider<ToxinService>(
  (ref) => ToxinService(FirebaseFirestore.instance),
);
