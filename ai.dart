import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'store.dart';
import 'util.dart';

class AiError implements Exception {
  final String msg;
  AiError(this.msg);
  @override
  String toString() => msg;
}

class AI {
  static bool get ready => Store.I.s.aiOn && Store.I.s.aiKey.trim().isNotEmpty;

  static Future<String> ask(String prompt, {bool json = false}) async {
    final s = Store.I.s;
    if (!ready) throw AiError('AI साठी Settings मध्ये मोफत Gemini key टाका.');
    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/${s.aiModel.trim()}:generateContent');
    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
    };
    if (json) body['generationConfig'] = {'responseMimeType': 'application/json'};
    http.Response r;
    try {
      r = await http
          .post(uri, headers: {'Content-Type': 'application/json', 'x-goog-api-key': s.aiKey.trim()}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
    } on SocketException {
      throw AiError('इंटरनेट नाही. AI साठी नेट चालू करा (बाकी अॅप ऑफलाइन चालतं).');
    } on TimeoutException {
      throw AiError('AI ला उत्तर द्यायला वेळ लागला. परत प्रयत्न करा.');
    }
    if (r.statusCode == 429) throw AiError('मोफत AI लिमिट संपली किंवा खूप जलद विचारलं. थोड्या वेळाने प्रयत्न करा.');
    if (r.statusCode == 400 || r.statusCode == 401 || r.statusCode == 403) {
      throw AiError('AI key चुकीची वाटते. Settings मध्ये key तपासा.');
    }
    if (r.statusCode == 404) throw AiError('AI मॉडेल सापडलं नाही. Settings मध्ये मॉडेल नाव तपासा.');
    if (r.statusCode != 200) throw AiError('AI चाललं नाही (${r.statusCode}). परत प्रयत्न करा.');
    final j = jsonDecode(utf8.decode(r.bodyBytes));
    final cands = j['candidates'];
    if (cands is! List || cands.isEmpty) throw AiError('AI ने उत्तर दिलं नाही. वेगळ्या शब्दांत विचारा.');
    final parts = (cands[0]['content']?['parts'] as List?) ?? [];
    return parts.map((p) => (p['text'] ?? '').toString()).join().trim();
  }

  static Future<dynamic> askJson(String prompt) async {
    var t = await ask(prompt, json: true);
    t = t.replaceAll(RegExp(r'```(json)?'), '').trim();
    return jsonDecode(t);
  }

  static String lang() {
    switch (Store.I.s.aiLang) {
      case 'English':
        return 'in professional English';
      case 'दोन्ही':
        return 'आधी मराठीत आणि खाली English मध्ये';
      default:
        return 'मराठीत';
    }
  }

  static String context() {
    final st = Store.I;
    final l = st.items.length > 80 ? st.items.sublist(st.items.length - 80) : st.items;
    return l.map((e) {
      if (e.isNote) return '[नोट ${e.date}${e.person.isNotEmpty ? ' ${e.person}' : ''}] ${e.content}';
      if (e.type == 'trip') {
        return '[ट्रिप ${e.date}] ${e.title}: ${e.trip.map((i) => '${i.k} ${i.detail}${i.d ? ' ✔' : ''}').join('; ')}';
      }
      final pts = e.points.isEmpty ? '' : ' | ${e.points.map((p) => p.t + (p.d ? ' ✔' : '')).join('; ')}';
      return '[${e.type == 'meeting' ? 'मीटिंग' : 'टास्क'} ${e.date} ${e.time ?? ''}] ${e.title}'
          '${e.person.isNotEmpty ? ' (सोबत ${e.person})' : ''}${e.done ? ' ✔' : ''}$pts';
    }).join('\n');
  }

  static String clean(String text) => Store.I.s.maskOn ? maskSensitive(text) : text;

  static String header() => 'तू माझ्या business डायरी अॅपमधला मदतनीस आहेस. आज ${todayKey()}, वेळ ${nowHM()}. '
      'Markdown (*, #) वापरू नको; थेट copy करून पाठवता येईल असा साधा मजकूर दे.';
}
