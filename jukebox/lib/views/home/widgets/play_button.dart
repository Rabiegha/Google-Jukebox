import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlayerButton extends StatelessWidget {
  const PlayerButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.size,
    this.iconSize,
  });

  final IconData icon;
  final void Function() onPressed;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: size,
        width: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xffE59E42),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 4,
            )
          ],
        ),
        child: Icon(
          icon,
          color: Colors.black,
          size: iconSize,
        ),
      ),
    );
  }
}
