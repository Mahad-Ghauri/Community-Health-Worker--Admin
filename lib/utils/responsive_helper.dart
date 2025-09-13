import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Enhanced breakpoints for ultra-adaptive design
  static bool isExtraSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < 480;
      
  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width >= 480 && 
      MediaQuery.of(context).size.width < 600;
      
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
      
  static bool isTabletSmall(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 900;
      
  static bool isTabletLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900 && 
      MediaQuery.of(context).size.width < 1200;
      
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 1200;
      
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200 &&
      MediaQuery.of(context).size.width < 1600;
      
  static bool isDesktopLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1600;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
      
  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Ultra-adaptive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 480) {
      return const EdgeInsets.all(12.0);
    } else if (width < 600) {
      return const EdgeInsets.all(16.0);
    } else if (width < 900) {
      return const EdgeInsets.all(20.0);
    } else if (width < 1200) {
      return const EdgeInsets.all(24.0);
    } else if (width < 1600) {
      return const EdgeInsets.all(32.0);
    } else {
      return const EdgeInsets.all(40.0);
    }
  }

  // Adaptive font sizing with smooth scaling
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final width = getScreenWidth(context);
    if (width < 480) {
      return baseFontSize * 0.85;
    } else if (width < 600) {
      return baseFontSize * 0.9;
    } else if (width < 900) {
      return baseFontSize * 0.95;
    } else if (width < 1200) {
      return baseFontSize;
    } else if (width < 1600) {
      return baseFontSize * 1.05;
    } else {
      return baseFontSize * 1.1;
    }
  }

  // Dynamic grid columns based on screen width
  static int getResponsiveGridColumns(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 480) {
      return 1;
    } else if (width < 600) {
      return 1;
    } else if (width < 900) {
      return 2;
    } else if (width < 1200) {
      return 3;
    } else if (width < 1600) {
      return 4;
    } else {
      return 5;
    }
  }

  // Adaptive card width calculation
  static double getResponsiveCardWidth(BuildContext context) {
    final width = getScreenWidth(context);
    final padding = getResponsivePadding(context).horizontal;
    final columns = getResponsiveGridColumns(context);
    final spacing = (columns - 1) * 16.0; // 16px spacing between cards
    
    return (width - padding - spacing) / columns;
  }

  // Get appropriate spacing based on screen size
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final width = getScreenWidth(context);
    if (width < 480) {
      return baseSpacing * 0.75;
    } else if (width < 600) {
      return baseSpacing * 0.9;
    } else if (width < 1200) {
      return baseSpacing;
    } else {
      return baseSpacing * 1.2;
    }
  }

  // Get adaptive border radius
  static double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    final width = getScreenWidth(context);
    if (width < 600) {
      return baseRadius;
    } else if (width < 1200) {
      return baseRadius * 1.2;
    } else {
      return baseRadius * 1.5;
    }
  }

  // Get screen size category as string for debugging
  static String getScreenSizeCategory(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 480) return 'Extra Small Mobile';
    if (width < 600) return 'Small Mobile';
    if (width < 900) return 'Small Tablet';
    if (width < 1200) return 'Large Tablet';
    if (width < 1600) return 'Desktop';
    return 'Large Desktop';
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tabletSmall;
  final Widget? tabletLarge;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? desktopLarge;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tabletSmall,
    this.tabletLarge,
    this.tablet,
    this.desktop,
    this.desktopLarge,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktopLarge(context)) {
      return desktopLarge ?? desktop ?? tablet ?? tabletLarge ?? tabletSmall ?? mobile;
    } else if (ResponsiveHelper.isDesktop(context)) {
      return desktop ?? tablet ?? tabletLarge ?? tabletSmall ?? mobile;
    } else if (ResponsiveHelper.isTabletLarge(context)) {
      return tabletLarge ?? tablet ?? tabletSmall ?? mobile;
    } else if (ResponsiveHelper.isTabletSmall(context)) {
      return tabletSmall ?? tablet ?? mobile;
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
    double containerMaxWidth;
    
    if (maxWidth != null) {
      containerMaxWidth = maxWidth!;
    } else if (ResponsiveHelper.isMobile(context)) {
      containerMaxWidth = double.infinity;
    } else if (ResponsiveHelper.isTabletSmall(context)) {
      containerMaxWidth = 700;
    } else if (ResponsiveHelper.isTabletLarge(context)) {
      containerMaxWidth = 900;
    } else if (ResponsiveHelper.isDesktop(context)) {
      containerMaxWidth = 1200;
    } else {
      containerMaxWidth = 1400;
    }

    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: containerMaxWidth),
        child: child,
      ),
    );
  }
}