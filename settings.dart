import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../ai.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'notes.dart';
import 'people.dart';
import 'summary.dart';
import 'trip.dart';

Future<void> backup(BuildContext c) async {
  try {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/SmartDiary-backup-${todayKey()}.json');
    await f.writeAsString(Store.I.backupJson());
    await Share.shareXFiles([XFile(f.path)], text: 'Smart Diary backup ${todayKey()}');
  } catch (_) {
    if (c.mounted) toast(c, 'Backup घेता आला नाही');
  }
}

Future<void> restore(BuildContext c) async {
  try {
    final r = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = r?.files.single.path;
    if (path == null) return;
    if (!c.mounted) return;
    if (!await confirm(c, 'सध्याचा डेटा बदलून backup मधला डेटा आणायचा?', ok: 'हो, आणा')) return;
    final ok = await Store.I.restore(await File(path).readAsString());
    if (c.mounted) toast(c, ok ? '♻️ Backup परत आणला' : 'ही Smart Diary backup फाइल नाही');
  } catch (_) {
    if (c.mounted) toast(c, 'फाइल वाचता आली नाही');
  }
}

void showEod(BuildContext c) {
  final st = Store.I;
  final pending = st.items.where((e) => e.type == 'task' && !e.done && e.date.compareTo(todayKey()) <= 0).toList();
  final note = TextEditingController();
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (s) => Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(s).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🌙 दिवसाचा शेवट', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: headColor(s))),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            const Text('आजची सगळी कामं पूर्ण 🎉')
          else ...[
            Text('${pending.length} कामं बाकी:'),
            ...pending.take(8).map((e) => Text('• ${e.title}')),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.green),
              onPressed: () {
                for (final e in pending) {
                  e.date = daysFrom(1);
                }
                st.save();
                Navigator.pop(s);
                toast(c, '➡️ ${pending.length} कामं उद्यावर');
              },
              child: const Text('सगळी उद्यावर ढकला ➡️'),
            ),
          ],
          const SizedBox(height: 14),
          TextField(controller: note, maxLines: 4, decoration: const InputDecoration(hintText: 'आज काय झालं… (डायरी नोंद)')),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              if (note.text.trim().isEmpty) return;
              st.add(Item(id: st.newId(), type: 'note', content: note.text.trim(), date: todayKey(), tags: ['दिवसाचा शेवट']));
              Navigator.pop(s);
              toast(c, '📝 नोंद सेव्ह');
            },
            child: const Text('नोंद सेव्ह करा'),
          ),
        ]),
      ),
    ),
  );
}

