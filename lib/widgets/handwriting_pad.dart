import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// V3.34 手写画布（Step 1）：捕捉触控笔/手指笔迹，导出 PNG 供视觉模型识别。
/// 用法：HandwritingPad(controller: ctrl, key: padKey)；padKey.currentState!.exportPng()。
class HandwritingController extends ChangeNotifier {
  final List<List<Offset>> strokes = [];
  List<Offset>? _current;

  bool get isEmpty => strokes.isEmpty;

  void start(Offset p) {
    _current = [p];
    strokes.add(_current!);
    notifyListeners();
  }

  void extend(Offset p) {
    _current?.add(p);
    notifyListeners();
  }

  void end() {
    _current = null;
  }

  void undo() {
    if (strokes.isNotEmpty) {
      strokes.removeLast();
      _current = null;
      notifyListeners();
    }
  }

  void clear() {
    strokes.clear();
    _current = null;
    notifyListeners();
  }
}

class HandwritingPad extends StatefulWidget {
  final HandwritingController controller;
  final double height;
  const HandwritingPad({super.key, required this.controller, this.height = 220});

  @override
  State<HandwritingPad> createState() => HandwritingPadState();
}

class HandwritingPadState extends State<HandwritingPad> {
  final _boundaryKey = GlobalKey();

  /// 导出白底 PNG（pixelRatio 2 提升手写清晰度，利于 OCR）。
  Future<Uint8List?> exportPng() async {
    final ctx = _boundaryKey.currentContext;
    if (ctx == null) return null;
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 2.0);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onPanStart: (d) => widget.controller.start(d.localPosition),
          onPanUpdate: (d) => widget.controller.extend(d.localPosition),
          onPanEnd: (_) => widget.controller.end(),
          child: CustomPaint(
            painter: _PadPainter(widget.controller),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _PadPainter extends CustomPainter {
  final HandwritingController c;
  _PadPainter(this.c) : super(repaint: c);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in c.strokes) {
      if (s.length == 1) {
        canvas.drawPoints(ui.PointMode.points, [s.first], paint);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (int i = 1; i < s.length; i++) {
        path.lineTo(s[i].dx, s[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PadPainter oldDelegate) => true;
}
