import 'package:flutter/material.dart';
import '../ai.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'forms.dart';

class MeetingPage extends StatefulWidget {
  final int id;
  const MeetingPage({super.key, required this.id});
  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  final point = TextEditingController();
  final aiOut = TextEditingController();
  bool busy = false, showAi = false;
  String nextDate = daysFrom(2), nextTime = '17:00';

  Future<void> runAi(Item e, String prompt) async {
    setState(() {
      busy = true;
      showAi = true;
      aiOut.text = '✨ विचार करतोय…';
    });
    try {
      aiOut.text = await AI.ask(prompt);
    } catch (err) {
      aiOut.text = err.toString();
    }
    if (mounted) setState(() => busy = false);
  }

  String waMsg(Item e) =>
      'नमस्कार${e.person.isNotEmpty ? ' ${e.person}' : ''}, आपली "${e.title}" मीटिंग ${nice(e.date)}${e.time != null ? ' रोजी ${e.time} वाजता' : ''} आहे.';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Store.I,
        builder: (context, _) {
          final st = Store.I;
          final e = st.byId(widget.id);
          if (e == null) return const Scaffold(body: Center(child: Text('ही मीटिंग डिलीट झाली.')));
          final prev = sortItems(st.items
                  .where((x) => x.type == 'meeting' && x.series == e.series && x.id != e.id && (x.date + (x.time ?? '')).compareTo(e.date + (e.time ?? '')) < 0)
                  .toList())
              .reversed
              .toList();
          final minutes = '${e.title} — ${nice(e.date)}${e.time != null ? ' ${e.time}' : ''}\n${e.points.map((p) => '${p.d ? '✅' : '⏳'} ${p.t}').join('\n')}';
          return Scaffold(
            appBar: AppBar(title: Text('🤝 ${e.title}'), actions: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemFormPage(type: 'meeting', edit: e)))),
              IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirm(context, 'ही मीटिंग डिलीट करायची?')) {
                      await st.remove(e.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }),
            ]),
            body: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 40), children: [
              Text('${dayLabel(e.date)} · ${nice(e.date)}${e.time != null ? ' · ⏰ ${e.time}' : ''}', style: TextStyle(color: Theme.of(context).hintColor)),
              if (e.person.isNotEmpty || e.phone.isNotEmpty) ...[
                const Section('👤 कोणासोबत'),
                Card(
                  child: ListTile(
                    title: Text(e.person.isEmpty ? 'Contact' : e.person),
                    subtitle: e.phone.isEmpty ? null : Text(e.phone),
                    trailing: e.phone.isEmpty
                        ? null
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.call), onPressed: () => openUrl(context, 'tel:${e.phone}')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: C.wa),
                              onPressed: () => openWhatsApp(context, e.phone, waMsg(e)),
                              child: const Text('📲 WhatsApp'),
                            ),
                          ]),
                  ),
                ),
              ],
              Section('📝 पॉइंट्स (${e.points.length})', trailing: e.points.isEmpty ? null : IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: () => copyText(context, minutes))),
              if (e.points.isEmpty) const Empty('मीटिंगमध्ये झालेले मुद्दे इथे लिहा.'),
              for (var i = 0; i < e.points.length; i++)
                Card(
                  child: Row(children: [
                    Checkbox(value: e.points[i].d, onChanged: (_) {
                      e.points[i].d = !e.points[i].d;
                      st.save(reschedule: false);
                    }),
                    Expanded(child: Text(e.points[i].t, style: TextStyle(decoration: e.points[i].d ? TextDecoration.lineThrough : null))),
                    IconButton(
                        tooltip: 'टास्क बनवा',
                        icon: const Icon(Icons.add_task, size: 20),
                        onPressed: () async {
                          await st.add(Item(id: st.newId(), type: 'task', title: e.points[i].t, date: todayKey(), person: e.person));
                          if (context.mounted) toast(context, '✅ Tasks मध्ये ॲड');
                        }),
                    IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () {
                      e.points.removeAt(i);
                      st.save(reschedule: false);
                    }),
                  ]),
                ),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: point,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(hintText: 'पॉइंट लिहा…'),
                    onSubmitted: (_) => addPoint(e),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: () => addPoint(e), icon: const Icon(Icons.add), style: IconButton.styleFrom(backgroundColor: C.green)),
              ]),
              if (AI.ready) ...[
                const Section('✨ AI'),
                Row(children: [
                  Expanded(
                    child: AiButton('📝 Summary', busy: busy, onTap: () {
                      if (e.points.isEmpty) {
                        toast(context, 'आधी पॉइंट्स टाका');
                        return;
                      }
                      runAi(e, '${AI.header()}\nया मीटिंगच्या पॉइंट्सवरून ${AI.lang()} छोटी Minutes बनव: 1) काय ठरलं 2) Action items (कोण, काय, कधी) 3) पुढच्या मीटिंगमध्ये काय बघायचं.\n'
                          'मीटिंग: ${e.title}, ${e.date}${e.person.isNotEmpty ? ', सोबत ${e.person}' : ''}\n${AI.clean(e.points.map((p) => '- ${p.t}${p.d ? ' (झालं)' : ''}').join('\n'))}');
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AiButton('📲 WhatsApp draft', busy: busy, onTap: () {
                      runAi(e, '${AI.header()}\n${e.person.isEmpty ? 'समोरच्या व्यक्ती' : e.person}ला पाठवण्यासाठी छोटा, नम्र WhatsApp follow-up मेसेज ${AI.lang()} लिही (3-4 ओळी). '
                          'मीटिंग: ${e.title}, ${nice(e.date)} ${e.time ?? ''}. पॉइंट्स: ${AI.clean(e.points.map((p) => p.t).join('; '))}. फक्त मेसेज दे.');
                    }),
                  ),
                ]),
                if (showAi) ResultBox(ctrl: aiOut, subject: '${e.title} — Minutes'),
                if (showAi && e.phone.isNotEmpty)
                  TextButton(onPressed: () => openWhatsApp(context, e.phone, aiOut.text), child: Text('📲 ${e.person.isEmpty ? 'contact' : e.person} ला थेट पाठवा')),
              ],
              if (prev.isNotEmpty) ...[
                const Section('📎 मागच्या मीटिंगमध्ये काय झालं'),
                for (final p in prev)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: const Border(left: BorderSide(color: C.gold, width: 3)), color: Theme.of(context).cardTheme.color),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${nice(p.date)}${p.time != null ? ' · ${p.time}' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      if (p.points.isEmpty) const Text('पॉइंट्स नाहीत'),
                      ...p.points.map((x) => Text('${x.d ? '✔️' : '⏳'} ${x.t}')),
                    ]),
                  ),
              ],
              const Section('🔁 पुढची मीटिंग ठरवा'),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () async {
                        final d = await pickDate(context, nextDate);
                        if (d != null) setState(() => nextDate = d);
                      },
                      child: Text(nice(nextDate))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                      onPressed: () async {
                        final t = await pickTime(context, nextTime);
                        if (t != null) setState(() => nextTime = t);
                      },
                      child: Text(nextTime)),
                ),
              ]),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: C.green),
                onPressed: () async {
                  e.done = true;
                  final n = Item(
                      id: st.newId(),
                      type: 'meeting',
                      title: e.title.replaceAll(' (follow-up)', '') + ' (follow-up)',
                      date: nextDate,
                      time: nextTime,
                      series: e.series,
                      person: e.person,
                      phone: e.phone);
                  await st.add(n);
                  if (!context.mounted) return;
                  toast(context, '🔁 ${nice(nextDate)} $nextTime — मागचे पॉइंट्स तिथे दिसतील');
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MeetingPage(id: n.id)));
                },
                child: const Text('पुढची मीटिंग सेव्ह करा'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  e.done = !e.done;
                  st.save();
                },
                child: Text(e.done ? '↺ परत उघडा' : '✔ मीटिंग झाली'),
              ),
            ]),
          );
        },
      );

  void addPoint(Item e) {
    final v = point.text.trim();
    if (v.isEmpty) return;
    e.points.add(Point(v));
    point.clear();
    Store.I.save(reschedule: false);
  }
}
