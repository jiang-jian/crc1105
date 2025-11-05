import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/theme/app_theme.dart';

/// NFC 设备状态显示组件
class NfcDeviceStatus extends StatelessWidget {
  final String status;
  final String? errorMessage;
  final VoidCallback? onEnableNfc;

  const NfcDeviceStatus({
    super.key,
    required this.status,
    this.errorMessage,
    this.onEnableNfc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _buildStatusIcon(),
          SizedBox(height: 16.h),
          _buildStatusText(),
          if (status == 'disabled' && onEnableNfc != null) ...[
            SizedBox(height: 16.h),
            _buildEnableButton(),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case 'checking':
        return const Color(0xFFF0F7FF);
      case 'available':
        return const Color(0xFFF0F9FF);
      case 'unsupported':
      case 'unavailable':
        return const Color(0xFFFFF1F0);
      case 'disabled':
        return const Color(0xFFFFFBE6);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getBorderColor() {
    switch (status) {
      case 'checking':
        return const Color(0xFF1890FF);
      case 'available':
        return const Color(0xFF52C41A);
      case 'unsupported':
      case 'unavailable':
        return const Color(0xFFE74C3C);
      case 'disabled':
        return const Color(0xFFF39C12);
      default:
        return const Color(0xFFD9D9D9);
    }
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (status) {
      case 'checking':
        icon = Icons.sync;
        color = const Color(0xFF1890FF);
        break;
      case 'available':
        icon = Icons.check_circle;
        color = const Color(0xFF52C41A);
        break;
      case 'unsupported':
        icon = Icons.block;
        color = const Color(0xFFE74C3C);
        break;
      case 'unavailable':
        icon = Icons.error;
        color = const Color(0xFFE74C3C);
        break;
      case 'disabled':
        icon = Icons.settings;
        color = const Color(0xFFF39C12);
        break;
      default:
        icon = Icons.help_outline;
        color = const Color(0xFF999999);
    }

    return Container(
      width: 64.w,
      height: 64.h,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 32.sp,
        color: color,
      ),
    );
  }

  Widget _buildStatusText() {
    String text;
    Color color;

    switch (status) {
      case 'checking':
        text = '正在检测设备...';
        color = const Color(0xFF1890FF);
        break;
      case 'available':
        text = '检测到可用设备';
        color = const Color(0xFF52C41A);
        break;
      case 'unsupported':
        text = '当前设备不支持 NFC 功能';
        color = const Color(0xFFE74C3C);
        break;
      case 'disabled':
        text = 'NFC 功能未启用';
        color = const Color(0xFFF39C12);
        break;
      case 'unavailable':
        text = errorMessage ?? '未检测到可用设备';
        color = const Color(0xFFE74C3C);
        break;
      default:
        text = '准备检测...';
        color = const Color(0xFF999999);
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEnableButton() {
    return SizedBox(
      height: 52.h, // 增加高度
      child: ElevatedButton.icon(
        onPressed: onEnableNfc,
        icon: Icon(Icons.settings, size: 18.sp),
        label: Text(
          '打开 NFC 设置',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            height: 1.2, // 设置行高
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h), // 增加内边距
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

