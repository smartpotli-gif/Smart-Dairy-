import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'notifications.dart';
import 'util.dart';

class Store extends ChangeNotifier {
  static final Store I = Store._();
  Store._();

  List<Item> items = [];
  List<Contact> contacts = [];
  Settings s = Settings();
  int nextId = 1;
  File? _file;

  Future<void> load() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/smart_diary.json');
    if (await _file!.exists()) {
      try {
        _apply(jsonDecode(await _file!.readAsString()) as Map<String, dynamic>, withSettings: true);
      } catch (_) {}
    }
  }

  void _apply(Map<String, dynamic> j, {required bool withSettings}) {
    items = ((j['items'] as List?) ?? []).map((e) => Item.fromJson(Map<String, dynamic>.from(e))).toList();
    contacts = ((j['contacts'] as List?) ?? []).map((e) => Contact.fromJson(Map<String, dynamic>.from(e))).toList();
    nextId = j['nextId'] ?? 1;
    for (final e in items) {
      if (e.id >= nextId) nextId = e.id + 1;
    }
    if (withSettings && j['settings'] != null) s = Settings.fromJson(Map<String, dynamic>.from(j['settings']));
  }

  Map<String, dynamic> toJson({bool forBackup = false}) {
    final st = s.toJson();
    if (forBackup) {
      st.remove('pin');
      st.remove('aiKey');
    }
    return {
      'app': 'smart_diary', 'v': 1, 'at': DateTime.now().toIso8601String(), 'nextId': nextId,
      'items': items.map((e) => e.toJson()).toList(),
      'contacts': contacts.map((e) => e.toJson()).toList(),
      'settings': st,
    };
  }

  String backupJson() => jsonEncode(toJson(forBackup: true));

  Future<bool> restore(String text) async {
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      if (j['app'] != 'smart_diary' || j['items'] is! List) return false;
      _apply(j, withSettings: false);
      await save();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> save({bool reschedule = true}) async {
    notifyListeners();
    try {
      await _file?.writeAsString(jsonEncode(toJson()));
    } catch (_) {}
    if (reschedule) await Notif.rescheduleAll(this);
  }

  int newId() => nextId++;

  Item? byId(int id) {
    for (final e in items) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> add(Item e) async {
    items.add(e);
    if (e.type == 'meeting') upsertContact(e.person, e.phone);
    await save();
  }

  Future<void> remove(int id) async {
    items.removeWhere((e) => e.id == id);
    await save();
  }

  Future<void> wipe() async {
    items = [];
    contacts = [];
    await save();
  }

  void upsertContact(String name, String phone) {
    name = name.trim();
    if (name.isEmpty) return;
    for (final c in contacts) {
      if (c.name == name) {
        if (phone.trim().isNotEmpty) c.phone = phone.trim();
        return;
      }
    }
    contacts.add(Contact(name: name, phone: phone.trim()));
  }

  Contact? contact(String name) {
    for (final c in contacts) {
      if (c.name == name) return c;
    }
    return null;
  }

  List<Item> get notes => items.where((e) => e.isNote).toList();
  List<Item> timedOn(String day) => sortItems(items.where((e) => e.timed && e.date == day).toList());
}
