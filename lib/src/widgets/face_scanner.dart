import 'dart:math';

import 'package:flutter/material.dart';

// クレカ標準の比
const _CARD_ASPECT_RATIO = 1.25 / 1;
// 横の枠線marginを決める時用のfactor
// 横幅の5%のサイズのmarginをとる
const _OFFSET_X_FACTOR = 0.08;

class FaceScannerOverlayShape extends ShapeBorder {
  const FaceScannerOverlayShape({
    this.borderColor = const Color(0xffa8b1bd),
    this.borderWidth = 2.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 100),
    // this.overlayColor = const Color.fromARGB(255, 255, 255, 255),
    this.borderRadius = 12,
    this.borderLength = 32,
    this.cutOutBottomOffset = 0,
    this.offsetYInput = 0});

  final offsetYInput;
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutBottomOffset;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )..lineTo(
        rect.left,
        rect.bottom,
      )..lineTo(
        rect.left,
        rect.top,
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // print("size overlay ${rect.width}");
    // print("size overlay ${rect.height}");
    final offsetX = rect.width * _OFFSET_X_FACTOR;
    final cardWidth = rect.width - offsetX * 2;
    // final cardHeight = cardWidth * _CARD_ASPECT_RATIO;
    final cardHeight = cardWidth;
    final offsetY = (offsetYInput>0)? offsetYInput : ((rect.height - rect.height * 0.15 - cardHeight) / 2);

    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + offsetX,
      rect.top + offsetY,
      cardWidth,
      cardHeight,
    );

    final radius = cutOutRect.width / 2;
    final midOffset = Offset((cutOutRect.right + cutOutRect.left) / 2,
        (cutOutRect.top + cutOutRect.bottom) / 2);

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.saveLayer(
      rect,
      backgroundPaint,
    );
    canvas.drawRect(
      rect,
      backgroundPaint,
    );
    canvas.drawOval(cutOutRect, boxPaint);
    canvas.restore();
    var j = 0.0;
    paint.color = borderColor;
    while (j <= 360) {
      final sweepAngle = 360 - j - 180.0;
      var a = cutOutRect.height / 2;
      var b = cutOutRect.width / 2;
      var aS = sin(deg2Rand(sweepAngle)) * sin(deg2Rand(sweepAngle));
      var bC = cos(deg2Rand(sweepAngle)) * cos(deg2Rand(sweepAngle));
      var radiusOval = (a * b) / sqrt(a * a * aS + b * b * bC);
      canvas.drawLine(
        Offset(midOffset.dx + sin(deg2Rand(sweepAngle)) * (radiusOval + 15),
            midOffset.dy + cos(deg2Rand(sweepAngle)) * (radiusOval + 15)),
        Offset(midOffset.dx + sin(deg2Rand(sweepAngle)) * (radiusOval + 5),
            midOffset.dy + cos(deg2Rand(sweepAngle)) * (radiusOval + 5)),
        paint,
      );
      j = j + 3.0;
    }
  }

  deg2Rand(double deg) => deg * pi / 180;

  @override
  ShapeBorder scale(double t) {
    return FaceScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
