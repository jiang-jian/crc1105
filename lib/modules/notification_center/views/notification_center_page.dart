import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../controllers/notification_center_controller.dart';

class NotificationCenterPage extends GetView<NotificationCenterController> {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 顶部操作栏
          _buildTopBar(),
          // 消息列表
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.messages.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: controller.refreshMessages,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    return _buildMessageItem(message);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 构建顶部操作栏
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1.w),
        ),
      ),
      child: Row(
        children: [
          Text(
            '消息中心',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          SizedBox(width: 16.w),
          Obx(() {
            final unreadCount = controller.unreadCount;
            if (unreadCount == 0) return const SizedBox.shrink();
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '$unreadCount',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
          const Spacer(),
          TextButton.icon(
            onPressed: controller.markAllAsRead,
            icon: Icon(Icons.done_all, size: 18.sp),
            label: Text('全部已读', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  /// 构建消息项
  Widget _buildMessageItem(message) {
    final timeFormat = DateFormat('MM-dd HH:mm');
    final isToday = DateTime.now().difference(message.time).inHours < 24;
    final timeStr = isToday
        ? DateFormat('HH:mm').format(message.time)
        : timeFormat.format(message.time);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧图标
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: message.isRead
                      ? Colors.grey.shade200
                      : AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  message.icon,
                  size: 24.sp,
                  color: message.isRead
                      ? Colors.grey.shade600
                      : AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: 16.w),
              // 中间内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: message.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                        // 未读标识
                        if (!message.isRead)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            margin: EdgeInsets.only(left: 8.w),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      message.description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF666666),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              // 右侧时间
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
        // 分割线
        Divider(height: 1.h, thickness: 1.h),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无消息',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
