import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/storage/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/auth_service.dart';
import '../../core/utils/navigation_helper.dart';
import 'change_password_form.dart';

/// AppHeader 专用控制器
/// 管理头部组件的交互逻辑，包括修改密码、退出登录等
class AppHeaderController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final AuthService _authService = AuthService();

  /// 显示退出登录确认对话框
  Future<void> showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('确认退出', style: TextStyle(fontSize: 18.sp)),
        content: SizedBox(
          width: 400.w,
          child: Text('您确定要退出登录吗?', style: TextStyle(fontSize: 14.sp)),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text('取消', style: TextStyle(fontSize: 16.sp)),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text('确定', style: TextStyle(fontSize: 16.sp)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    // 在对话框关闭后再执行退出登录
    if (result == true) {
      await logout();
    }
  }

  /// 退出登录
  Future<void> logout() async {
    print('logout');
    try {
      // 先调用退出登录 API（此时 token 还在，可以正常请求）
      await _authService.logout();
    } catch (e) {
      debugPrint('退出登录 API 调用失败: $e');
    }
    print('logout success');
    // 清除本地存储的用户数据
    await _storage.remove(StorageKeys.token);
    await _storage.remove(StorageKeys.tokenName);
    await _storage.remove(StorageKeys.userId);
    await _storage.remove(StorageKeys.username);
    await _storage.remove(StorageKeys.merchantCode);

    // 使用导航辅助类，自动清理首页相关 Controller
    NavigationHelper.homeToLogin();
  }

  /// 显示修改密码对话框
  Future<void> showChangePasswordDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('修改登录密码', style: TextStyle(fontSize: 18.sp)),
        content: SizedBox(
          width: 400.w,
          child: ChangePasswordForm(
            onConfirm: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
      ),
    );

    if (result == true && context.mounted) {
      // TODO: 调用修改密码 API
      debugPrint('修改密码成功');
    }
  }
}
