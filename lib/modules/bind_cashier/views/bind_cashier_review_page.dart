import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/theme/app_theme.dart';

/// 绑定审核中页面
class BindCashierReviewPage extends StatelessWidget {
  const BindCashierReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Container(
          width: 900.w,
          padding: EdgeInsets.all(56.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              SizedBox(height: 32.h),
              _buildTitle(),
              SizedBox(height: 16.h),
              _buildDescription(),
              SizedBox(height: 48.h),
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40.r),
      ),
      child: Center(
        child: Icon(
          Icons.hourglass_empty,
          size: 40.sp,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      '审核中',
      style: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      '您的绑定申请已提交，我们会尽快为您审核',
      style: TextStyle(
        fontSize: 14.sp,
        color: const Color(0xFF666666),
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.w),
      ),
      child: Column(
        children: [
          _buildInfoRow('状态', '审核中'),
          SizedBox(height: 16.h),
          _buildInfoRow('预计时间', '1-3个工作日'),
          SizedBox(height: 16.h),
          _buildInfoRow('通知方式', '短信/邮件通知'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
