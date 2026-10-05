import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

/// Add / edit a task or meeting.
class ItemFormPage extends StatefulWidget {
  final String type;
  final Item? edit;
  final String? date;
  const ItemFormPage({super.key, required this.type, this.edit, this.date});
  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  late final title = TextEditingController(text: widget.edit?.title ?? '');
  late final person = TextEditingController(text: widget.edit?.person ?? '');
  late final phone = TextEditingController(text: widget.edit?.phone ?? '');
  late String date = widget.edit?.date ?? widget.date ?? todayKey();
  late String? time = widget.edit?.time ?? (widget.type == 'meeting' ? '14:00' : null);
  late bool priority = (widget.edit?.priority ?? 0) > 0;
  String tpl = '';

  bool get meeting => widget.type == 'meeting';

  Future<void> save() async {
    final t = title.text.trim();
    if (t.isEmpty) {
      toast(context, 'नाव टाका');
      return;
    }
    final st = Store.I;
    final e = widget.edit;
    if (e != null) {
      e
        ..title = t
        ..date = date
        ..time = time
        ..person = person.text.trim()
        ..phone = phone.text.trim()
        ..priority = priority ? 1 : 0;
      st.upsertContact(e.person, e.phone);
      await st.save();
    } else {
      await st.add(Item(
        id: st.newId(),
        type: widget.type,
        title: t,
        date: date,
        time: time,
        person: person.text.trim(),
        phone: phone.text.trim(),
        priority: priority ? 1 : 0,
        points: (meetingTemplates[tpl] ?? []).map((x) => Point(x)).toList(),
      ));
    }
    if (mounted) {
      toast(context, time != null ? '✔ सेव्ह — ⏰ रिमाइंडर लागला' : '✔ सेव्ह');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = Store.I.contacts;
    return Scaffold(
      appBar: AppBar(title: Text(widget.edit != null ? 'Edit' : meeting ? '🤝 नवीन मीटिंग' : '✅ नवीन काम')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        if (meeting && widget.edit == null) ...[
          const Text('Template', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('रिकामी'), selected: tpl.isEmpty, onSelected: (_) => setState(() => tpl = '')),
            for (final k in meetingTemplates.keys)
              ChoiceChip(
                label: Text(k),
                selected: tpl == k,
                onSelected: (_) => setState(() {
                  tpl = k;
                  if (title.text.isEmpty) title.text = k;
                }),
              ),
          ]),
          const SizedBox(height: 14),
        ],
        TextField(controller: title, autofocus: widget.edit == null, decoration: InputDecoration(labelText: meeting ? 'मीटिंगचं नाव' : 'काम')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final d = await pickDate(context, date);
                if (d != null) setState(() => date = d);
              },
              icon: const Icon(Icons.event),
              label: Text(nice(date)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final t = await pickTime(context, time);
                if (t != null) setState(() => time = t);
              },
              icon: const Icon(Icons.schedule),
              label: Text(time ?? 'वेळ (optional)'),
            ),
          ),
          if (time != null) IconButton(onPressed: () => setState(() => time = null), icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 12),
        TextField(controller: person, decoration: const InputDecoration(labelText: 'कोणासोबत / कोणासाठी (optional)'), onChanged: (v) {
          final c = Store.I.contact(v.trim());
          if (c != null && c.phone.isNotEmpty) phone.text = c.phone;
        }),
        if (contacts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(spacing: 6, children: [
              for (final c in contacts.take(8))
                ActionChip(label: Text(c.name), onPressed: () => setState(() {
                  person.text = c.name;
                  phone.text = c.phone;
                })),
            ]),
          ),
        if (meeting) ...[
          const SizedBox(height: 12),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp नंबर (optional)')),
        ],
        if (!meeting)
          SwitchListTile(contentPadding: EdgeInsets.zero, value: priority, onChanged: (v) => setState(() => priority = v), title: const Text('⭐ Priority')),
        const SizedBox(height: 20),
        FilledButton(onPressed: save, style: FilledButton.styleFrom(backgroundColor: C.green, padding: const EdgeInsets.all(14)), child: const Text('सेव्ह करा')),
      ]),
    );
  }
}
