import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../modules/network_check/widgets/network_check_widget.dart';
import '../../network_check/controllers/network_check_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/version_check_controller.dart';
import 'version_check_view.dart';
import 'change_password_view.dart';
import 'placeholder_view.dart';
import 'external_card_reader_view.dart';
import 'external_printer_view.dart';
import 'qr_scanner_config_view.dart';
import 'card_registration_view.dart';
import 'game_card_management_view.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Obx(
                      () => _buildContent(controller.selectedMenu.value),
                    ),
                  ),
                ),
                _buildSidebar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final menuItems = [
      ('external_card_reader', '读卡器', Icons.nfc),
      ('qr_scanner', '二维码扫描仪', Icons.qr_code_2),
      ('external_printer', '打印机', Icons.print),
      ('network_detection', '网络检测', Icons.network_check),
      ('receipt_settings', '小票设置', Icons.receipt),
      ('card_registration', '卡片登记', Icons.card_membership),
      ('game_card_management', '游戏卡管理', Icons.games),
      ('change_password', '修改登录密码', Icons.lock),
      ('version_check', '版本检查', Icons.info),
    ];

    return Container(
      width: 200.w,
      color: const Color(0xFF2C3E50),
      child: ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final (key, label, icon) = menuItems[index];
          return Obx(
            () => Container(
              color: controller.selectedMenu.value == key
                  ? AppTheme.primaryColor
                  : Colors.transparent,
              child: InkWell(
                onTap: () => controller.selectMenu(key),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20.sp,
                        color: controller.selectedMenu.value == key
                            ? Colors.white
                            : Colors.grey[300],
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: controller.selectedMenu.value == key
                                ? Colors.white
                                : Colors.grey[300],
                            fontWeight: controller.selectedMenu.value == key
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(String selectedMenu) {
    Widget content;
    switch (selectedMenu) {
      case 'external_card_reader':
        content = const ExternalCardReaderView();
        break;
      case 'qr_scanner':
        content = const QrScannerConfigView();
        break;
      case 'external_printer':
        content = const ExternalPrinterView();
        break;
      case 'network_detection':
        _ensureNetworkCheckController();
        content = const NetworkCheckWidget();
        break;
      case 'card_registration':
        content = const CardRegistrationView();
        break;
      case 'game_card_management':
        content = const GameCardManagementView();
        break;
      case 'version_check':
        _ensureVersionCheckController();
        content = const VersionCheckView();
        break;
      case 'change_password':
        content = const ChangePasswordView();
        break;
      default:
        content = const PlaceholderView();
    }
    
    return Container(
      width: 1000.w,
      padding: EdgeInsets.all(12.w),
      child: content,
    );
  }

  void _ensureNetworkCheckController() {
    if (!Get.isRegistered<NetworkCheckController>()) {
      Get.put(NetworkCheckController());
      print('✓ 创建 NetworkCheckController');
    }
  }

  void _ensureVersionCheckController() {
    if (!Get.isRegistered<VersionCheckController>()) {
      Get.put(VersionCheckController());
    }
  }
}
