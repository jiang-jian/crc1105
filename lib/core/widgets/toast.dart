import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/app_theme.dart';

class _ToastItem {
  final ValueNotifier<double> topOffset;
  final String message;
  final bool isError;

  _ToastItem({
    required this.topOffset,
    required this.message,
    required this.isError,
  });
}

/// 全局 Toast 管理器
class Toast {
  static double _toastTopOffset = 20;
  static const double _toastHeight = 48;
  static const double _toastSpacing = 12;
  static final List<_ToastItem> _toastItems = [];

  /// 显示 Toast
  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    final currentTopOffset = _toastTopOffset;

    late OverlayEntry overlayEntry;
    final toastItem = _ToastItem(
      topOffset: ValueNotifier(currentTopOffset),
      message: message,
      isError: isError,
    );

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: Overlay.of(context),
    );

    final opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );

    overlayEntry = OverlayEntry(
      builder: (context) => ValueListenableBuilder<double>(
        valueListenable: toastItem.topOffset,
        builder: (context, topOffset, _) {
          return Positioned(
            top: topOffset.h,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: AnimatedBuilder(
                  animation: opacityAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: opacityAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isError ? AppTheme.warningColor : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(6.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // 记录当前 Toast
    _toastItems.add(toastItem);

    // 更新下一个 Toast 的位置
    _toastTopOffset += _toastHeight + _toastSpacing;

    overlay.insert(overlayEntry);

    // 播放淡入动画
    animationController.forward();

    // 指定时间后播放淡出动画
    Future.delayed(duration, () {
      animationController.reverse().then((_) {
        overlayEntry.remove();
        animationController.dispose();

        // 移除当前 Toast
        _toastItems.remove(toastItem);

        // 重新计算所有 Toast 的位置
        _recalculateToastPositions();
      });
    });
  }

  /// 显示成功提示
  static void success({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context: context,
      message: message,
      isError: false,
      duration: duration,
    );
  }

  /// 显示错误提示
  static void error({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context: context,
      message: message,
      isError: true,
      duration: duration,
    );
  }

  /// 重新计算所有 Toast 的位置
  static void _recalculateToastPositions() {
    double newTopOffset = 20;
    for (var item in _toastItems) {
      item.topOffset.value = newTopOffset;
      newTopOffset += _toastHeight + _toastSpacing;
    }
    _toastTopOffset = newTopOffset;
  }
}
