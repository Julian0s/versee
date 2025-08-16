import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VerseeLogo extends StatelessWidget {
  final double? height;
  final double? width;

  const VerseeLogo({
    super.key,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/versee_logo_header.svg',
      height: height ?? 40,
      width: width ?? 120,
      fit: BoxFit.contain,
    );
  }
}