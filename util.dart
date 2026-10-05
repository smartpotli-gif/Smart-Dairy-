import 'package:intl/intl.dart';
import 'models.dart';

String two(int n) => n.toString().padLeft(2, '0');
String dkey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
String todayKey() => dkey(DateTime.now());
String daysFrom(int n) => dkey(DateTime.now().add(Duration(days: n)));
String nowHM() {
  final n = DateTime.now();
  return '${two(n.hour)}:${two(n.minute)}';
}

DateTime? parseKey(String k) {
  try {
    final p = k.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  } catch (_) {
    return null;
  }
}

String nice(String k) {
  final d = parseKey(k);
  return d == null ? k : DateFormat('EEE, d MMM').format(d);
}

String dayLabel(String k) {
  if (k == todayKey()) return 'आज';
  if (k == daysFrom(-1)) return 'काल';
  if (k == daysFrom(1)) return 'उद्या';
  return nice(k);
}

int minsOf(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String timeLeft(String t) {
  final d = minsOf(t) - minsOf(nowHM());
  if (d <= 0) return 'आता';
  if (d < 60) return '$d मिनिटांनी';
  final m = d % 60;
  return '${d ~/ 60} तास${m > 0 ? ' $m मि.' : ''} नंतर';
}

DateTime? whenOf(String date, String? time) {
  final d = parseKey(date);
  if (d == null || time == null || time.isEmpty) return null;
  final p = time.split(':');
  return DateTime(d.year, d.month, d.day, int.parse(p[0]), int.parse(p[1]));
}

List<Item> sortItems(List<Item> l) {
  l.sort((a, b) => (a.date + (a.time ?? '99')).compareTo(b.date + (b.time ?? '99')));
  return l;
}

bool isMissed(Item e) {
  if (!e.timed || e.done) return false;
  final t = todayKey();
  if (e.date.compareTo(t) < 0) return true;
  return e.date == t && e.time != null && e.time!.compareTo(nowHM()) < 0;
}

class Parsed {
  final String title, date, type;
  final String? time;
  Parsed(this.title, this.date, this.time, this.type);
}

Parsed parseNatural(String input) {
  final s = input.toLowerCase();
  var d = DateTime.now();
  d = DateTime(d.year, d.month, d.day);
  String? time;
  if (s.contains('परवा') || s.contains('day after tomorrow')) {
    d = d.add(const Duration(days: 2));
  } else if (s.contains('उद्या') || s.contains('tomorrow')) {
    d = d.add(const Duration(days: 1));
  }
  final dm = RegExp(r'\b(\d{1,2})[/\-](\d{1,2})(?:[/\-](\d{4}))?\b').firstMatch(s);
  if (dm != null) {
    final m = int.parse(dm.group(2)!);
    if (m >= 1 && m <= 12) d = DateTime(int.tryParse(dm.group(3) ?? '') ?? d.year, m, int.parse(dm.group(1)!));
  }
  final tm = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)').firstMatch(s);
  final mt = RegExp(r'(सकाळी|दुपारी|संध्याकाळी|रात्री)\s*(\d{1,2})(?::(\d{2}))?').firstMatch(s);
  final vt = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(वाजता|ला)').firstMatch(s);
  if (tm != null) {
    var h = int.parse(tm.group(1)!);
    if (tm.group(3) == 'pm' && h < 12) h += 12;
    if (tm.group(3) == 'am' && h == 12) h = 0;
    time = '${two(h)}:${tm.group(2) ?? '00'}';
  } else if (mt != null) {
    var h = int.parse(mt.group(2)!);
    if (mt.group(1) != 'सकाळी' && h < 12) h += 12;
    time = '${two(h)}:${mt.group(3) ?? '00'}';
  } else if (vt != null) {
    var h = int.parse(vt.group(1)!);
    if (h < 8) h += 12;
    time = '${two(h)}:${vt.group(2) ?? '00'}';
  }
  if (time != null && minsOf(time) >= 24 * 60) time = null;
  final isMeeting = RegExp(r'मीटिंग|मिटिंग|meeting|बैठक').hasMatch(s);
  return Parsed(input.trim(), dkey(d), time, isMeeting ? 'meeting' : 'task');
}

/// Hides PAN and long account-like numbers before text goes to AI.
String maskSensitive(String s) {
  s = s.replaceAllMapped(RegExp(r'\b[A-Z]{5}\d{4}[A-Z]\b'), (m) {
    final v = m.group(0)!;
    return '${v.substring(0, 2)}XXXXXX${v.substring(8)}';
  });
  return s.replaceAllMapped(RegExp(r'\b\d[\d -]{7,}\d\b'), (m) {
    final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 ? 'XXXX${digits.substring(digits.length - 4)}' : m.group(0)!;
  });
}

String waNumber(String phone) {
  var n = phone.replaceAll(RegExp(r'\D'), '');
  if (n.length == 10) n = '91$n';
  return n;
}

const meetingTemplates = <String, List<String>>{
  'Vendor मीटिंग': ['रेट्स / quotation', 'Delivery timeline', 'Payment terms', 'पुढची action'],
  'CA चर्चा': ['GST / TDS', 'Documents पाठवायचे', 'Deadlines', 'Fees / payment'],
  'Internal review': ['मागच्या कामांचा आढावा', 'अडचणी', 'पुढची कामं'],
};
const tripTemplate = ['✈️ फ्लाइट', '🏨 हॉटेल', '🚕 कॅब', '🛂 व्हिसा', '🛡️ Insurance'];

const motivation = [
  'आजचं छोटं पाऊल, उद्याची मोठी कंपनी.',
  'मोठी स्वप्नं, पण रोजचं काम छोटं आणि नीट.',
  'ग्राहकाची अडचण सोडवा, पैसा आपोआप येईल.',
  'परफेक्ट होण्याची वाट नको, सुरुवात करा आणि सुधारत जा.',
  'आज एका नवीन व्यक्तीशी बोला, एक संधी तिथेच असू शकते.',
  '"नाही" ऐकणं हा प्रवासाचा भाग आहे, शेवट नाही.',
  'Cash flow वर लक्ष, निर्णयात शांतपणा.',
  'टीम मजबूत तर कंपनी मजबूत.',
  'आज जे शिकलात, ते उद्याची ताकद आहे.',
  'वेळ हीच सगळ्यात मोठी गुंतवणूक आहे, ती नीट वापरा.',
  'प्रत्येक follow-up म्हणजे एक नवीन दरवाजा.',
  'अडचण आली म्हणजे तुम्ही पुढे जात आहात.',
  'कमी बोला, जास्त करून दाखवा.',
  'शिस्त प्रेरणेपेक्षा जास्त दूर नेते.',
  'आज एक काम पूर्ण करा जे कालपासून पुढे ढकलताय.',
  'विश्वास कमावायला वेळ लागतो, तोच सगळ्यात मोठं भांडवल आहे.',
  'चुकांची भीती नको, न शिकण्याची भीती ठेवा.',
  'छोटे विजय साजरे करा, ते मोठ्या यशाकडे नेतात.',
  'ग्राहकाचं ऐका, उत्तर तिथेच दडलेलं असतं.',
  '{name}, आजचा दिवस तुमचा आहे. चला सुरुवात करूया! 🚀',
];

/// Same message all day, changes daily.
String todaysMessage(String name, List<String> custom) {
  final all = [...motivation, ...custom];
  final d = DateTime.now();
  final idx = DateTime(d.year, d.month, d.day).difference(DateTime(2024, 1, 1)).inDays % all.length;
  return all[idx].replaceAll('{name}', name.isEmpty ? 'मित्रा' : name);
}
