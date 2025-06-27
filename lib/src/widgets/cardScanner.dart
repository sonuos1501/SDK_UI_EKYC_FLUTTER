import 'dart:math';

import 'package:flutter/material.dart';

// クレカ標準の比

// const _CARD_ASPECT_RATIO = 1 / 1.618;
// 横の枠線marginを決める時用のfactor
// 横幅の5%のサイズのmarginをとる


class CardScannerOverlayShape extends ShapeBorder {
  CardScannerOverlayShape({
    this.CARD_ASPECT_RATIO = 1 / 1.5,
    this.OFFSET_X_FACTOR = 0.05,
    this.borderColor = Colors.white,
    this.validColor = Colors.green,
    this.borderWidth = 4.0,
    // this.overlayColor = const Color.fromRGBO(0, 0, 0, 60),
    this.overlayColor = const Color.fromARGB(255, 255, 255, 255),
    this.borderRadius = 6,
    this.borderLength = 32,
    this.cutOutBottomOffset = 0,
  });

  var CARD_ASPECT_RATIO;
  var OFFSET_X_FACTOR;
  final Color borderColor;
  final Color validColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutBottomOffset;
  final double padingValideAndRect = -2;

  // int? _left, _top, _height, _width;
  // bool _isAddMaskShape = false;
  // int get_left() {
  //   return _left!;
  // }

  // int get_top() {
  //   return _top!;
  // }

  // int get_height() {
  //   return _height!;
  // }

  // int get_heidth() {
  //   return _width!;
  // }

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
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.top,
      );
  }

  deg2Rand(double deg) => deg * pi / 180;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // print("size overlay ${rect.width}");
    // print("size overlay ${rect.height}");
    final offsetX = rect.width * OFFSET_X_FACTOR;
    final cardWidth = rect.width - offsetX * 2;
    final cardHeight = cardWidth * CARD_ASPECT_RATIO;
    final offsetY = (rect.height - cardHeight) / 2;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final validatePaint = Paint()
      ..color = validColor
      ..strokeCap= StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + offsetX,
      rect.top + offsetY,
      cardWidth,
      cardHeight,
    );

    // print("hubert RectLeft= " + rect.left.round().toString());
    // print("hubert RectTop= " + rect.top.round().toString());
    // print("hubert RectWidth= " + rect.width.round().toString());
    // print("hubert RectHeight= " + rect.height.round().toString());
    // print("hubert offsetX  = " + offsetX.toString());
    // print("hubert offsetY  = " + offsetY.toString());
    // print("hubert Left = " + (rect.left + offsetX).round().toString());
    // print("hubert Top = " + (rect.top + offsetY).round().toString());
    // print("hubert Height = " + cardHeight.round().toString());
    // print("hubert Width = " + cardWidth.round().toString());

    // if (!_isAddMaskShape) {
    //   print("add mask shape");
    //   this._left = (rect.left + offsetX).round();
    //   this._top = (rect.top + offsetY).round();
    //   this._height = cardHeight.round();
    //   print("add mask shape height = " + this._height.toString());
    //   this._width = cardWidth.round();
    //   _isAddMaskShape = true;
    // }

    // canvas
    //   ..saveLayer(
    //     rect,
    //     backgroundPaint,
    //   )
    //   ..drawRect(
    //     rect,
    //     backgroundPaint,
    //   )
    //   ..drawOval(cutOutRect, boxPaint)
    //   ..drawOval(cutOutRect, borderPaint)
    //   ..restore()
    //   ..restore();
    // top rigth
    double extend = borderRadius + 24.0;
    Size arcSize = Size.square(borderRadius*1.5);
    final pathBottomRight = Path();
    pathBottomRight
      ..moveTo(cutOutRect.right + padingValideAndRect,
          cutOutRect.bottom - borderLength + padingValideAndRect)
      ..arcTo(
          Rect.fromLTRB(
              cutOutRect.right - arcSize.width + padingValideAndRect,
              cutOutRect.bottom - arcSize.width + padingValideAndRect,
              cutOutRect.right + padingValideAndRect,
              cutOutRect.bottom + padingValideAndRect),
          2 * pi,
          pi / 2,
          false)
      ..lineTo(cutOutRect.right - borderLength + padingValideAndRect,
          cutOutRect.bottom + padingValideAndRect);

    final pathTopLeft = Path();
    pathTopLeft
      ..moveTo(cutOutRect.left - padingValideAndRect,
          cutOutRect.top + borderLength - padingValideAndRect)
      ..arcTo(
          Rect.fromLTRB(
              cutOutRect.left - padingValideAndRect,
              cutOutRect.top - padingValideAndRect,
              cutOutRect.left + arcSize.width - padingValideAndRect,
              cutOutRect.top + arcSize.width - padingValideAndRect),
          pi,
          pi / 2,
          false)
      ..lineTo(cutOutRect.left + borderLength - padingValideAndRect,
          cutOutRect.top - padingValideAndRect);

    final pathBottomLeft = Path();
    pathBottomLeft
      ..moveTo(cutOutRect.left - padingValideAndRect,
          cutOutRect.bottom - borderLength + padingValideAndRect)
      ..arcTo(
          Rect.fromLTRB(
              cutOutRect.left - padingValideAndRect,
              cutOutRect.bottom - arcSize.width + padingValideAndRect,
              cutOutRect.left + arcSize.width - padingValideAndRect,
              cutOutRect.bottom + padingValideAndRect),
          pi,
          -pi / 2,
          false)
      ..lineTo(cutOutRect.left + borderLength - padingValideAndRect,
          cutOutRect.bottom + padingValideAndRect);

    final pathTopRight = Path();
    pathBottomLeft
      ..moveTo(cutOutRect.right + padingValideAndRect,
          cutOutRect.top + borderLength - padingValideAndRect)
      ..arcTo(
          Rect.fromLTRB(
              cutOutRect.right - arcSize.width + padingValideAndRect,
              cutOutRect.top - padingValideAndRect,
              cutOutRect.right + padingValideAndRect,
              cutOutRect.top + arcSize.width - padingValideAndRect),
          2 * pi,
          -pi / 2,
          false)
      ..lineTo(cutOutRect.right - borderLength + padingValideAndRect,
          cutOutRect.top - padingValideAndRect);
    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..drawRRect(
          RRect.fromRectXY(cutOutRect, borderRadius, borderRadius), borderPaint)
      ..drawPath(pathTopLeft, validatePaint)
      ..drawPath(pathBottomRight, validatePaint)
      ..drawPath(pathBottomLeft, validatePaint)
      ..drawPath(pathTopRight, validatePaint)
      ..restore();
  }

  @override
  ShapeBorder scale(double t) {
    return CardScannerOverlayShape(
      borderColor: borderColor,
      validColor: validColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
