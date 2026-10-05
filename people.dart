import 'package:flutter/material.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'notes.dart';
import 'summary.dart';

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Store.I,
        builder: (context, _) {
          final st = Store.I;
          final l = [...st.contacts]..sort((a, b) => a.name.compareTo(b.name));
          return Scaffold(
            appBar: AppBar(title: const Text('👥 Contacts')),
            body: ListView(padding: const EdgeInsets.all(18), children: [
              if (l.isEmpty) const Empty('मीटिंग किंवा Summary मध्ये नाव टाकलं की इथे येईल.'),
              for (final c in l)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: C.softGold, child: Text(c.name.characters.first)),
                    title: Text(c.name),
                    subtitle: Text('${c.phone}  ·  ${st.items.where((e) => e.person == c.name).length} नोंदी'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonPage(name: c.name))),
                  ),
                ),
            ]),
          );
        },
      );
}

class PersonPage extends StatelessWidget {
  final String name;
  const PersonPage({super.key, required this.name});

  Future<void> editContact(BuildContext context) async {
    final st = Store.I;
    st.upsertContact(name, '');
    final c = st.contact(name)!;
    final phone = TextEditingController(text: c.phone), company = TextEditingController(text: c.company);
    await showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'नंबर')),
          const SizedBox(height: 10),
          TextField(controller: company, decoration: const InputDecoration(labelText: 'कंपनी')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                c.phone = phone.text.trim();
                c.company = company.text.trim();
                st.save(reschedule: false);
                Navigator.pop(d);
              },
              child: const Text('सेव्ह')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Store.I,
        builder: (context, _) {
          final st = Store.I;
          final c = st.contact(name);
          final meetings = sortItems(st.items.where((e) => e.type == 'meeting' && e.person == name).toList()).reversed.toList();
          final tasks = st.items.where((e) => e.type == 'task' && !e.done && e.person == name).toList();
          final sums = st.items.where((e) => e.isNote && e.person == name).toList().reversed.toList();
          return Scaffold(
            appBar: AppBar(title: Text('👤 $name'), actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () => editContact(context))]),
            body: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 40), children: [
              if (c != null && (c.phone.isNotEmpty || c.company.isNotEmpty))
                Text('${c.company}  ${c.phone}', style: TextStyle(color: Theme.of(context).hintColor)),
              const SizedBox(height: 10),
              Row(children: [
                if (c != null && c.phone.isNotEmpty) ...[
                  Expanded(
                      child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: C.wa), onPressed: () => openWhatsApp(context, c.phone, ''), child: const Text('📲 WhatsApp'))),
                  const SizedBox(width: 8),
                ],
                Expanded(
                    child: FilledButton.tonal(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SummaryPage(person: name))), child: const Text('📋 नवीन Summary'))),
              ]),
              Section('⏳ बाकी कामं (${tasks.length})'),
              if (tasks.isEmpty) const Empty('काही बाकी नाही.'),
              ...tasks.map((e) => ItemTile(e)),
              Section('🤝 मीटिंग्स (${meetings.length})'),
              if (meetings.isEmpty) const Empty('मीटिंग्स नाहीत.'),
              ...meetings.map((e) => ItemTile(e)),
              Section('📋 Summaries / नोट्स (${sums.length})'),
              if (sums.isEmpty) const Empty('अजून नाहीत.'),
              ...sums.map((e) => NoteTile(e)),
            ]),
          );
        },
      );
}
