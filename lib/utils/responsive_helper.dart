import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
      
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 1200;
      
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
      
  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isMobile(context)) {
      return baseFontSize * 0.9;
    } else if (isTablet(context)) {
      return baseFontSize;
    } else {
      return baseFontSize * 1.1;
    }
  }

  static int getResponsiveGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  static double getResponsiveCardWidth(BuildContext context) {
    if (isMobile(context)) {
      return getScreenWidth(context) - 32;
    } else if (isTablet(context)) {
      return (getScreenWidth(context) - 72) / 2;
    } else {
      return (getScreenWidth(context) - 128) / 3;
    }
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (ResponsiveHelper.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 
            (ResponsiveHelper.isMobile(context) ? double.infinity : 600),
        ),
        child: child,
      ),
    );
  }
}