import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../controllers/device_setup_controller.dart';
import '../widgets/device_setup_layout.dart';

/// 扫码枪设置页面
class ScannerSetupPage extends GetView<DeviceSetupController> {
  const ScannerSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceSetupLayout(
      currentStep: 1,
      title: '扫码枪',
      statusSection: _buildDeviceStatus(),
      instructionsSection: _buildScanInstructions(),
      actionButtons: _buildScannerIcon(),
      recognitionStatus: _buildScanStatus(),
      bottomButtons: _buildBottomButtons(),
    );
  }

  Widget _buildDeviceStatus() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFF52C41A), width: 2.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: const BoxDecoration(
                  color: Color(0xFF52C41A),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 24.sp, color: Colors.white),
              ),
              SizedBox(width: 12.w),
              Text(
                '扫码枪已连接到设备',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF52C41A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanInstructions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          _buildInstructionItem('1', '请扫描包装盒上的条形码'),
          SizedBox(height: 16.h),
          _buildInstructionItem('2', '扫描下方验证条形码'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28.w,
          height: 28.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          text,
          style: TextStyle(fontSize: 13.sp, color: const Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildScannerIcon() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600.w),
        child: Column(
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 60.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanStatus() {
    return Column(
      children: [
        Icon(Icons.check_circle, size: 40.sp, color: const Color(0xFF52C41A)),
        SizedBox(height: 12.h),
        Text(
          '✓ 扫描通过',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF52C41A),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600.w),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () {
                  controller.scannerCompleted.value = true;
                  controller.nextStep();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '下一步',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: controller.skipCurrentStep,
              child: Text(
                '稍后设置"硬件"',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF1890FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
