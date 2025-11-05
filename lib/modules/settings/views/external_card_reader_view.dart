import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../data/services/external_card_reader_service.dart';
import '../../../data/models/external_card_reader_model.dart';

class ExternalCardReaderView extends StatelessWidget {
  const ExternalCardReaderView({super.key});

  @override
  Widget build(BuildContext context) {
    ExternalCardReaderService service;
    try {
      service = Get.find<ExternalCardReaderService>();
    } catch (e) {
      service = Get.put(ExternalCardReaderService());
      service.init();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Obx(() {
        final isReading = service.isReading.value;
        final cardData = service.cardData.value;
        final hasError = service.lastError.value != null;
        
        String cardReadStatus;
        if (isReading) {
          cardReadStatus = 'reading';
        } else if (cardData != null && cardData['isValid'] == true) {
          cardReadStatus = 'success';
        } else if (hasError) {
          cardReadStatus = 'failed';
        } else {
          cardReadStatus = 'waiting';
        }

        return _buildThreeColumnLayout(service, cardReadStatus);
      }),
    );
  }

  Widget _buildThreeColumnLayout(ExternalCardReaderService service, String cardReadStatus) {
    return Obx(() {
      final selectedDevice = service.selectedReader.value;
      
      return Row(
        children: [
          // 左列：设备基础信息 (30%)
          Expanded(
            flex: 30,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border(
                  right: BorderSide(color: const Color(0xFFE0E0E0), width: 1.w),
                ),
              ),
              child: _buildDeviceBasicInfo(service, selectedDevice),
            ),
          ),
          
          // 中列：读卡器配置 (35%)
          Expanded(
            flex: 35,
            child: Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                border: Border(
                  right: BorderSide(color: const Color(0xFFE0E0E0), width: 1.w),
                ),
              ),
              child: _buildCardReaderConfig(service, cardReadStatus),
            ),
          ),
          
          // 右列：扫描按钮+卡片数据 (35%)
          Expanded(
            flex: 35,
            child: Container(
              padding: EdgeInsets.all(32.w),
              color: Colors.white,
              child: _buildCardDataSection(service, cardReadStatus),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDeviceBasicInfo(ExternalCardReaderService service, ExternalCardReaderDevice? device) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          '设备信息',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        
        SizedBox(height: 32.h),
        
        // 扫描按钮
        _buildScanButton(service),
        
        SizedBox(height: 32.h),
        
        // 设备信息内容
        Expanded(
          child: Obx(() {
            if (service.isScanning.value) {
              return _buildScanningState();
            }
            
            if (device == null) {
              return _buildNoDeviceState();
            }
            
            return _buildDeviceInfoList(device);
          }),
        ),
      ],
    );
  }

