import 'package:flutter/cupertino.dart';

class Utils {
  static int calcMessageHeight(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: 250);

    return textPainter.size.height.toInt() + 10;
  }

  static bool isOverflow(String text, double fontSize, int maxLine) {
    final textStyle = TextStyle(fontSize: fontSize);
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        maxLines: maxLine)
      ..layout(minWidth: 0, maxWidth: 250);

    return textPainter.didExceedMaxLines;
  }
}
