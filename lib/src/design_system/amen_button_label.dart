import 'package:flutter/material.dart';

class AmenButtonLabel extends StatelessWidget {
  const AmenButtonLabel(
    this.label, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
  });

  final String label;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}
