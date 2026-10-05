import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'util.dart';
import 'screens/meeting.dart';
import 'screens/trip.dart';
import 'screens/forms.dart';

void toast(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)));
}

Future<void> copyText(BuildContext c, String t) async {
  await Clipboard.setData(ClipboardData(text: t));
  if (c.mounted) toast(c, '📋 कॉपी झालं');
}

Future<void> openUrl(BuildContext c, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && c.mounted) toast(c, 'उघडता आलं नाही');
}

Future<void> openWhatsApp(BuildContext c, String phone, String text) =>
    openUrl(c, 'https://wa.me/${waNumber(phone)}?text=${Uri.encodeComponent(text)}');

Future<void> openEmail(BuildContext c, String subject, String body) =>
    openUrl(c, 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');

Future<String?> pickDate(BuildContext c, String initial) async {
  final d = await showDatePicker(
      context: c, initialDate: parseKey(initial) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
  return d == null ? null : dkey(d);
}

Future<String?> pickTime(BuildContext c, String? initial) async {
  final p = (initial ?? '10:00').split(':');
  final t = await showTimePicker(context: c, initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])));
  return t == null ? null : '${two(t.hour)}:${two(t.minute)}';
}

Future<bool> confirm(BuildContext c, String title, {String ok = 'हो, डिलीट'}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (_) => AlertDialog(
      title: Text(title),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('नको')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: C.red), onPressed: () => Navigator.pop(c, true), child: Text(ok)),
      ],
    ),
  );
  return r == true;
}

class Section extends StatelessWidget {
  final String text;
  final Color? color;
  final Widget? trailing;
  const Section(this.text, {super.key, this.color, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Row(children: [
          Expanded(child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color ?? headColor(context)))),
          if (trailing != null) trailing!,
        ]),
      );
}

class Empty extends StatelessWidget {
  final String text;
  const Empty(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(text, style: TextStyle(color: Theme.of(context).hintColor)));
}

class AiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  const AiButton(this.label, {super.key, this.onTap, this.busy = false});
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onTap == null || busy ? .6 : 1,
        child: Container(
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [C.aiA, C.aiB]), borderRadius: BorderRadius.circular(22)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: busy ? null : onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Copy / WhatsApp / Email / Share row for any text.
class ShareBar extends StatelessWidget {
  final String Function() text;
  final String subject;
  const ShareBar({super.key, required this.text, required this.subject});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 6, children: [
        ActionChip(avatar: const Text('📋'), label: const Text('Copy'), onPressed: () => copyText(context, text())),
        ActionChip(avatar: const Text('📲'), label: const Text('WhatsApp'), onPressed: () => openUrl(context, 'https://wa.me/?text=${Uri.encodeComponent(text())}')),
        ActionChip(avatar: const Text('✉️'), label: const Text('Email'), onPressed: () => openEmail(context, subject, text())),
        ActionChip(avatar: const Text('↗️'), label: const Text('Share'), onPressed: () => Share.share(text())),
      ]);
}

/// Editable AI result box with share bar.
class ResultBox extends StatelessWidget {
  final TextEditingController ctrl;
  final String subject;
  const ResultBox({super.key, required this.ctrl, required this.subject});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 10),
        TextField(controller: ctrl, maxLines: null, minLines: 4, decoration: const InputDecoration(helperText: 'हवं तर edit करा')),
        const SizedBox(height: 6),
        ShareBar(text: () => ctrl.text, subject: subject),
      ]);
}

Future<void> reschedule(BuildContext c, Item e) async {
  final d = await pickDate(c, daysFrom(1));
  if (d == null || !c.mounted) return;
  final t = await pickTime(c, e.time);
  e.date = d;
  if (t != null) e.time = t;
  await Store.I.save();
  if (c.mounted) toast(c, '🔁 ${nice(d)}${e.time != null ? ' ${e.time}' : ''} ला ढकललं');
}

void taskActions(BuildContext c, Item e) {
  showModalBottomSheet(
    context: c,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.edit), title: const Text('Edit'), onTap: () {
          Navigator.pop(c);
          Navigator.push(c, MaterialPageRoute(builder: (_) => ItemFormPage(type: e.type, edit: e)));
        }),
        ListTile(leading: Icon(e.priority > 0 ? Icons.star : Icons.star_border), title: Text(e.priority > 0 ? 'Priority काढा' : '⭐ Priority द्या'), onTap: () {
          e.priority = e.priority > 0 ? 0 : 1;
          Store.I.save(reschedule: false);
          Navigator.pop(c);
        }),
        ListTile(leading: const Icon(Icons.update), title: const Text('🔁 पुढे ढकला'), onTap: () {
          Navigator.pop(c);
          reschedule(c, e);
        }),
        ListTile(leading: const Icon(Icons.delete_outline, color: C.red), title: const Text('डिलीट', style: TextStyle(color: C.red)), onTap: () async {
          Navigator.pop(c);
          if (await confirm(c, 'डिलीट करायचं?')) Store.I.remove(e.id);
        }),
      ]),
    ),
  );
}

class ItemTile extends StatelessWidget {
  final Item e;
  final bool missed;
  final String? countdown;
  const ItemTile(this.e, {super.key, this.missed = false, this.countdown});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hint = Theme.of(context).hintColor;
    Color? bg;
    String icon = '';
    String meta = '${dayLabel(e.date)}${e.time != null ? ' · ⏰ ${e.time}' : ''}${e.person.isNotEmpty ? ' · 👤 ${e.person}' : ''}';
    if (e.type == 'meeting') {
      bg = dark ? C.meetingD : C.meetingL;
      icon = '🤝';
      meta += ' · ${e.points.length} पॉइंट्स';
    } else if (e.type == 'trip') {
      bg = dark ? C.tripD : C.tripL;
      icon = '✈️';
      meta = '${dayLabel(e.date)} · ${e.trip.where((i) => i.d).length}/${e.trip.length} बुकिंग पूर्ण';
    }
    void open() {
      if (e.type == 'meeting') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingPage(id: e.id)));
      } else if (e.type == 'trip') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TripPage(id: e.id)));
      } else {
        taskActions(context, e);
      }
    }

    return Card(
      color: bg,
      shape: missed
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: C.red))
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: open,
        onLongPress: () => taskActions(context, e),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          child: Row(children: [
            if (e.type == 'task')
              Checkbox(value: e.done, shape: const CircleBorder(), onChanged: (_) {
                e.done = !e.done;
                Store.I.save();
              })
            else
              Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(icon, style: const TextStyle(fontSize: 22))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (countdown != null)
                    Text('⏳ $countdown', style: const TextStyle(color: C.gold, fontWeight: FontWeight.w700, fontSize: 12)),
                  Text(e.title + (e.priority > 0 ? '  ⭐' : ''),
                      style: TextStyle(
                          fontSize: 15,
                          decoration: e.done ? TextDecoration.lineThrough : null,
                          color: e.done ? hint : null)),
                  const SizedBox(height: 2),
                  Text(meta, style: TextStyle(fontSize: 12, color: hint)),
                  if (missed)
                    Row(children: [
                      TextButton(onPressed: () {
                        e.done = true;
                        Store.I.save();
                      }, child: const Text('✔ झालं')),
                      TextButton(onPressed: () => reschedule(context, e), child: const Text('🔁 पुढे ढकला')),
                    ]),
                ]),
              ),
            ),
            if (e.type != 'task') Icon(Icons.chevron_right, color: hint),
          ]),
        ),
      ),
    );
  }
}
