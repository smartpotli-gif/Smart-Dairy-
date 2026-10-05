import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ai.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'forms.dart';
import 'notes.dart';
import 'settings.dart';
import 'summary.dart';
import 'trip.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Store.I,
        builder: (context, _) {
          final s = Store.I.s;
          final pages = [const TodayTab(), const CalendarTab(), const TasksTab(), const NotesTab(), const MoreTab()];
          return Scaffold(
            appBar: AppBar(
              titleSpacing: 18,
              title: Text('Smart Diary', style: TextStyle(fontWeight: FontWeight.w800, color: headColor(context))),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
                    child: CircleAvatar(
                      backgroundColor: C.gold,
                      child: Text(s.name.isEmpty ? '?' : s.name.characters.first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
            body: pages[tab],
            bottomNavigationBar: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (i) => setState(() => tab = i),
              destinations: [
                NavigationDestination(icon: const Icon(Icons.today_outlined), selectedIcon: const Icon(Icons.today), label: tr('आज')),
                NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: tr('कॅलेंडर')),
                NavigationDestination(icon: const Icon(Icons.check_circle_outline), selectedIcon: const Icon(Icons.check_circle), label: tr('कामं')),
                NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: tr('नोट्स')),
                NavigationDestination(icon: const Icon(Icons.more_horiz), label: tr('अधिक')),
              ],
            ),
          );
        },
      );
}

class TodayTab extends StatefulWidget {
  const TodayTab({super.key});
  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  final input = TextEditingController();
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> quickAdd() async {
    final t = input.text.trim();
    if (t.isEmpty) return;
    final p = parseNatural(t);
    final st = Store.I;
    await st.add(Item(id: st.newId(), type: p.type, title: p.title, date: p.date, time: p.time));
    input.clear();
    if (mounted) toast(context, '${p.type == 'meeting' ? '🤝 मीटिंग' : '✅ काम'} — ${dayLabel(p.date)}${p.time != null ? ' · ⏰ ${p.time}' : ''}');
  }

