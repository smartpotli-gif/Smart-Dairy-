import 'package:flutter/material.dart';
import '../ai.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'people.dart';

class NoteTile extends StatelessWidget {
  final Item e;
  const NoteTile(this.e, {super.key});
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteViewPage(id: e.id))),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (e.kind == 'summary')
                    Text('📋 Summary${e.person.isNotEmpty ? ' · ${e.person}' : ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  Text(e.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5)),
                  if (e.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(spacing: 4, runSpacing: 4, children: e.tags.map((t) => _Tag(t)).toList()),
                    ),
                ]),
              ),
              if (e.pinned) const Text('📌'),
            ]),
          ),
        ),
      );
}

class _Tag extends StatelessWidget {
  final String t;
  const _Tag(this.t);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: C.softGold.withOpacity(.6), borderRadius: BorderRadius.circular(10)),
        child: Text('#$t', style: const TextStyle(fontSize: 11, color: Colors.black87)),
      );
}

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});
  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  String q = '', tag = '';
  final Set<String> open = {};
  bool init = false;
  final keys = <String, GlobalKey>{};
  final wk = TextEditingController();
  bool wkBusy = false, wkShow = false;

  Future<void> jump() async {
    final d = await pickDate(context, todayKey());
    if (d == null) return;
    setState(() => open.add(d));
    await Future.delayed(const Duration(milliseconds: 80));
    final k = keys[d];
    if (k?.currentContext != null) {
      Scrollable.ensureVisible(k!.currentContext!, duration: const Duration(milliseconds: 350));
    } else if (mounted) {
      toast(context, '${nice(d)} ला नोट्स नाहीत');
    }
  }

  Future<void> week() async {
    final notes = Store.I.notes.where((e) => e.date.compareTo(daysFrom(-7)) >= 0).map((e) => '${e.date}: ${e.content}').join('\n\n');
    if (notes.isEmpty) {
      toast(context, 'या आठवड्यात नोट्स नाहीत');
      return;
    }
    setState(() {
      wkBusy = true;
      wkShow = true;
      wk.text = '✨ विचार करतोय…';
    });
    try {
      wk.text = await AI.ask('${AI.header()}\nया आठवड्याच्या माझ्या business नोट्सचा ${AI.lang()} छोटा सारांश दे: मुख्य गोष्टी, ठरलेले निर्णय, बाकी कामं.\n\n${AI.clean(notes)}');
    } catch (e) {
      wk.text = e.toString();
    }
    if (mounted) setState(() => wkBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final all = Store.I.notes;
    final tags = {for (final e in all) ...e.tags}.toList();
    final list = all.where((e) {
      if (tag.isNotEmpty && !e.tags.contains(tag)) return false;
      if (q.isEmpty) return true;
      return '${e.content} ${e.tags.join(' ')} ${e.person}'.toLowerCase().contains(q.toLowerCase());
    }).toList();
    final pins = list.where((e) => e.pinned).toList();
    final rest = list.where((e) => !e.pinned).toList();
    final days = rest.map((e) => e.date).toSet().toList()..sort((a, b) => b.compareTo(a));
    if (!init) {
      open.addAll(days.take(2));
      init = true;
    }
    final searching = q.isNotEmpty || tag.isNotEmpty;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.green,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteEditPage())),
        icon: const Icon(Icons.add),
        label: Text(tr('नोट')),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 90), children: [
        Row(children: [
          Expanded(child: TextField(onChanged: (v) => setState(() => q = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr('शोधा…')))),
          IconButton(tooltip: 'तारखेवर जा', onPressed: jump, icon: const Icon(Icons.event)),
        ]),
        if (tags.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final t in tags)
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 6),
                  child: FilterChip(label: Text('#$t'), selected: tag == t, onSelected: (_) => setState(() => tag = tag == t ? '' : t)),
                ),
            ]),
          ),
        if (AI.ready && !searching) ...[
          const SizedBox(height: 10),
          AiButton('✨ या आठवड्याचा सारांश', busy: wkBusy, onTap: week),
          if (wkShow) ResultBox(ctrl: wk, subject: 'आठवड्याचा सारांश'),
        ],
        if (pins.isNotEmpty) ...[const Section('📌 Pinned'), ...pins.map((e) => NoteTile(e))],
        for (final d in days) ...[
          InkWell(
            key: keys.putIfAbsent(d, () => GlobalKey()),
            onTap: () => setState(() => open.contains(d) ? open.remove(d) : open.add(d)),
            child: Container(
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
              child: Row(children: [
                Icon(searching || open.contains(d) ? Icons.expand_more : Icons.chevron_right, color: headColor(context)),
                Text(dayLabel(d), style: TextStyle(fontWeight: FontWeight.w700, color: headColor(context), fontSize: 15)),
                if (dayLabel(d) != nice(d)) Text('  ${nice(d)}', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                const Spacer(),
                Text('${rest.where((e) => e.date == d).length} नोट्स', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
              ]),
            ),
          ),
          if (searching || open.contains(d)) ...rest.where((e) => e.date == d).map((e) => NoteTile(e)),
        ],
        if (list.isEmpty) const Empty('काही सापडलं नाही.'),
      ]),
    );
  }
}

