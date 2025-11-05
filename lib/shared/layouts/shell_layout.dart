import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/app_header.dart';

/// Shell Layout - 包含 Header 的布局容器
/// 使用 GoRouter 的 ShellRoute，Header 固定显示，子页面内容会根据路由变化
class ShellLayout extends StatefulWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            // 动态变化的内容区域（灰色背景 + padding）
            Expanded(
              child: Container(
                color: const Color(0xFFF4F5FA),
                padding: EdgeInsets.all(20.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
