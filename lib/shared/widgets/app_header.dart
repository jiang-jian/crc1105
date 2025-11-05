import 'package:ailand_pos/app/routes/router_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../core/controllers/locale_controller.dart';
import 'marquee_text.dart';
import 'app_header_controller.dart';
import 'breadcrumb.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  /// 检查当前是否在绑定页面
  bool _isBindingPage(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    return currentRoute == '/bind-cashier';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 使用 Get.find 获取已存在的 HomeController（用于获取用户信息）
    final homeController = Get.find<HomeController>();

    final headerController = Get.find<AppHeaderController>();
    // 获取语言控制器
    final localeController = Get.find<LocaleController>();

    final isBindingPage = _isBindingPage(context);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        children: [
          Row(
            children: [
              // 用户信息容器（带 PopupMenu）
              PopupMenuButton<String>(
                offset: Offset(0, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'change_password',
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text('修改登录密码', style: TextStyle(fontSize: 16.sp)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text('交班退出登录', style: TextStyle(fontSize: 16.sp)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'change_password') {
                    headerController.showChangePasswordDialog(context);
                  } else if (value == 'logout') {
                    headerController.showLogoutDialog(context);
                  }
                },
                child: Obx(
                  () => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 用户头像
                        Container(
                          width: 32.w,
                          height: 32.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 18.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // 用户名
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.cashier}${homeController.username.value}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF333333),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 24.w),
              Text(
                '我是门店名称',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 24.w),
              Icon(Icons.chevron_right, size: 16.sp, color: Colors.grey),
              SizedBox(width: 8.w),
              SizedBox(
                width: 300.w, // 固定宽度，防止跑马灯位置变动
                child: Breadcrumb(
                  items: Breadcrumb.fromContext(context),
                  disabled: isBindingPage,
                ),
              ),
              SizedBox(width: 24.w),
              // 跑马灯通知
              Container(
                width: 970.w,
                height: 32.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: 16.sp,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: MarqueeText(
                        text:
                            'This is a test message! System update! New promotion~This is a test message! System update! New promotion~This is a test message! System update! New promotion~This is a test message! System update! New promotion~',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildIconButton(
                Icons.notifications_outlined,
                isBindingPage
                    ? null
                    : () {
                        AppRouter.push('/notification-center');
                      },
                showBadge: true,
                disabled: isBindingPage,
              ),
              SizedBox(width: 12.w),
              // 语言切换按钮
              Obx(
                () => _buildLanguageButton(
                  localeController.currentLanguageText,
                  () => localeController.toggleLocale(),
                ),
              ),
              SizedBox(width: 12.w),
              _buildIconButton(Icons.help_outline, () {}),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建图标按钮
  Widget _buildIconButton(
    IconData icon,
    VoidCallback? onPressed, {
    bool showBadge = false,
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onPressed,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFE8E8E8) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: disabled ? const Color(0xFFCCCCCC) : const Color(0xFF666666),
            ),
            if (showBadge && !disabled)
              Positioned(
                right: 8.w,
                top: 8.h,
                child: Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE74C3C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建语言切换按钮
  Widget _buildLanguageButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 20.sp, color: const Color(0xFF666666)),
            SizedBox(width: 6.w),
            Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
