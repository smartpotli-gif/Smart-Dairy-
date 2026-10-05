import 'dart:math';
import 'package:flutter/material.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import 'home.dart';

/// Decides: name setup -> splash -> PIN lock -> home.
class StartGate extends StatefulWidget {
  const StartGate({super.key});
  @override
  State<StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<StartGate> {
  bool splashDone = false, unlocked = false;
  @override
  Widget build(BuildContext context) {
    final s = Store.I.s;
    if (s.name.isEmpty) return Onboarding(onDone: () => setState(() {}));
    if (s.splashOn && !splashDone) return Splash(onDone: () => setState(() => splashDone = true));
    if (s.pin.isNotEmpty && !unlocked) return LockScreen(onOk: () => setState(() => unlocked = true));
    return const HomeShell();
  }
}

class Onboarding extends StatefulWidget {
  final VoidCallback onDone;
  const Onboarding({super.key, required this.onDone});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final name = TextEditingController(), company = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(28), children: [
            const SizedBox(height: 40),
            const Center(child: Text('👝', style: TextStyle(fontSize: 64))),
            const SizedBox(height: 12),
            Center(child: Text('Smart Diary', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: headColor(context)))),
            const Center(child: Text('by Smart Potli', style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 36),
            const Text('तुमचं नाव काय?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: name, autofocus: true, decoration: const InputDecoration(hintText: 'उदा. सूरज')),
            const SizedBox(height: 14),
            TextField(controller: company, decoration: const InputDecoration(hintText: 'कंपनी / व्यवसाय (optional)')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                Store.I.s.name = name.text.trim();
                Store.I.s.company = company.text.trim();
                Store.I.save();
                widget.onDone();
              },
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: C.green),
              child: const Text('सुरू करा 🚀'),
            ),
            const SizedBox(height: 12),
            const Text('नाव नंतर Settings मध्ये बदलता येईल. तुमचा सगळा डेटा फक्त या फोनमध्ये राहतो.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      );
}

/// Potli fills with gold, knot opens, sparkle, then welcome + daily message.
class Splash extends StatefulWidget {
  final VoidCallback onDone;
  const Splash({super.key, required this.onDone});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
  bool left = false;
  void finish() {
    if (left) return;
    left = true;
    widget.onDone();
  }

