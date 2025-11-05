import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../data/services/external_printer_service.dart';
import '../../../data/models/external_printer_model.dart';

/// 外置打印机配置页面（优化版）
/// 移除边框，垂直分3块：扫描、信息、测试
class ExternalPrinterView extends StatelessWidget {
  const ExternalPrinterView({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保服务已注册
    ExternalPrinterService service;
    try {
      service = Get.find<ExternalPrinterService>();
    } catch (e) {
      return _buildErrorState();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 32.h),
          Expanded(
            child: _buildContent(service),
          ),
        ],
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 24.h),
            Text(
              '外置打印机服务未初始化',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '请在main.dart中添加服务初始化',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// 页面头部
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.usb,
            size: 32.sp,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '外置打印机配置',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '管理USB外接打印机设备',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 主内容区域（无边框版）
  Widget _buildContent(ExternalPrinterService service) {
    return Obx(() {
      // 扫描中状态
      if (service.isScanning.value) {
        return _buildScanningState();
      }

      // 未检测到设备
      if (service.detectedPrinters.isEmpty) {
        return Column(
          children: [
            _buildScanButton(service),
            SizedBox(height: 32.h),
            Expanded(child: _buildEmptyState()),
          ],
        );
      }

      // 有设备，显示3块布局
      final selectedDevice = service.selectedPrinter.value;
      if (selectedDevice != null) {
        return _buildThreeColumnLayout(selectedDevice, service);
      }

      // 有设备但未选择，显示扫描按钮和设备列表
      return Column(
        children: [
          _buildScanButton(service),
          SizedBox(height: 32.h),
          Expanded(child: _buildDeviceList(service)),
        ],
      );
    });
  }

  /// 三列布局（扫描、信息、测试）- 紧凑版
  Widget _buildThreeColumnLayout(
    ExternalPrinterDevice device,
    ExternalPrinterService service,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 第1块：扫描USB设备按钮
          _buildScanButton(service),

          SizedBox(height: 24.h), // 压缩间距

          // 第2块：打印机基础信息（固定高度，避免Expanded导致的空白）
          _buildPrinterInfo(device),

          SizedBox(height: 24.h), // 压缩间距

          // 第3块：测试打印按钮和状态显示区域（固定高度）
          _buildTestSection(device, service),
        ],
      ),
    );
  }

  /// 扫描按钮
  Widget _buildScanButton(ExternalPrinterService service) {
    return Obx(() => SizedBox(
          height: 50.h,
          width: 400.w,
          child: ElevatedButton.icon(
            onPressed: service.isScanning.value
                ? null
                : () => service.scanUsbPrinters(),
            icon: service.isScanning.value
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.refresh, size: 22.sp),
            label: Text(
              service.isScanning.value ? '扫描中...' : '扫描USB设备',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ));
  }

  /// 打印机基础信息卡片
  Widget _buildPrinterInfo(ExternalPrinterDevice device) {
    return Container(
      constraints: BoxConstraints(maxWidth: 500.w),
      padding: EdgeInsets.all(16.w), // 压缩内边距
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF9C27B0),
          width: 2.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 打印机名称和状态
          Row(
            children: [
              Icon(
                Icons.print,
                size: 28.sp,
                color: const Color(0xFF9C27B0),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  device.displayName,
                  style: TextStyle(
                    fontSize: 22.sp, // 增大打印机名称字号
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50), // 绿色高亮
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '已连接',
                  style: TextStyle(
                    fontSize: 14.sp, // 增大字号
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h), // 压缩标题和信息之间的间距

          // 设备信息
          _buildInfoRow('厂商', device.manufacturer),
          SizedBox(height: 8.h), // 压缩信息行间距
          _buildInfoRow('USB ID', device.usbIdentifier),
          if (device.serialNumber != null) ...[
            SizedBox(height: 8.h), // 压缩信息行间距
            _buildInfoRow('序列号', device.serialNumber!),
          ],
        ],
      ),
    );
  }

  /// 信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            '$label：',
            style: TextStyle(
              fontSize: 16.sp, // 增大标签字号
              color: const Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16.sp, // 增大值字号
              color: const Color(0xFF666666),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 测试区域（按钮 + 状态显示区域）- 固定高度避免位移
  Widget _buildTestSection(
    ExternalPrinterDevice device,
    ExternalPrinterService service,
  ) {
    return Obx(() {
      final isPrinting = service.isPrinting.value;
      final testPassed = service.testPrintSuccess.value;

      return Column(
        mainAxisSize: MainAxisSize.min, // 使用最小尺寸
        children: [
          // 测试打印按钮
          SizedBox(
            width: 400.w,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: isPrinting
                  ? null
                  : () => _testPrint(device, service),
              icon: isPrinting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.print, size: 22.sp),
              label: Text(
                isPrinting ? '打印中...' : '测试打印',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCCCCCC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),

          // 状态显示区域（固定高度60.h，避免出现时导致位移）
          SizedBox(
            height: 60.h, // 固定高度
            child: testPassed
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24.w,
                          height: 24.h,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          '测试通过',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(), // 未测试时显示空白但保持高度
          ),
        ],
      );
    });
  }

  /// 扫描中状态
  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50.w,
            height: 50.h,
            child: CircularProgressIndicator(
              strokeWidth: 4.w,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            '正在扫描USB设备...',
            style: TextStyle(
              fontSize: 17.sp,
              color: const Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.usb_off,
            size: 64.sp,
            color: const Color(0xFFCCCCCC),
          ),
          SizedBox(height: 24.h),
          Text(
            '未检测到USB打印机',
            style: TextStyle(
              fontSize: 18.sp,
              color: const Color(0xFF999999),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '请连接USB打印机后点击扫描',
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFFCCCCCC),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '支持：Epson、芯烨、佳博等品牌',
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFFCCCCCC),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// 设备列表（未选择设备时显示）
  Widget _buildDeviceList(ExternalPrinterService service) {
    return ListView.separated(
      padding: EdgeInsets.only(bottom: 20.h),
      itemCount: service.detectedPrinters.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final device = service.detectedPrinters[index];
        return _buildDeviceCard(device, service);
      },
    );
  }

  /// 设备卡片（用于设备选择）
  Widget _buildDeviceCard(
    ExternalPrinterDevice device,
    ExternalPrinterService service,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: device.isConnected
            ? const Color(0xFFF3E5F5)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: device.isConnected
              ? const Color(0xFF9C27B0)
              : const Color(0xFFE0E0E0),
          width: 2.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 设备名称和状态
          Row(
            children: [
              Icon(
                Icons.print,
                size: 24.sp,
                color: device.isConnected
                    ? const Color(0xFF9C27B0)
                    : const Color(0xFF999999),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  device.displayName,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: device.isConnected
                      ? const Color(0xFF9C27B0)
                      : const Color(0xFF999999),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  device.isConnected ? '已连接' : '未连接',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // 设备信息
          _buildDeviceInfo('厂商', device.manufacturer),
          SizedBox(height: 8.h),
          _buildDeviceInfo('USB ID', device.usbIdentifier),
          if (device.serialNumber != null) ...[
            SizedBox(height: 8.h),
            _buildDeviceInfo('序列号', device.serialNumber!),
          ],

          SizedBox(height: 16.h),

          // 授权按钮
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: device.isConnected
                  ? () => service.requestPermission(device)
                  : null,
              icon: Icon(Icons.check_circle_outline, size: 20.sp),
              label: Text(
                '授权使用',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 设备信息行
  Widget _buildDeviceInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75.w,
          child: Text(
            '$label：',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF666666),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 测试打印
  Future<void> _testPrint(
    ExternalPrinterDevice device,
    ExternalPrinterService service,
  ) async {
    final result = await service.testPrint(device);

    if (result.success) {
      // 成功时不显示snackbar，只显示测试通过状态
      service.testPrintSuccess.value = true;
    } else {
      // 失败时显示错误信息
      Get.snackbar(
        '打印失败',
        result.message,
        backgroundColor: const Color(0xFFE74C3C).withValues(alpha: 0.1),
        colorText: const Color(0xFFE74C3C),
        icon: const Icon(Icons.error, color: Color(0xFFE74C3C)),
      );
    }
  }
}
