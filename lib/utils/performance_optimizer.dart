import 'package:flutter/material.dart';
import 'dart:async';

// Debounced search implementation
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class PerformanceOptimizer {
  // Lazy loading implementation
  static Widget lazyBuilder({
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    ScrollController? controller,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // Performance optimizations
      cacheExtent: 200.0, // Cache items for smooth scrolling
      addAutomaticKeepAlives: false, // Don't keep items alive unnecessarily
      addRepaintBoundaries: false, // Reduce unnecessary repaints
    );
  }

  // Optimized image loading
  static Widget optimizedImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      // Use memory efficient loading
      filterQuality: FilterQuality.medium,
    );
  }

  // Debounced search implementation - use the top-level Debouncer class

  // Optimized form validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Use a more efficient regex for email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Memory management helpers
  static void disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  // Efficient state updates
  static void batchStateUpdates(List<VoidCallback> updates) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final update in updates) {
        update();
      }
    });
  }
}

// Mixin for automatic disposal of resources
mixin DisposableMixin<T extends StatefulWidget> on State<T> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  void addController(TextEditingController controller) {
    _controllers.add(controller);
  }

  void addFocusNode(FocusNode focusNode) {
    _focusNodes.add(focusNode);
  }

  void addSubscription(StreamSubscription<dynamic> subscription) {
    _subscriptions.add(subscription);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}