  @override
  void initState() {
    super.initState();
    a.forward().whenComplete(finish);
  }

  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  double seg(double v, double from, double to) => ((v - from) / (to - from)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final s = Store.I.s;
    final msg = s.motivationOn ? todaysMessage(s.name, s.customMsgs) : '';
    return GestureDetector(
      onTap: finish,
      child: Scaffold(
        backgroundColor: C.green,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: a,
            builder: (_, __) {
              final v = a.value;
              final logo = Curves.easeOut.transform(seg(v, 0, .12));
              final fill = Curves.easeInOut.transform(seg(v, .12, .48));
              final open = Curves.easeOut.transform(seg(v, .48, .6));
              final text = seg(v, .6, .72);
              final m = seg(v, .7, .82);
              return Column(children: [
                const Spacer(flex: 2),
                Opacity(
                  opacity: logo,
                  child: Transform.scale(
                    scale: .8 + .2 * logo,
                    child: SizedBox(width: 190, height: 210, child: CustomPaint(painter: PotliPainter(fill, open))),
                  ),
                ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: text,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - text)),
                    child: Column(children: [
                      const Text('Smart Diary', style: TextStyle(color: C.gold, fontSize: 34, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('Welcome, ${s.name}', style: const TextStyle(color: Colors.white, fontSize: 20)),
                    ]),
                  ),
                ),
                const SizedBox(height: 26),
                if (msg.isNotEmpty)
                  Opacity(
                    opacity: m,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Text('“$msg”',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFE4D39A), fontSize: 16, height: 1.4, fontStyle: FontStyle.italic)),
                    ),
                  ),
                const Spacer(flex: 3),
                const Text('by Smart Potli', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                const Text('टॅप करून पुढे जा', style: TextStyle(color: Colors.white30, fontSize: 11)),
                const SizedBox(height: 18),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class PotliPainter extends CustomPainter {
  final double fill, open;
  PotliPainter(this.fill, this.open);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final body = Path()
      ..moveTo(w * .36, h * .34)
      ..cubicTo(w * .02, h * .46, w * .0, h * .94, w * .5, h * .95)
      ..cubicTo(w * 1.0, h * .94, w * .98, h * .46, w * .64, h * .34)
      ..close();
    // bag base
    c.drawPath(body, Paint()..color = const Color(0xFF8B5E34));
    // gold fill rising from bottom
    c.save();
    c.clipPath(body);
    final top = h * .95 - (h * .62) * fill;
    final wave = Path()..moveTo(0, top);
    for (double x = 0; x <= w; x += 6) {
      wave.lineTo(x, top + sin((x / w) * pi * 4 + fill * 8) * 4);
    }
    wave
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(wave, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2D06B), C.gold]).createShader(Rect.fromLTWH(0, 0, w, h)));
    c.restore();
    c.drawPath(body, Paint()
      ..color = const Color(0xFF5E3B1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    // neck flaps open outward
    final flap = Paint()..color = const Color(0xFF8B5E34);
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.translate(w * .5 + side * w * .1, h * .34);
      c.rotate(side * open * .7);
      final f = Path()
        ..moveTo(-w * .1, 0)
        ..lineTo(side * w * .02 - w * .06, -h * .16)
        ..lineTo(side * w * .02 + w * .06, -h * .16)
        ..lineTo(w * .1, 0)
        ..close();
      c.drawPath(f, flap);
      c.restore();
    }
    // knot (fades as it opens)
    final knot = Paint()..color = Color.lerp(const Color(0xFFC0392B), Colors.transparent, open)!;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * .5, h * .34), width: w * .34, height: h * .05), const Radius.circular(6)), knot);
    // sparkle burst
    if (open > 0) {
      final sp = Paint()..color = const Color(0xFFFFE9A6).withOpacity((1 - (open - .6).clamp(0.0, .4) / .4 * .4));
      for (var i = 0; i < 12; i++) {
        final ang = -pi / 2 + (i - 5.5) * .22;
        final r = h * (.1 + .32 * open);
        final p = Offset(w * .5 + cos(ang) * r, h * .3 + sin(ang) * r);
        c.drawCircle(p, 3.5 * (1 - open * .4), sp);
      }
      c.drawCircle(Offset(w * .5, h * .3), 18 * open, Paint()..color = const Color(0x55FFE9A6));
    }
    // coin symbol
    if (fill > .6) {
      final tp = TextPainter(
          text: TextSpan(text: '₹', style: TextStyle(fontSize: 40, color: const Color(0xFF5E3B1C).withOpacity((fill - .6) / .4), fontWeight: FontWeight.w800)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(c, Offset(w * .5 - tp.width / 2, h * .62));
    }
  }

  @override
  bool shouldRepaint(PotliPainter o) => o.fill != fill || o.open != open;
}

class LockScreen extends StatefulWidget {
  final VoidCallback onOk;
  const LockScreen({super.key, required this.onOk});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String entered = '';
  bool wrong = false;
  void tap(String d) {
    if (entered.length >= 4) return;
    setState(() {
      entered += d;
      wrong = false;
    });
    if (entered.length == 4) {
      if (entered == Store.I.s.pin) {
        widget.onOk();
      } else {
        setState(() {
          wrong = true;
          entered = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String d) => Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 72,
            height: 72,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(shape: const CircleBorder()),
              onPressed: d.isEmpty
                  ? null
                  : () {
                      if (d == '⌫') {
                        setState(() => entered = entered.isEmpty ? '' : entered.substring(0, entered.length - 1));
                      } else {
                        tap(d);
                      }
                    },
              child: Text(d, style: const TextStyle(fontSize: 22)),
            ),
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔒', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text('Smart Diary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: headColor(context))),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  4,
                  (i) => Container(
                        margin: const EdgeInsets.all(8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: i < entered.length ? C.green : Colors.grey.withOpacity(.3)),
                      )),
            ),
            SizedBox(height: 24, child: wrong ? const Text('चुकीचा PIN', style: TextStyle(color: C.red)) : null),
            for (final row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '⌫']
            ])
              Row(mainAxisSize: MainAxisSize.min, children: row.map(key).toList()),
          ]),
        ),
      ),
    );
  }
}
