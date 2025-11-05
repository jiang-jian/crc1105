import 'package:ailand_pos/app/routes/router_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../controllers/device_setup_controller.dart';
import 'nfc_setup_page.dart';
import 'scanner_setup_page.dart';
import 'printer_setup_page.dart';

/// 设备初始化主页面
class DeviceSetupPage extends GetView<DeviceSetupController> {
  const DeviceSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Obx(() {
          // 根据当前步骤显示不同页面
          switch (controller.currentStep.value) {
            case DeviceSetupStep.scanner:
              return const ScannerSetupPage();
            case DeviceSetupStep.cardReader:
              return const NfcSetupPage();
            case DeviceSetupStep.printer:
              return const PrinterSetupPage();
            case DeviceSetupStep.completed:
              return _buildCompletedPage();
          }
        }),
      ),
    );
  }

  /// 处理返回按钮
  void _handleBackPress() {
    print('[DeviceSetup] 处理返回按钮，当前步骤: ${controller.currentStep.value}, 读卡状态: ${controller.cardReadStatus.value}');
    
    // 如果正在读卡中，不允许返回
    if (controller.cardReadStatus.value == 'reading') {
      print('[DeviceSetup] 正在读卡中，阻止返回');
      Get.snackbar(
        '提示',
        '正在读取卡片，请稍候...',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
      );
      return;
    }

    // 如果在读卡器步骤，先清理
    if (controller.currentStep.value == DeviceSetupStep.cardReader) {
      print('[DeviceSetup] 在读卡器步骤，先清理状态');
      controller.cleanupCardReaderStep();
    }

    // 其他情况下允许返回
    if (controller.currentStep.value != DeviceSetupStep.scanner) {
      print('[DeviceSetup] 返回上一步');
      controller.previousStep();
    } else {
      print('[DeviceSetup] 退出设备设置');
      AppRouter.pop();
    }
  }

  /// 构建完成页面
  Widget _buildCompletedPage() {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: const BoxDecoration(
                color: Color(0xFF52C41A),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 50.sp, color: Colors.white),
            ),
            SizedBox(height: 24.h),
            Text(
              '设置完成',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 48.h),
            Container(
              constraints: BoxConstraints(maxWidth: 600.w),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () => AppRouter.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '开始营业',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
