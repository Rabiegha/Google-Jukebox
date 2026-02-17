import 'package:flutter/material.dart';

class SizeConfig {
  late MediaQueryData? _mediaQueryData;

  static double? screenWidth;
  static double? screenHeight;
  static double? blockSizeH;
  static double? blockSizeV;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenHeight = _mediaQueryData!.size.height;
    screenWidth = _mediaQueryData!.size.width;

    blockSizeV = screenHeight! / 100;
    blockSizeH = screenWidth! / 100;
  }
}