class NoteViewPage extends StatefulWidget {
  final int id;
  const NoteViewPage({super.key, required this.id});
  @override
  State<NoteViewPage> createState() => _NoteViewPageState();
}

class _NoteViewPageState extends State<NoteViewPage> {
  final ai = TextEditingController();
  bool busy = false, show = false;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Store.I,
        builder: (context, _) {
          final e = Store.I.byId(widget.id);
          if (e == null) return const Scaffold(body: Center(child: Text('नोट डिलीट झाली.')));
          final lines = e.content.split('\n');
          return Scaffold(
            appBar: AppBar(title: Text('${dayLabel(e.date)} · ${nice(e.date)}'), actions: [
              IconButton(icon: Icon(e.pinned ? Icons.push_pin : Icons.push_pin_outlined), onPressed: () {
                e.pinned = !e.pinned;
                Store.I.save(reschedule: false);
              }),
              IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditPage(edit: e)))),
              IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirm(context, 'ही नोट डिलीट करायची?')) {
                      await Store.I.remove(e.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }),
            ]),
            body: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 40), children: [
              if (e.person.isNotEmpty)
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonPage(name: e.person))),
                  child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('👤 ${e.person}', style: const TextStyle(color: C.gold, fontWeight: FontWeight.w600))),
                ),
              for (var i = 0; i < lines.length; i++)
                if (lines[i].startsWith('☐') || lines[i].startsWith('☑'))
                  InkWell(
                    onTap: () {
                      final l = e.content.split('\n');
                      l[i] = (l[i].startsWith('☐') ? '☑' : '☐') + l[i].substring(1);
                      e.content = l.join('\n');
                      Store.I.save(reschedule: false);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Icon(lines[i].startsWith('☑') ? Icons.check_box : Icons.check_box_outline_blank, color: C.green),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(lines[i].substring(1).trim(),
                                style: TextStyle(fontSize: 16, decoration: lines[i].startsWith('☑') ? TextDecoration.lineThrough : null))),
                      ]),
                    ),
                  )
                else
                  SelectableText(lines[i].isEmpty ? ' ' : lines[i], style: const TextStyle(fontSize: 16, height: 1.5)),
              if (e.tags.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(spacing: 6, children: e.tags.map((t) => _Tag(t)).toList())),
              const SizedBox(height: 16),
              ShareBar(text: () => e.content, subject: 'Note — ${nice(e.date)}'),
              if (AI.ready) ...[
                const SizedBox(height: 14),
                AiButton('✨ मुख्य मुद्दे', busy: busy, onTap: () async {
                  setState(() {
                    busy = true;
                    show = true;
                    ai.text = '✨ विचार करतोय…';
                  });
                  try {
                    ai.text = await AI.ask('${AI.header()}\nया नोटचे मुख्य मुद्दे ${AI.lang()} 3-5 ओळींत दे:\n\n${AI.clean(e.content)}');
                  } catch (err) {
                    ai.text = err.toString();
                  }
                  if (mounted) setState(() => busy = false);
                }),
                if (show) ResultBox(ctrl: ai, subject: 'मुख्य मुद्दे'),
              ],
            ]),
          );
        },
      );
}

class NoteEditPage extends StatefulWidget {
  final Item? edit;
  final String? prefill;
  const NoteEditPage({super.key, this.edit, this.prefill});
  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  late final text = TextEditingController(text: widget.edit?.content ?? widget.prefill ?? '');
  late final tags = TextEditingController(text: widget.edit?.tags.join(', ') ?? '');
  late String date = widget.edit?.date ?? todayKey();

  void addCheck() {
    final t = text.text;
    text.text = '$t${t.isEmpty || t.endsWith('\n') ? '' : '\n'}☐ ';
    text.selection = TextSelection.collapsed(offset: text.text.length);
  }

  Future<void> save() async {
    final v = text.text.trim();
    if (v.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final tg = tags.text.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
    final st = Store.I;
    if (widget.edit != null) {
      widget.edit!
        ..content = v
        ..tags = tg
        ..date = date;
      await st.save(reschedule: false);
    } else {
      await st.add(Item(id: st.newId(), type: 'note', content: v, tags: tg, date: date));
    }
    if (mounted) {
      toast(context, '📝 नोट सेव्ह');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.edit == null ? '📝 नवीन नोट' : '✏️ नोट edit'), actions: [
          TextButton(onPressed: save, child: const Text('सेव्ह', style: TextStyle(fontWeight: FontWeight.w700))),
        ]),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          TextField(controller: text, autofocus: true, maxLines: null, minLines: 10, decoration: const InputDecoration(hintText: 'काहीही लिहा… (कीबोर्डवरचा 🎤 वापरून बोलूनही लिहा)')),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ActionChip(avatar: const Text('☐'), label: const Text('Checklist ओळ'), onPressed: addCheck),
            ActionChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(nice(date)),
                onPressed: () async {
                  final d = await pickDate(context, date);
                  if (d != null) setState(() => date = d);
                }),
          ]),
          const SizedBox(height: 12),
          TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags (स्वल्पविरामाने)', hintText: 'उदा. काम, CEO, CA')),
          const SizedBox(height: 20),
          FilledButton(onPressed: save, style: FilledButton.styleFrom(backgroundColor: C.green, padding: const EdgeInsets.all(14)), child: const Text('सेव्ह करा')),
        ]),
      );
}
