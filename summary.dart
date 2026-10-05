import 'package:flutter/material.dart';
import '../ai.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

/// Summary of a conversation (CA, vendor…) with formats, masking, tasks, compare.
class SummaryPage extends StatefulWidget {
  final String? person, text;
  const SummaryPage({super.key, this.person, this.text});
  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late final person = TextEditingController(text: widget.person ?? '');
  late final input = TextEditingController(text: widget.text ?? '');
  final out = TextEditingController();
  String format = 'Minutes';
  late String lang = Store.I.s.aiLang;
  late bool mask = Store.I.s.maskOn;
  bool busy = false, shown = false;

  String cleanInput() => mask ? maskSensitive(input.text.trim()) : input.text.trim();
  String langText() => lang == 'English' ? 'in professional English' : lang == 'दोन्ही' ? 'आधी मराठीत आणि खाली English मध्ये' : 'मराठीत';

  Future<void> run(String prompt, {bool replace = true}) async {
    setState(() {
      busy = true;
      shown = true;
      if (replace) out.text = '✨ विचार करतोय…';
    });
    try {
      out.text = await AI.ask(prompt);
    } catch (e) {
      out.text = e.toString();
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> make() async {
    if (input.text.trim().isEmpty) {
      toast(context, 'आधी चर्चा लिहा किंवा पेस्ट करा');
      return;
    }
    final fm = {
      'Minutes': 'Minutes of Meeting: 1) मुख्य चर्चा 2) काय ठरलं 3) Action items (कोण, काय, deadline)',
      'WhatsApp छोटा': 'WhatsApp वर पाठवण्यासाठी 4-5 ओळींचा छोटा, नम्र मेसेज',
      'Formal Email': 'Formal business email, Subject line सोबत',
    }[format];
    final p = person.text.trim();
    await run('${AI.header()}\nखाली ${p.isEmpty ? 'एका व्यक्ती' : p}सोबत झालेल्या business चर्चेचा मजकूर आहे. त्याचा $fm बनव, ${langText()}. '
        'फक्त दिलेल्या माहितीवरूनच लिही, काही नवीन जोडू नको.\n\n${cleanInput()}');
  }

  Future<void> toTasks() async {
    setState(() => busy = true);
    try {
      final j = await AI.askJson('आज ${todayKey()}. या मजकुरातून Action items काढ. फक्त JSON array दे: [{"title":"छोटं काम","date":"YYYY-MM-DD किंवा null"}]. काही नसेल तर [].\n\n'
          '${out.text.isNotEmpty ? out.text : cleanInput()}');
      final st = Store.I;
      var n = 0;
      if (j is List) {
        for (final x in j) {
          final t = (x is Map ? x['title'] : null)?.toString() ?? '';
          if (t.isEmpty) continue;
          final d = (x['date'] ?? '').toString();
          st.items.add(Item(
              id: st.newId(), type: 'task', title: t, date: RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d) ? d : todayKey(), person: person.text.trim()));
          n++;
        }
      }
      await st.save();
      if (mounted) toast(context, n > 0 ? '✅ $n कामं Tasks मध्ये' : 'कामं सापडली नाहीत');
    } catch (e) {
      if (mounted) toast(context, e is AiError ? e.msg : 'कामं काढता आली नाहीत');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> saveNote() async {
    final v = out.text.trim();
    if (v.isEmpty) return;
    final st = Store.I, p = person.text.trim();
    st.upsertContact(p, '');
    await st.add(Item(id: st.newId(), type: 'note', kind: 'summary', person: p, content: v, date: todayKey(), tags: ['Summary', if (p.isNotEmpty) p]));
    if (mounted) toast(context, '💾 Notes मध्ये सेव्ह');
  }

  void compare() {
    final p = person.text.trim();
    final old = Store.I.items.where((e) => e.kind == 'summary' && e.person == p).toList();
    final last = old.length > 2 ? old.sublist(old.length - 2) : old;
    run('${AI.header()}\n$p सोबतच्या मागच्या चर्चा:\n${last.map((e) => '${nice(e.date)}:\n${e.content}').join('\n\n')}\n\nआजची चर्चा:\n${out.text}\n\n'
        '${langText()} सांग: मागच्या वेळी काय ठरलं होतं, त्यातलं काय पूर्ण झालं, काय अजून बाकी आहे.');
  }

  @override
  Widget build(BuildContext context) {
    final p = person.text.trim();
    final hasOld = p.isNotEmpty && Store.I.items.any((e) => e.kind == 'summary' && e.person == p);
    return Scaffold(
      appBar: AppBar(title: const Text('📋 चर्चेचं Summary')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 40), children: [
        TextField(controller: person, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'कोणासोबत चर्चा', hintText: 'उदा. CA')),
        if (Store.I.contacts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(spacing: 6, children: [
              for (final c in Store.I.contacts.take(8)) ActionChip(label: Text(c.name), onPressed: () => setState(() => person.text = c.name)),
            ]),
          ),
        const SizedBox(height: 12),
        TextField(
            controller: input,
            maxLines: null,
            minLines: 6,
            decoration: const InputDecoration(hintText: 'बोलणं झालेले मुद्दे लिहा, किंवा WhatsApp/Email chat कॉपी करून इथे पेस्ट करा… (🎤 कीबोर्ड माइकनेही चालेल)')),
        const Section('फॉरमॅट'),
        Wrap(spacing: 8, children: [
          for (final f in ['Minutes', 'WhatsApp छोटा', 'Formal Email']) ChoiceChip(label: Text(f), selected: format == f, onSelected: (_) => setState(() => format = f)),
        ]),
        const Section('भाषा'),
        Wrap(spacing: 8, children: [
          for (final f in ['मराठी', 'English', 'दोन्ही']) ChoiceChip(label: Text(f), selected: lang == f, onSelected: (_) => setState(() => lang = f)),
        ]),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: mask,
            onChanged: (v) => setState(() => mask = v),
            title: const Text('🔒 PAN, खाते नंबर AI ला पाठवण्याआधी लपवा'),
            subtitle: const Text('उदा. XXXX1234')),
        if (!AI.ready)
          const Card(child: ListTile(title: Text('AI साठी Settings मध्ये मोफत Gemini key टाका'), leading: Text('✨')))
        else
          AiButton('✨ Summary बनवा', busy: busy, onTap: make),
        if (shown) ...[
          const Section('Summary'),
          ResultBox(ctrl: out, subject: 'चर्चा Summary${p.isNotEmpty ? ' — $p' : ''}'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: C.green), onPressed: busy ? null : toTasks, child: const Text('✅ कामं Tasks मध्ये'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.tonal(onPressed: busy ? null : saveNote, child: const Text('💾 सेव्ह करा'))),
          ]),
          if (hasOld) TextButton(onPressed: busy ? null : compare, child: const Text('🔁 मागच्या चर्चेशी तुलना')),
        ],
      ]),
    );
  }
}

