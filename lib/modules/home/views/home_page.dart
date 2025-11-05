import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../controllers/home_controller.dart';
import '../widgets/menu_card.dart';
import '../../../l10n/app_localizations.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            _buildInfoBar(context, l10n),
            SizedBox(height: 16.h),
            _buildMenuGrid(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.phone, size: 18.sp, color: const Color(0xFF666666)),
        SizedBox(width: 4.w),
        Text(
          '${l10n.customerService}400-223-1133',
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF666666)),
        ),
        SizedBox(width: 24.w),
        Icon(Icons.store, size: 18.sp, color: const Color(0xFF666666)),
        SizedBox(width: 4.w),
        Obx(
          () => Text(
            '${l10n.merchantCode}${controller.merchantCode.value}',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF666666)),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid(AppLocalizations l10n) {
    final menus = [
      {'title': l10n.quickCheckout, 'color': AppTheme.primaryColor, 'path': '/cashier'},
      {'title': l10n.giftExchange, 'color': const Color(0xFFE8E8E8), 'path': null},
      {'title': l10n.customerCenter, 'color': const Color(0xFFE8E8E8), 'path': null},
      {'title': l10n.exchangeVerification, 'color': const Color(0xFFE8E8E8), 'path': null},
      {'title': l10n.activityCenter, 'color': const Color(0xFFE8E8E8), 'path': null},
      {'title': l10n.orderCenter, 'color': const Color(0xFFE8E8E8), 'path': null},
      {'title': l10n.businessReport, 'color': const Color(0xFFE8E8E8), 'path': null},
      {'title': l10n.financialManagement, 'color': const Color(0xFFE8E8E8), 'path': null},
      {'title': '设备初始化', 'color': AppTheme.primaryColor, 'path': '/device-setup'},
      {'title': 'Sunmi SDK', 'color': const Color(0xFF4CAF50), 'path': '/sunmi-customer-api'},
      {'title': l10n.settings, 'color': const Color(0xFFE8E8E8), 'path': '/settings'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1.2,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        return MenuCard(
          title: menus[index]['title'] as String,
          color: menus[index]['color'] as Color,
          onTap: () => controller.onMenuTap(menus[index]['path'] as String?),
        );
      },
    );
  }
}
