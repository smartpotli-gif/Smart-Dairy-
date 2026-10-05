class Point {
  String t;
  bool d;
  Point(this.t, {this.d = false});
  Map<String, dynamic> toJson() => {'t': t, 'd': d};
  factory Point.fromJson(Map<String, dynamic> j) => Point(j['t'] ?? '', d: j['d'] == true);
}

class TripItem {
  String k, detail, date, time;
  bool d;
  TripItem({required this.k, this.detail = '', required this.date, this.time = '', this.d = false});
  Map<String, dynamic> toJson() => {'k': k, 'detail': detail, 'date': date, 'time': time, 'd': d};
  factory TripItem.fromJson(Map<String, dynamic> j) =>
      TripItem(k: j['k'] ?? '', detail: j['detail'] ?? '', date: j['date'] ?? '', time: j['time'] ?? '', d: j['d'] == true);
}

/// type: task | meeting | note | trip ; kind: '' | summary
class Item {
  int id;
  String type, title, content, date, person, phone, kind;
  String? time;
  int priority, series;
  bool done, pinned;
  List<String> tags;
  List<Point> points;
  List<TripItem> trip;
  Item({
    required this.id,
    required this.type,
    this.title = '',
    this.content = '',
    required this.date,
    this.time,
    this.person = '',
    this.phone = '',
    this.kind = '',
    this.priority = 0,
    int? series,
    this.done = false,
    this.pinned = false,
    List<String>? tags,
    List<Point>? points,
    List<TripItem>? trip,
  })  : series = series ?? id,
        tags = tags ?? [],
        points = points ?? [],
        trip = trip ?? [];

  bool get isNote => type == 'note';
  bool get timed => type == 'task' || type == 'meeting';

  Map<String, dynamic> toJson() => {
        'id': id, 'type': type, 'title': title, 'content': content, 'date': date, 'time': time,
        'person': person, 'phone': phone, 'kind': kind, 'priority': priority, 'series': series,
        'done': done, 'pinned': pinned, 'tags': tags,
        'points': points.map((e) => e.toJson()).toList(),
        'trip': trip.map((e) => e.toJson()).toList(),
      };

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as int,
        type: j['type'] ?? 'task',
        title: j['title'] ?? '',
        content: j['content'] ?? '',
        date: j['date'] ?? '',
        time: j['time'],
        person: j['person'] ?? '',
        phone: j['phone'] ?? '',
        kind: j['kind'] ?? '',
        priority: j['priority'] ?? 0,
        series: j['series'],
        done: j['done'] == true,
        pinned: j['pinned'] == true,
        tags: ((j['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
        points: ((j['points'] as List?) ?? []).map((e) => Point.fromJson(Map<String, dynamic>.from(e))).toList(),
        trip: ((j['trip'] as List?) ?? []).map((e) => TripItem.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
}

class Contact {
  String name, phone, company;
  Contact({required this.name, this.phone = '', this.company = ''});
  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'company': company};
  factory Contact.fromJson(Map<String, dynamic> j) =>
      Contact(name: j['name'] ?? '', phone: j['phone'] ?? '', company: j['company'] ?? '');
}

class Settings {
  String name = '', company = '', lang = 'mr', theme = 'system', pin = '';
  String aiKey = '', aiModel = 'gemini-flash-latest', aiLang = 'मराठी';
  bool aiOn = true, maskOn = true, motivationOn = true, splashOn = true, morningOn = true, eodOn = true;
  int remindBefore = 15, morningHour = 8, eodHour = 20;
  List<String> customMsgs = [];

  Map<String, dynamic> toJson() => {
        'name': name, 'company': company, 'lang': lang, 'theme': theme, 'pin': pin,
        'aiKey': aiKey, 'aiModel': aiModel, 'aiLang': aiLang, 'aiOn': aiOn, 'maskOn': maskOn,
        'motivationOn': motivationOn, 'splashOn': splashOn, 'morningOn': morningOn, 'eodOn': eodOn,
        'remindBefore': remindBefore, 'morningHour': morningHour, 'eodHour': eodHour, 'customMsgs': customMsgs,
      };

  static Settings fromJson(Map<String, dynamic> j) {
    final s = Settings();
    s.name = j['name'] ?? '';
    s.company = j['company'] ?? '';
    s.lang = j['lang'] ?? 'mr';
    s.theme = j['theme'] ?? 'system';
    s.pin = j['pin'] ?? '';
    s.aiKey = j['aiKey'] ?? '';
    s.aiModel = j['aiModel'] ?? 'gemini-flash-latest';
    s.aiLang = j['aiLang'] ?? 'मराठी';
    s.aiOn = j['aiOn'] ?? true;
    s.maskOn = j['maskOn'] ?? true;
    s.motivationOn = j['motivationOn'] ?? true;
    s.splashOn = j['splashOn'] ?? true;
    s.morningOn = j['morningOn'] ?? true;
    s.eodOn = j['eodOn'] ?? true;
    s.remindBefore = j['remindBefore'] ?? 15;
    s.morningHour = j['morningHour'] ?? 8;
    s.eodHour = j['eodHour'] ?? 20;
    s.customMsgs = ((j['customMsgs'] as List?) ?? []).map((e) => e.toString()).toList();
    return s;
  }
}
