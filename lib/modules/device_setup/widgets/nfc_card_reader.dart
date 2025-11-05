import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/theme/app_theme.dart';
import 'card_data_display.dart';

/// NFC 读卡区域组件
class NfcCardReader extends StatelessWidget {
  final String cardReadStatus;
  final String? errorMessage;
  final VoidCallback onStartRead;
  final VoidCallback? onRetry;
  final Map<String, dynamic>? cardData;

  const NfcCardReader({
    super.key,
    required this.cardReadStatus,
    this.errorMessage,
    required this.onStartRead,
    this.onRetry,
    this.cardData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 提示文本
          Text(
            '请将 M1 卡片靠近读卡器',
            style: TextStyle(
              fontSize: 18.sp,
              color: const Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          SizedBox(height: 40.h),
          
          // 卡片图标动画
          _buildCardIcon(),
          
          SizedBox(height: 40.h),
          
          // 读卡状态
          _buildCardStatus(),
          
          SizedBox(height: 32.h),
          
          // 操作按钮
          _buildActionButton(),
          
          // 卡片数据显示（成功读卡后显示）
          if (cardReadStatus == 'success' && cardData != null)
            CardDataDisplay(cardData: cardData!),
        ],
      ),
    );
  }

  Widget _buildCardIcon() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Container(
            width: 160.w,
            height: 160.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: _getGradientColors()[0].withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.credit_card,
                  size: 80.sp,
                  color: Colors.white,
                ),
                if (cardReadStatus == 'reading')
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _getGradientColors() {
    switch (cardReadStatus) {
      case 'success':
        return [const Color(0xFF52C41A), const Color(0xFF389E0D)];
      case 'failed':
        return [const Color(0xFFE74C3C), const Color(0xFFC0392B)];
      case 'reading':
        return [const Color(0xFF1890FF), const Color(0xFF096DD9)];
      default:
        return [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)];
    }
  }

  Widget _buildCardStatus() {
    String text;
    Color color;
    IconData? icon;

    switch (cardReadStatus) {
      case 'waiting':
        text = '等待读卡...';
        color = const Color(0xFF666666);
        icon = null;
        break;
      case 'reading':
        text = '正在读取卡片，请保持卡片稳定...';
        color = const Color(0xFF1890FF);
        icon = Icons.sync;
        break;
      case 'success':
        text = '✓ 识别通过';
        color = const Color(0xFF52C41A);
        icon = Icons.check_circle;
        break;
      case 'failed':
        text = errorMessage ?? '识别失败，请重试';
        color = const Color(0xFFE74C3C);
        icon = Icons.error;
        break;
      default:
        text = '准备读卡';
        color = const Color(0xFF999999);
        icon = null;
    }

    return Column(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 32.sp, color: color),
          SizedBox(height: 12.h),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (cardReadStatus == 'success') {
      return const SizedBox.shrink();
    }

    final isReading = cardReadStatus == 'reading';
    final isFailed = cardReadStatus == 'failed';

    return SizedBox(
      width: 200.w,
      height: 48.h,
      child: ElevatedButton(
        onPressed: isReading ? null : (isFailed && onRetry != null ? onRetry : onStartRead),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD9D9D9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          elevation: 0,
        ),
        child: Text(
          isFailed ? '重新读卡' : isReading ? '读取中...' : '开始读卡',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

