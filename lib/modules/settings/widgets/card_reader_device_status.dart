import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/external_card_reader_model.dart';

/// 读卡器设备状态显示组件
class CardReaderDeviceStatus extends StatelessWidget {
  final ExternalCardReaderDevice? device;
  final ExternalCardReaderStatus status;
  final bool isScanning;

  const CardReaderDeviceStatus({
    super.key,
    required this.device,
    required this.status,
    this.isScanning = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isScanning) {
      return _buildScanningStatus();
    }

    if (device == null) {
      return _buildNoDeviceStatus();
    }

    return _buildDeviceInfo();
  }

  /// 扫描中状态
  Widget _buildScanningStatus() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF1890FF),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 32.w,
            height: 32.h,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1890FF)),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '正在扫描USB设备...',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1890FF),
            ),
          ),
        ],
      ),
    );
  }

  /// 未检测到设备状态
  Widget _buildNoDeviceStatus() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE74C3C),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.usb_off,
              size: 32.sp,
              color: const Color(0xFFE74C3C),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '未检测到读卡器设备',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFE74C3C),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '请连接USB读卡器后点击扫描按钮',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  /// 设备信息显示
  Widget _buildDeviceInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 设备名称和状态
          Row(
            children: [
              Icon(
                Icons.nfc,
                size: 24.sp,
                color: const Color(0xFF1890FF),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device!.displayName,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    _buildStatusChip(),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // 设备详细信息
          _buildInfoRow('厂商', device!.manufacturer),
          SizedBox(height: 8.h),
          if (device!.model != null) ...[
            _buildInfoRow('型号', device!.model!),
            SizedBox(height: 8.h),
          ],
          if (device!.specifications != null) ...[
            _buildInfoRow('规格', device!.specifications!),
            SizedBox(height: 8.h),
          ],
          _buildInfoRow('USB ID', device!.usbIdentifier),
          if (device!.serialNumber != null) ...[
            SizedBox(height: 8.h),
            _buildInfoRow('序列号', device!.serialNumber!),
          ],
        ],
      ),
    );
  }

  /// 状态标签
  Widget _buildStatusChip() {
    Color bgColor;
    Color textColor;
    String statusText;

    switch (status) {
      case ExternalCardReaderStatus.connected:
        bgColor = const Color(0xFF52C41A).withValues(alpha: 0.1);
        textColor = const Color(0xFF52C41A);
        statusText = '已连接';
        break;
      case ExternalCardReaderStatus.reading:
        bgColor = const Color(0xFF1890FF).withValues(alpha: 0.1);
        textColor = const Color(0xFF1890FF);
        statusText = '读卡中...';
        break;
      case ExternalCardReaderStatus.error:
        bgColor = const Color(0xFFE74C3C).withValues(alpha: 0.1);
        textColor = const Color(0xFFE74C3C);
        statusText = '错误';
        break;
      default:
        bgColor = const Color(0xFF999999).withValues(alpha: 0.1);
        textColor = const Color(0xFF999999);
        statusText = '未连接';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
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
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF999999),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  /// 获取边框颜色
  Color _getBorderColor() {
    switch (status) {
      case ExternalCardReaderStatus.connected:
        return const Color(0xFF52C41A);
      case ExternalCardReaderStatus.reading:
        return const Color(0xFF1890FF);
      case ExternalCardReaderStatus.error:
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFFD9D9D9);
    }
  }
}
