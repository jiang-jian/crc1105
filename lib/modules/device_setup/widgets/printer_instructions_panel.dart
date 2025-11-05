import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 打印机配置操作提示面板组件（优化版 - 更紧凑）
class PrinterInstructionsPanel extends StatelessWidget {
  const PrinterInstructionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFF1890FF).withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16.sp,
                color: const Color(0xFF1890FF),
              ),
              SizedBox(width: 6.w),
              Text(
                '操作提示',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1890FF),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _buildInstructionItem('1', '自动检测打印机状态'),
          SizedBox(height: 8.h),
          _buildInstructionItem('2', '状态正常后点击测试打印'),
          SizedBox(height: 8.h),
          _buildInstructionItem('3', '右侧日志显示SDK调用详情'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.w,
          height: 20.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1890FF),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF333333),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
