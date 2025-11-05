import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../controllers/device_setup_controller.dart';

/// 设备初始化侧边栏导航
class DeviceSetupSidebar extends GetView<DeviceSetupController> {
  const DeviceSetupSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280.w,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.devices_other,
                    size: 24.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '设备初始化',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // 步骤列表
          Expanded(
            child: Obx(() => ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _buildStepItem(
                  icon: Icons.qr_code_scanner,
                  title: '扫码枪设置',
                  subtitle: '第一步',
                  step: DeviceSetupStep.scanner,
                  isCompleted: controller.scannerCompleted.value,
                ),
                SizedBox(height: 12.h),
                _buildStepItem(
                  icon: Icons.credit_card,
                  title: '读卡器设置',
                  subtitle: '第二步',
                  step: DeviceSetupStep.cardReader,
                  isCompleted: controller.cardReaderCompleted.value,
                ),
                SizedBox(height: 12.h),
                _buildStepItem(
                  icon: Icons.print,
                  title: '打印机设置',
                  subtitle: '第三步',
                  step: DeviceSetupStep.printer,
                  isCompleted: controller.printerCompleted.value,
                ),
                SizedBox(height: 12.h),
                _buildStepItem(
                  icon: Icons.check_circle,
                  title: '设置完成',
                  subtitle: '完成',
                  step: DeviceSetupStep.completed,
                  isCompleted: false,
                ),
              ],
            )),
          ),
          
          // 底部提示
          Container(
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFF1890FF).withValues(alpha: 0.2),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20.sp,
                  color: const Color(0xFF1890FF),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '请按顺序完成设备设置',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF1890FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建步骤项
  Widget _buildStepItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required DeviceSetupStep step,
    required bool isCompleted,
  }) {
    final isCurrent = controller.currentStep.value == step;
    final isActive = isCurrent || isCompleted;
    
    return InkWell(
      onTap: () {
        // 可以添加点击切换步骤的逻辑
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isCurrent 
              ? const Color(0xFFFFF8E1) 
              : isCompleted
                  ? const Color(0xFFF0F7FF)
                  : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isCurrent
                ? AppTheme.primaryColor
                : isCompleted
                    ? const Color(0xFF1890FF)
                    : Colors.transparent,
            width: 2.w,
          ),
        ),
        child: Row(
          children: [
            // 图标或状态
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppTheme.primaryColor
                    : isCompleted
                        ? const Color(0xFF52C41A)
                        : const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                size: 24.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12.w),
            // 文字信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isActive 
                          ? const Color(0xFF333333)
                          : const Color(0xFF999999),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isActive
                          ? const Color(0xFF666666)
                          : const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
            ),
            // 箭头或勾选
            if (isCurrent)
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: AppTheme.primaryColor,
              )
            else if (isCompleted)
              Container(
                width: 20.w,
                height: 20.h,
                decoration: const BoxDecoration(
                  color: Color(0xFF52C41A),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 14.sp,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

