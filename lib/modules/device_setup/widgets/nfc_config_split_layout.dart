import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// NFC配置左右分栏布局组件
class NfcConfigSplitLayout extends StatelessWidget {
  final Widget leftSection;  // 左侧配置区域
  final Widget rightSection; // 右侧数据显示区域

  const NfcConfigSplitLayout({
    super.key,
    required this.leftSection,
    required this.rightSection,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧配置区域 (50%)
        Expanded(
          flex: 1,
          child: Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              border: Border(
                right: BorderSide(
                  color: const Color(0xFFE0E0E0),
                  width: 1.w,
                ),
              ),
            ),
            child: leftSection,
          ),
        ),
        
        // 右侧数据显示区域 (50%)
        Expanded(
          flex: 1,
          child: Container(
            padding: EdgeInsets.all(32.w),
            color: Colors.white,
            child: rightSection,
          ),
        ),
      ],
    );
  }
}