  Widget _buildScanButton(ExternalCardReaderService service) {
    return Obx(() => SizedBox(
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: service.isScanning.value ? null : () => service.scanUsbReaders(),
        icon: service.isScanning.value
            ? SizedBox(
                width: 18.w,
                height: 18.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.refresh, size: 20.sp),
        label: Text(
          service.isScanning.value ? '扫描中...' : '扫描USB设备',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5B544),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD9D9D9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          elevation: 2,
        ),
      ),
    ));
  }

  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50.w,
            height: 50.h,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5B544)),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '扫描中...',
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDeviceState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 60.sp, color: const Color(0xFFBDC3C7)),
          SizedBox(height: 16.h),
          Text(
            '未检测到设备',
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF999999)),
          ),
          SizedBox(height: 8.h),
          Text(
            '请连接USB读卡器',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFFBDC3C7)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoList(ExternalCardReaderDevice device) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 连接状态
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFF52C41A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10.w,
                  height: 10.h,
                  decoration: const BoxDecoration(
                    color: Color(0xFF52C41A),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '设备已连接',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF52C41A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // 设备详细信息
          _buildInfoItem('厂商', device.manufacturer, Icons.business),
          SizedBox(height: 16.h),
          _buildInfoItem('型号', device.model ?? 'Unknown', Icons.device_hub),
          SizedBox(height: 16.h),
          _buildInfoItem('规格', device.specifications ?? 'Unknown', Icons.info_outline),
          SizedBox(height: 16.h),
          _buildInfoItem('USB ID', device.usbIdentifier, Icons.usb),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: const Color(0xFFE5B544)),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF333333),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCardReaderConfig(ExternalCardReaderService service, String cardReadStatus) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '读卡器配置',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        
        SizedBox(height: 48.h),
        
        _buildCardIcon(cardReadStatus),
        
        SizedBox(height: 48.h),
        
        _buildStatusText(service, cardReadStatus),
        
        SizedBox(height: 32.h),
        
        if (cardReadStatus == 'failed') _buildRetryButton(service),
      ],
    );
  }

  Widget _buildCardIcon(String cardReadStatus) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Container(
            width: 180.w,
            height: 180.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(cardReadStatus),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: _getGradientColors(cardReadStatus)[0].withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.credit_card, size: 90.sp, color: Colors.white),
                if (cardReadStatus == 'reading')
                  Positioned(
                    bottom: 35.h,
                    child: SizedBox(
                      width: 35.w,
                      height: 35.h,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3.w,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _getGradientColors(String status) {
    switch (status) {
      case 'success':
        return [const Color(0xFF52C41A), const Color(0xFF389E0D)];
      case 'failed':
        return [const Color(0xFFE74C3C), const Color(0xFFC0392B)];
      case 'reading':
      case 'waiting':
      default:
        return [const Color(0xFF1890FF), const Color(0xFF096DD9)];
    }
  }

  Widget _buildStatusText(ExternalCardReaderService service, String cardReadStatus) {
    String text;
    Color color;
    IconData? icon;

    switch (cardReadStatus) {
      case 'waiting':
      case 'reading':
        text = '请将 M1 卡片靠近外置读卡器...';
        color = const Color(0xFF1890FF);
        icon = Icons.contactless;
        break;
      case 'success':
        text = '✓ 读取成功';
        color = const Color(0xFF52C41A);
        icon = Icons.check_circle;
        break;
      case 'failed':
        text = service.lastError.value ?? '读取失败，请重试';
        color = const Color(0xFFE74C3C);
        icon = Icons.error;
        break;
      default:
        text = '准备读卡...';
        color = const Color(0xFF999999);
        icon = Icons.nfc;
    }

    return Column(
      children: [
        Icon(icon, size: 36.sp, color: color),
        SizedBox(height: 14.h),
        Text(
          text,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRetryButton(ExternalCardReaderService service) {
    return SizedBox(
      width: 180.w,
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: () {
          service.clearCardData();
          service.lastError.value = null;
        },
        icon: Icon(Icons.refresh, size: 18.sp),
        label: Text('重新读卡', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5B544),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildCardDataSection(ExternalCardReaderService service, String cardReadStatus) {
    return Obx(() {
      final cardData = service.cardData.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '卡片数据',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          
          SizedBox(height: 32.h),
          
          Expanded(
            child: cardData != null && cardReadStatus == 'success'
                ? _buildCardDataDisplay(cardData, service)
                : _buildCardPlaceholder(cardReadStatus),
          ),
        ],
      );
    });
  }

  Widget _buildCardPlaceholder(String cardReadStatus) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cardReadStatus == 'reading' ? Icons.sync : Icons.credit_card_outlined,
              size: 60.sp,
              color: const Color(0xFFBDC3C7),
            ),
            SizedBox(height: 16.h),
            Text(
              cardReadStatus == 'reading' ? '正在读取卡片...' : '等待读卡',
              style: TextStyle(fontSize: 16.sp, color: const Color(0xFF999999), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDataDisplay(Map<String, dynamic> cardData, ExternalCardReaderService service) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFF52C41A).withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4.w,
                  height: 20.h,
                  decoration: BoxDecoration(color: const Color(0xFF52C41A), borderRadius: BorderRadius.circular(2.r)),
                ),
                SizedBox(width: 12.w),
                Text('读取数据', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF333333))),
                const Spacer(),
                IconButton(
                  onPressed: () => service.clearCardData(),
                  icon: Icon(Icons.clear, size: 18.sp),
                  tooltip: '清除数据',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: const Color(0xFF999999),
                ),
              ],
            ),
            
            SizedBox(height: 20.h),
            
            _buildCardDataRow('卡片 UID', cardData['uid'] ?? '未知'),
            SizedBox(height: 14.h),
            _buildCardDataRow('卡片类型', cardData['type'] ?? '未知'),
            if (cardData['capacity'] != null) ...[
              SizedBox(height: 14.h),
              _buildCardDataRow('卡片容量', cardData['capacity'] ?? '未知'),
            ],
            SizedBox(height: 14.h),
            _buildCardDataRow('读取时间', _formatTimestamp(cardData['timestamp'])),
            
            if (cardData['isValid'] == true) ...[
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF52C41A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 18.sp, color: const Color(0xFF52C41A)),
                    SizedBox(width: 8.w),
                    Text('卡片验证通过', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: const Color(0xFF52C41A))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardDataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90.w,
          child: Text(label, style: TextStyle(fontSize: 13.sp, color: const Color(0xFF999999), fontWeight: FontWeight.w500)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13.sp, color: const Color(0xFF333333), fontWeight: FontWeight.w600, fontFamily: 'monospace')),
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