/// Ask questions about your diary, or turn a sentence into a task/meeting.
class AskAiPage extends StatefulWidget {
  final String? prefill;
  const AskAiPage({super.key, this.prefill});
  @override
  State<AskAiPage> createState() => _AskAiPageState();
}

class _AskAiPageState extends State<AskAiPage> {
  late final q = TextEditingController(text: widget.prefill ?? '');
  final out = TextEditingController();
  bool busy = false, shown = false;

  Future<void> ask() async {
    if (q.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      shown = true;
      out.text = '✨ विचार करतोय…';
    });
    try {
      out.text = await AI.ask('${AI.header()}\nखालच्या नोंदींवरूनच ${AI.lang()} थोडक्यात उत्तर दे; माहिती नसेल तर तसं सांग.\n\n'
          '${AI.clean(AI.context())}\n\nप्रश्न: ${AI.clean(q.text.trim())}');
    } catch (e) {
      out.text = e.toString();
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> addEntry() async {
    if (q.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      final j = await AI.askJson('आज ${todayKey()}, वेळ ${nowHM()}. या वाक्यावरून डायरी नोंद काढ. फक्त JSON: '
          '{"type":"meeting" किंवा "task","title":"छोटं नाव","date":"YYYY-MM-DD","time":"HH:MM किंवा null","person":"व्यक्ती किंवा रिकामं"}\nवाक्य: ${q.text.trim()}');
      final st = Store.I;
      final type = j['type'] == 'meeting' ? 'meeting' : 'task';
      final d = (j['date'] ?? '').toString(), t = (j['time'] ?? '').toString(), p = (j['person'] ?? '').toString();
      final e = Item(
        id: st.newId(),
        type: type,
        title: (j['title'] ?? q.text).toString(),
        date: RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d) ? d : todayKey(),
        time: RegExp(r'^\d{2}:\d{2}$').hasMatch(t) ? t : null,
        person: p,
        phone: st.contact(p)?.phone ?? '',
      );
      await st.add(e);
      if (!mounted) return;
      toast(context, '✨ ${type == 'meeting' ? 'मीटिंग' : 'काम'} — ${dayLabel(e.date)}${e.time != null ? ' ${e.time}' : ''}');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, e is AiError ? e.msg : 'नीट समजलं नाही, परत लिहून बघा.');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('✨ AI ला विचारा')),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          TextField(
              controller: q,
              autofocus: true,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(hintText: 'उदा. CA सोबत काय बाकी आहे?\nकिंवा: उद्या 5 ला राहुलसोबत मीटिंग')),
          const SizedBox(height: 10),
          if (!AI.ready)
            const Card(child: ListTile(leading: Text('✨'), title: Text('Settings मध्ये मोफत Gemini key टाका')))
          else
            Row(children: [
              Expanded(child: AiButton('विचारा', busy: busy, onTap: ask)),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: C.green, padding: const EdgeInsets.all(12)), onPressed: busy ? null : addEntry, child: const Text('✨ नोंद बनवा'))),
            ]),
          if (shown) ResultBox(ctrl: out, subject: 'AI उत्तर'),
        ]),
      );
}