  @override
  Widget build(BuildContext context) {
    final st = Store.I, today = todayKey(), hm = nowHM();
    final missed = sortItems(st.items.where(isMissed).toList());
    final todays = st.timedOn(today);
    final next = todays.where((e) => !e.done && (e.time == null || e.time!.compareTo(hm) >= 0)).toList();
    final done = todays.where((e) => e.done).toList();
    final coming = sortItems(st.items.where((e) => (e.type == 'meeting' || e.type == 'trip') && !e.done && e.date.compareTo(today) > 0).toList()).take(4).toList();
    Widget quick(String icon, String label, VoidCallback f, {bool ai = false}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: ai ? null : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: ai ? BoxDecoration(gradient: const LinearGradient(colors: [C.aiA, C.aiB]), borderRadius: BorderRadius.circular(14)) : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: f,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(children: [
                      Text(icon, style: const TextStyle(fontSize: 20)),
                      Text(label, style: TextStyle(fontSize: 11, color: ai ? Colors.white : null)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 28), children: [
      Text('${tr('आज')} · $hm', style: TextStyle(color: Theme.of(context).hintColor)),
      Text(DateFormat('EEEE, d MMMM').format(DateTime.now()), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: headColor(context))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextField(
            controller: input,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => quickAdd(),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.add), hintText: tr('उदा. आज 2 वाजता मीटिंग आहे')),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: quickAdd, icon: const Icon(Icons.arrow_upward), style: IconButton.styleFrom(backgroundColor: C.green)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        quick('🤝', tr('मीटिंग'), () => go(const ItemFormPage(type: 'meeting'))),
        quick('📝', tr('नोट'), () => go(const NoteEditPage())),
        quick('📋', 'Summary', () => go(const SummaryPage())),
        quick('✈️', tr('ट्रिप'), () => go(const TripFormPage())),
        if (Store.I.s.aiOn) quick('✨', 'AI', () => go(const AskAiPage()), ai: true),
      ]),
      if (missed.isNotEmpty) ...[
        Section('🔴 ${tr('चुकलेलं')} (${missed.length})', color: C.red),
        ...missed.map((e) => ItemTile(e, missed: true)),
      ],
      Section('⏰ ${tr('आता पुढे')}'),
      if (next.isEmpty) Empty(tr('आज पुढे काही नाही.')),
      for (var i = 0; i < next.length; i++) ItemTile(next[i], countdown: i == 0 && next[i].time != null ? timeLeft(next[i].time!) : null),
      if (coming.isNotEmpty) ...[Section('📅 ${tr('पुढे येणारं')}'), ...coming.map((e) => ItemTile(e))],
      if (done.isNotEmpty) ...[
        Section('✔ ${tr('झालेलं')} (${done.length})', color: Theme.of(context).hintColor),
        Opacity(opacity: .6, child: Column(children: done.map((e) => ItemTile(e)).toList())),
      ],
      if (DateTime.now().hour >= Store.I.s.eodHour) ...[
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: () => showEod(context), child: const Padding(padding: EdgeInsets.all(12), child: Text('🌙 दिवसाचा शेवट करा'))),
      ],
      if (!AI.ready && Store.I.s.aiOn) ...[
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Text('✨', style: TextStyle(fontSize: 22)),
            title: const Text('AI चालू करा (मोफत)'),
            subtitle: const Text('Settings मध्ये Gemini key टाका'),
            onTap: () => go(const SettingsPage()),
          ),
        ),
      ],
    ]);
  }
}

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});
  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  String sel = todayKey();
  @override
  Widget build(BuildContext context) {
    final st = Store.I;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = DateTime(month.year, month.month, 1).weekday % 7;
    final has = st.items.map((e) => e.date).toSet();
    final list = st.items.where((e) => e.date == sel).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 28), children: [
      Row(children: [
        IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
        Expanded(child: Center(child: Text(DateFormat('MMMM yyyy').format(month), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: headColor(context))))),
        IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right)),
      ]),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final d in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) Center(child: Text(d, style: TextStyle(color: Theme.of(context).hintColor))),
          for (var i = 0; i < lead; i++) const SizedBox(),
          for (var d = 1; d <= days; d++)
            Builder(builder: (_) {
              final k = dkey(DateTime(month.year, month.month, d));
              final isSel = k == sel;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => sel = k),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: isSel ? C.green : null, borderRadius: BorderRadius.circular(12)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$d', style: TextStyle(color: isSel ? Colors.white : null, fontWeight: k == todayKey() ? FontWeight.w800 : null)),
                    if (has.contains(k)) Container(width: 5, height: 5, decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle)),
                  ]),
                ),
              );
            }),
        ],
      ),
      Section(nice(sel)),
      if (list.isEmpty) const Empty('या दिवशी काही नाही.'),
      ...list.map((e) => e.isNote ? NoteTile(e) : ItemTile(e)),
    ]);
  }
}

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});
  @override
  Widget build(BuildContext context) {
    final all = sortItems(Store.I.items.where((e) => !e.isNote).toList());
    final pending = all.where((e) => !e.done).toList();
    final done = all.where((e) => e.done).toList().reversed.take(30).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 90), children: [
      Section('⏳ ${tr('बाकी')} (${pending.length})', trailing: TextButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemFormPage(type: 'task'))),
        icon: const Icon(Icons.add), label: const Text('काम'),
      )),
      if (pending.isEmpty) const Empty('सगळं झालं 🎉'),
      ...pending.map((e) => ItemTile(e, missed: isMissed(e))),
      Section('✔ ${tr('पूर्ण')}', color: Theme.of(context).hintColor),
      if (done.isEmpty) const Empty('अजून काही नाही.'),
      ...done.map((e) => Opacity(opacity: .6, child: ItemTile(e))),
    ]);
  }
}
