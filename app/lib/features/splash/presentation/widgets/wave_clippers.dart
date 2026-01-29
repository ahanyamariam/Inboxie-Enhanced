import 'package:flutter/material.dart';


class BottomYellowWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    path.moveTo(0, size.height * 0.35);

   
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.20,
      size.width * 0.5,
      size.height * 0.30,
    );

   
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.42,
      size.width,
      size.height * 0.25,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class BottomBlueWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    path.moveTo(0, size.height * 0.50);

    
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.35,
      size.width * 0.5,
      size.height * 0.45,
    );

  
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.58,
      size.width,
      size.height * 0.42,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}