void pasteIn(BuildContext c) {
  final t = TextEditingController();
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (s) => Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(s).viewInsets.bottom + 18),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📥 मेसेजवरून नोंद', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Text('WhatsApp/Email मधला मजकूर कॉपी करून इथे पेस्ट करा.'),
        const SizedBox(height: 10),
        TextField(controller: t, maxLines: 6, autofocus: true),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(
              onPressed: () {
                Navigator.pop(s);
                Navigator.push(c, MaterialPageRoute(builder: (_) => NoteEditPage(prefill: t.text)));
              },
              child: const Text('📝 नोट')),
          FilledButton(
              onPressed: () {
                Navigator.pop(s);
                Navigator.push(c, MaterialPageRoute(builder: (_) => AskAiPage(prefill: t.text)));
              },
              child: const Text('✨ काम/मीटिंग')),
          FilledButton(
              onPressed: () {
                Navigator.pop(s);
                Navigator.push(c, MaterialPageRoute(builder: (_) => SummaryPage(text: t.text)));
              },
              child: const Text('📋 Summary')),
        ]),
      ]),
    ),
  );
}

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});
  @override
  Widget build(BuildContext context) {
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    Widget tile(String icon, String t, String sub, VoidCallback f) =>
        Card(child: ListTile(leading: Text(icon, style: const TextStyle(fontSize: 22)), title: Text(t), subtitle: sub.isEmpty ? null : Text(sub), onTap: f));
    return ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 28), children: [
      tile('👥', tr('Contacts'), 'व्यक्तीनुसार मीटिंग्स, summaries, बाकी कामं', () => go(const PeoplePage())),
      tile('✈️', tr('Trips'), 'फ्लाइट, हॉटेल, कॅब एकत्र', () => go(const TripsPage())),
      tile('📋', 'चर्चेचं Summary', 'CA, vendor सोबतच्या बोलण्याचा सारांश', () => go(const SummaryPage())),
      tile('📥', 'मेसेजवरून नोंद', 'WhatsApp/Email मधला मजकूर पेस्ट करा', () => pasteIn(context)),
      tile('🌙', 'दिवसाचा शेवट', '', () => showEod(context)),
      tile('💾', 'Backup घ्या', 'Drive / WhatsApp वर फाइल ठेवा', () => backup(context)),
      tile('♻️', 'Backup परत आणा', '', () => restore(context)),
      tile('⚙️', tr('Settings'), '', () => go(const SettingsPage())),
      const SizedBox(height: 16),
      Center(child: Text('Smart Diary · by Smart Potli', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12))),
    ]);
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final s = Store.I.s;
  late final name = TextEditingController(text: s.name);
  late final company = TextEditingController(text: s.company);
  late final key = TextEditingController(text: s.aiKey);
  late final model = TextEditingController(text: s.aiModel);
  bool testing = false;

  void save({bool reschedule = false}) => Store.I.save(reschedule: reschedule);

  Future<void> hourPick(int current, void Function(int) set) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: current, minute: 0));
    if (t != null) {
      setState(() => set(t.hour));
      save(reschedule: true);
    }
  }

  Future<void> setPin() async {
    final c = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('🔒 4 अंकी PIN'),
        content: TextField(controller: c, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, autofocus: true),
        actions: [
          if (s.pin.isNotEmpty) TextButton(onPressed: () => Navigator.pop(d, ''), child: const Text('लॉक काढा', style: TextStyle(color: C.red))),
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('सेव्ह')),
        ],
      ),
    );
    if (r == null) return;
    if (r.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(r)) {
      if (mounted) toast(context, '4 अंक टाका');
      return;
    }
    setState(() => s.pin = r);
    save();
    if (mounted) toast(context, r.isEmpty ? 'लॉक बंद' : '🔒 लॉक चालू');
  }

  Future<void> test() async {
    s.aiKey = key.text.trim();
    s.aiModel = model.text.trim().isEmpty ? 'gemini-flash-latest' : model.text.trim();
    save();
    setState(() => testing = true);
    try {
      final r = await AI.ask('फक्त "AI चालू आहे ✅" एवढंच उत्तर दे.');
      if (mounted) toast(context, r.isEmpty ? '✅ AI चालू आहे' : r);
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
    if (mounted) setState(() => testing = false);
  }

  Future<void> editMsgs() async {
    final c = TextEditingController(text: s.customMsgs.join('\n'));
    final r = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('💬 तुमचे मेसेज'),
        content: TextField(controller: c, maxLines: 8, decoration: const InputDecoration(hintText: 'प्रत्येक ओळीत एक मेसेज. हे 20 मेसेजेसच्या यादीत जोडले जातील.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('सेव्ह')),
        ],
      ),
    );
    if (r == null) return;
    s.customMsgs = r.split('\n').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
    save();
  }

  Widget head(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 6),
        child: Text(t, style: TextStyle(fontWeight: FontWeight.w700, color: headColor(context))),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr('Settings'))),
        body: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 40), children: [
          Center(
            child: CircleAvatar(
              radius: 34,
              backgroundColor: C.gold,
              child: Text(s.name.isEmpty ? '?' : s.name.characters.first, style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          head('👤 Profile'),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'नाव'), onChanged: (v) {
            if (v.trim().isEmpty) return;
            s.name = v.trim();
            save();
          }),
          const SizedBox(height: 10),
          TextField(controller: company, decoration: const InputDecoration(labelText: 'कंपनी / व्यवसाय'), onChanged: (v) {
            s.company = v.trim();
            save();
          }),
          head('🌐 भाषा / Language'),
          SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'mr', label: Text('मराठी')), ButtonSegment(value: 'en', label: Text('English'))],
            selected: {s.lang},
            onSelectionChanged: (v) {
              setState(() => s.lang = v.first);
              save();
            },
          ),
          head('🎨 दिसणं'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', label: Text('फोननुसार')),
              ButtonSegment(value: 'light', label: Text('Light')),
              ButtonSegment(value: 'dark', label: Text('Dark')),
            ],
            selected: {s.theme},
            onSelectionChanged: (v) {
              setState(() => s.theme = v.first);
              save();
            },
          ),
          head('🔔 Notifications'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('रिमाइंडर किती आधी'),
            trailing: DropdownButton<int>(
              value: s.remindBefore,
              items: const [
                DropdownMenuItem(value: 0, child: Text('फक्त वेळेवर')),
                DropdownMenuItem(value: 5, child: Text('5 मिनिटं')),
                DropdownMenuItem(value: 15, child: Text('15 मिनिटं')),
                DropdownMenuItem(value: 30, child: Text('30 मिनिटं')),
                DropdownMenuItem(value: 60, child: Text('1 तास')),
              ],
              onChanged: (v) {
                setState(() => s.remindBefore = v ?? 15);
                save(reschedule: true);
              },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('🌅 सकाळचा आढावा'),
            subtitle: Text('रोज ${two(s.morningHour)}:00 — वेळ बदलायला टॅप करा'),
            value: s.morningOn,
            onChanged: (v) {
              setState(() => s.morningOn = v);
              save(reschedule: true);
            },
            secondary: IconButton(icon: const Icon(Icons.schedule), onPressed: () => hourPick(s.morningHour, (h) => s.morningHour = h)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('🌙 दिवसाचा शेवट'),
            subtitle: Text('रोज ${two(s.eodHour)}:00'),
            value: s.eodOn,
            onChanged: (v) {
              setState(() => s.eodOn = v);
              save(reschedule: true);
            },
            secondary: IconButton(icon: const Icon(Icons.schedule), onPressed: () => hourPick(s.eodHour, (h) => s.eodHour = h)),
          ),
          head('💬 सुरुवात'),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('🎬 पोटली ॲनिमेशन'),
              value: s.splashOn,
              onChanged: (v) {
                setState(() => s.splashOn = v);
                save();
              }),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('रोजचा मोटिवेशनल मेसेज'),
              subtitle: Text('आजचा: ${todaysMessage(s.name, s.customMsgs)}'),
              value: s.motivationOn,
              onChanged: (v) {
                setState(() => s.motivationOn = v);
                save();
              }),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('✏️ स्वतःचे मेसेज जोडा'), subtitle: Text('${s.customMsgs.length} जोडलेले'), onTap: editMsgs),
          head('✨ AI (मोफत Gemini)'),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('AI चालू'),
              value: s.aiOn,
              onChanged: (v) {
                setState(() => s.aiOn = v);
                save();
              }),
          TextField(
            controller: key,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Gemini API key', helperText: 'aistudio.google.com वरून मोफत मिळते. ही key फक्त या फोनमध्ये राहते.'),
            onChanged: (v) {
              s.aiKey = v.trim();
              save();
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: model,
            decoration: const InputDecoration(labelText: 'मॉडेल नाव', helperText: 'Default: gemini-flash-latest (फक्त error आला तर बदला)'),
            onChanged: (v) {
              s.aiModel = v.trim().isEmpty ? 'gemini-flash-latest' : v.trim();
              save();
            },
          ),
          const SizedBox(height: 10),
          AiButton('AI तपासा', busy: testing, onTap: test),
          const SizedBox(height: 10),
          const Text('Summary ची default भाषा'),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'मराठी', label: Text('मराठी')), ButtonSegment(value: 'English', label: Text('English')), ButtonSegment(value: 'दोन्ही', label: Text('दोन्ही'))],
            selected: {s.aiLang},
            onSelectionChanged: (v) {
              setState(() => s.aiLang = v.first);
              save();
            },
          ),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('🔒 PAN / खाते नंबर AI ला पाठवण्याआधी लपवा'),
              value: s.maskOn,
              onChanged: (v) {
                setState(() => s.maskOn = v);
                save();
              }),
          const Text('⚠️ मोफत प्लॅनमध्ये पाठवलेला मजकूर Google वापरू शकतं. पासवर्ड, OTP, खाजगी तपशील AI ला पाठवू नका.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          head('🔒 सुरक्षा'),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('App lock (PIN)'), subtitle: Text(s.pin.isEmpty ? 'बंद' : 'चालू'), onTap: setPin, trailing: const Icon(Icons.chevron_right)),
          head('💾 डेटा'),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Backup घ्या'), leading: const Icon(Icons.upload_file), onTap: () => backup(context)),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Backup परत आणा'), leading: const Icon(Icons.restore), onTap: () => restore(context)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_forever, color: C.red),
            title: const Text('सगळा डेटा डिलीट करा', style: TextStyle(color: C.red)),
            onTap: () async {
              if (await confirm(context, 'सगळ्या नोंदी कायमच्या डिलीट होतील. आधी Backup घेतला का?')) {
                await Store.I.wipe();
                if (context.mounted) toast(context, 'डेटा डिलीट झाला');
              }
            },
          ),
          head('ℹ️ अॅपबद्दल'),
          const Text('Smart Diary v1.0 · by Smart Potli\nतुमचा सगळा डेटा फक्त या फोनमध्ये राहतो. इंटरनेट फक्त AI साठी वापरलं जातं.', style: TextStyle(color: Colors.grey)),
        ]),
      );
}
