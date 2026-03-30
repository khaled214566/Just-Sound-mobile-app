import 'package:flutter/material.dart';

class BasicAppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final double? height;
  final Color? textColor;
  final double? textSize;
  final Color? buttonColor;
  const BasicAppButton({
    required this.onPressed,
    required this.title,
    this.buttonColor,
    this.height,
    this.textColor,
    this.textSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(height ?? 80),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white, // text color
          fontSize: textSize ?? 35,
          fontFamily: 'Sora',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
