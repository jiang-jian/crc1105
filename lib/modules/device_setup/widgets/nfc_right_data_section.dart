import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/theme/app_theme.dart';

/// NFC配置右侧数据显示区域组件
class NfcRightDataSection extends StatelessWidget {
  final Map<String, dynamic>? cardData;
  final String cardReadStatus;

  const NfcRightDataSection({
    super.key,
    this.cardData,
    required this.cardReadStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Row(
          children: [
            Container(
              width: 4.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              '卡片数据',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 32.h),
        
        // 数据显示区域
        Expanded(
          child: _buildDataContent(),
        ),
      ],
    );
  }

  Widget _buildDataContent() {
    if (cardData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 80.sp,
              color: const Color(0xFFD9D9D9),
            ),
            SizedBox(height: 24.h),
            Text(
              '暂无数据',
              style: TextStyle(
                fontSize: 18.sp,
                color: const Color(0xFF999999),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '请将卡片靠近读卡器',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFFBFBFBF),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFF52C41A).withValues(alpha: 0.3),
            width: 2.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 成功图标
            if (cardData!['isValid'] == true)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF52C41A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20.sp,
                      color: const Color(0xFF52C41A),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '卡片验证通过',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF52C41A),
                      ),
                    ),
                  ],
                ),
              ),

            // 数据列表
            _buildDataRow('卡片 UID', cardData!['uid'] ?? '未知'),
            SizedBox(height: 20.h),
            _buildDataRow('卡片类型', cardData!['type'] ?? '未知'),
            if (cardData!['capacity'] != null) ...[
              SizedBox(height: 20.h),
              _buildDataRow('卡片容量', cardData!['capacity'] ?? '未知'),
            ],
            SizedBox(height: 20.h),
            _buildDataRow(
              '读取时间',
              _formatTimestamp(cardData!['timestamp']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF999999),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF333333),
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '未知';
    
    try {
      final dateTime = DateTime.parse(timestamp.toString());
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp.toString();
    }
  }
}

