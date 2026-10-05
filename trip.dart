import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

class TripFormPage extends StatefulWidget {
  const TripFormPage({super.key});
  @override
  State<TripFormPage> createState() => _TripFormPageState();
}

class _TripFormPageState extends State<TripFormPage> {
  final title = TextEditingController();
  String date = daysFrom(7);
  bool useTpl = true;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('✈️ नवीन ट्रिप')),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'ट्रिपचं नाव', hintText: 'उदा. Delhi ट्रिप')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: () async {
                final d = await pickDate(context, date);
                if (d != null) setState(() => date = d);
              },
              icon: const Icon(Icons.event),
              label: Text('प्रवासाची तारीख: ${nice(date)}')),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: useTpl,
              onChanged: (v) => setState(() => useTpl = v),
              title: const Text('फ्लाइट, हॉटेल, कॅब, व्हिसा, Insurance यादी आपोआप टाका')),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.green, padding: const EdgeInsets.all(14)),
            onPressed: () async {
              if (title.text.trim().isEmpty) {
                toast(context, 'नाव टाका');
                return;
              }
              final st = Store.I;
              final t = Item(
                  id: st.newId(),
                  type: 'trip',
                  title: title.text.trim(),
                  date: date,
                  trip: useTpl ? tripTemplate.map((k) => TripItem(k: k, date: date)).toList() : []);
              await st.add(t);
              if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TripPage(id: t.id)));
            },
            child: const Text('सेव्ह करा'),
          ),
        ]),
      );
}

class TripPage extends StatelessWidget {
  final int id;
  const TripPage({super.key, required this.id});

  Future<void> editItem(BuildContext context, Item t, int? i) async {
    final it = i == null ? TripItem(k: '', date: t.date) : t.trip[i];
    final k = TextEditingController(text: it.k), detail = TextEditingController(text: it.detail);
    String date = it.date, time = it.time;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(c).viewInsets.bottom + 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: k, decoration: const InputDecoration(labelText: 'प्रकार (उदा. ✈️ फ्लाइट)')),
            const SizedBox(height: 10),
            TextField(controller: detail, decoration: const InputDecoration(labelText: 'तपशील (PNR, हॉटेल, vendor…)')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () async {
                        final d = await pickDate(c, date);
                        if (d != null) set(() => date = d);
                      },
                      child: Text(nice(date)))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () async {
                        final x = await pickTime(c, time.isEmpty ? null : time);
                        if (x != null) set(() => time = x);
                      },
                      child: Text(time.isEmpty ? 'वेळ' : time))),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: C.green),
                onPressed: () {
                  if (k.text.trim().isEmpty) return;
                  it
                    ..k = k.text.trim()
                    ..detail = detail.text.trim()
                    ..date = date
                    ..time = time;
                  if (i == null) t.trip.add(it);
                  Store.I.save();
                  Navigator.pop(c);
                },
                child: const Text('सेव्ह'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Store.I,
        builder: (context, _) {
          final st = Store.I;
          final t = st.byId(id);
          if (t == null) return const Scaffold(body: Center(child: Text('ही ट्रिप डिलीट झाली.')));
          String summary() =>
              '${t.title} — ${nice(t.date)}\n${t.trip.map((i) => '${i.d ? '✅' : '⏳'} ${i.k}${i.detail.isNotEmpty ? ': ${i.detail}' : ''}${i.time.isNotEmpty ? ' (${nice(i.date)} ${i.time})' : ''}').join('\n')}';
          return Scaffold(
            appBar: AppBar(title: Text('✈️ ${t.title}'), actions: [
              IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirm(context, 'ही ट्रिप डिलीट करायची?')) {
                      await st.remove(t.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }),
            ]),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () => editItem(context, t, null), backgroundColor: C.green, foregroundColor: Colors.white, icon: const Icon(Icons.add), label: const Text('बुकिंग')),
            body: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 90), children: [
              Text(nice(t.date), style: TextStyle(color: Theme.of(context).hintColor)),
              const Section('बुकिंग्स'),
              if (t.trip.isEmpty) const Empty('खाली + बुकिंग दाबा.'),
              for (var i = 0; i < t.trip.length; i++)
                Card(
                  child: ListTile(
                    leading: Checkbox(value: t.trip[i].d, onChanged: (_) {
                      t.trip[i].d = !t.trip[i].d;
                      st.save();
                    }),
                    title: Text(t.trip[i].k, style: TextStyle(decoration: t.trip[i].d ? TextDecoration.lineThrough : null)),
                    subtitle: Text([
                      if (t.trip[i].detail.isNotEmpty) t.trip[i].detail,
                      if (t.trip[i].time.isNotEmpty) '${nice(t.trip[i].date)} · ${t.trip[i].time} (1 तास आधी रिमाइंडर)',
                    ].join('\n')),
                    onTap: () => editItem(context, t, i),
                    trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () {
                      t.trip.removeAt(i);
                      st.save();
                    }),
                  ),
                ),
              const Section('📤 शेअर'),
              ShareBar(text: summary, subject: t.title),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () {
                t.done = !t.done;
                st.save();
              }, child: Text(t.done ? '↺ परत उघडा' : '✔ ट्रिप पूर्ण')),
            ]),
          );
        },
      );
}

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Store.I,
        builder: (context, _) {
          final l = sortItems(Store.I.items.where((e) => e.type == 'trip').toList()).reversed.toList();
          return Scaffold(
            appBar: AppBar(title: const Text('✈️ Trips')),
            floatingActionButton: FloatingActionButton(
                backgroundColor: C.green,
                foregroundColor: Colors.white,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripFormPage())),
                child: const Icon(Icons.add)),
            body: ListView(padding: const EdgeInsets.all(18), children: [
              if (l.isEmpty) const Empty('अजून ट्रिप नाही.'),
              ...l.map((e) => ItemTile(e)),
            ]),
          );
        },
      );
}
