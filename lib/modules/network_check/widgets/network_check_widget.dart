import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/network_check_controller.dart';
import '../../../data/models/network_status.dart';
import '../../../l10n/app_localizations.dart';

class NetworkCheckWidget extends GetView<NetworkCheckController> {
  const NetworkCheckWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 标题
        Center(
          child: Text(
            l10n.networkAutoCheck,
            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 32.h),

        // 连接状态区域
        Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 外网连接状态
              _buildCheckItem(
                label: l10n.externalConnectionStatus,
                statusObservable: controller.externalConnectionStatus,
              ),
              SizedBox(height: 16.h),
              // 中心服务器连接状态
              _buildCheckItem(
                label: l10n.centerServerConnectionStatus,
                statusObservable: controller.centerServerConnectionStatus,
              ),
              SizedBox(height: 16.h),
              // 外网Ping检测
              _buildCheckItem(
                label: l10n.externalPingResult,
                statusObservable: controller.externalPingStatus,
                showLatency: true,
              ),
              SizedBox(height: 16.h),

              // DNS服务Ping
              _buildCheckItem(
                label: l10n.dnsPingResult,
                statusObservable: controller.dnsPingStatus,
                showLatency: true,
              ),
              SizedBox(height: 16.h),
              // 中心服务Ping
              _buildCheckItem(
                label: l10n.centerServerPingResult,
                statusObservable: controller.centerServerPingStatus,
                showLatency: true,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: controller.checkAll,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        l10n.refreshCheck,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem({
    required String label,
    required Rx<NetworkCheckResult> statusObservable,
    bool showLatency = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200, width: 1.w),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
          ),
          Obx(() {
            final result = statusObservable.value;
            return _buildStatusIndicator(result);
          }),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(NetworkCheckResult result) {
    switch (result.status) {
      case NetworkCheckStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.remove, size: 18.sp, color: Colors.grey.shade400),
            SizedBox(width: 8.w),
            Text(
              controller.getStatusText(result),
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
          ],
        );

      case NetworkCheckStatus.checking:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.h,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orange.shade400,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              controller.getStatusText(result),
              style: TextStyle(fontSize: 14.sp, color: Colors.orange.shade600),
            ),
          ],
        );

      case NetworkCheckStatus.success:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 18.sp, color: Colors.green.shade600),
            SizedBox(width: 8.w),
            Text(
              controller.getStatusText(result),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case NetworkCheckStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, size: 18.sp, color: Colors.red.shade600),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                controller.getStatusText(result),
                style: TextStyle(fontSize: 14.sp, color: Colors.red.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
    }
  }
}
