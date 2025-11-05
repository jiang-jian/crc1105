import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/quick_login_widget.dart';
import '../../network_check/widgets/network_check_widget.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  // 统一的水平内边距
  static final _horizontalPadding = EdgeInsets.symmetric(horizontal: 80.w);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // 左侧：网络检测区域
            Expanded(
              child: Container(
                padding: EdgeInsets.all(40.w),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: const NetworkCheckWidget(),
              ),
            ),
            // 右侧：登录区域
            Expanded(child: Center(child: _buildLoginSection(context, l10n))),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: _horizontalPadding, child: const QuickLoginWidget()),
        Divider(height: 1.h, thickness: 1.h),
        SizedBox(height: 24.h),
        Padding(
          padding: _horizontalPadding,
          child: Obx(
            () => controller.isQuickLogin.value
                ? _buildQuickLoginInputs(l10n, context)
                : _buildFullLoginInputs(l10n, context),
          ),
        ),
        SizedBox(height: 48.h),
        Padding(
          padding: _horizontalPadding,
          child: _buildLoginButton(l10n, context),
        ),
      ],
    );
  }

  Widget _buildFullLoginInputs(AppLocalizations l10n, BuildContext context) {
    return Column(
      children: [
        _buildUsernameInput(l10n),
        SizedBox(height: 24.h),
        _buildPasswordInput(l10n, context),
      ],
    );
  }

  Widget _buildQuickLoginInputs(AppLocalizations l10n, BuildContext context) {
    return Column(
      children: [
        _buildPasswordInput(l10n, context),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildUsernameInput(AppLocalizations l10n) {
    return TextField(
      controller: controller.usernameController,
      keyboardType: TextInputType.text,
      style: TextStyle(fontSize: 16.sp),
      decoration: InputDecoration(
        hintText: l10n.enterUsername,
        hintStyle: TextStyle(fontSize: 16.sp),
      ),
    );
  }

  Widget _buildPasswordInput(AppLocalizations l10n, BuildContext context) {
    return Obx(
      () => TextField(
        controller: controller.passwordController,
        obscureText: controller.obscurePassword.value,
        textInputAction: TextInputAction.done,
        style: TextStyle(fontSize: 16.sp),
        onSubmitted: (_) {
          if (!controller.isLoading.value) {
            controller.login(context);
          }
        },
        decoration: InputDecoration(
          hintText: l10n.enterPassword,
          hintStyle: TextStyle(fontSize: 16.sp),
          suffixIcon: IconButton(
            icon: Icon(
              controller.obscurePassword.value
                  ? Icons.visibility_off
                  : Icons.visibility,
              size: 20.sp,
            ),
            onPressed: controller.togglePasswordVisibility,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AppLocalizations l10n, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: Obx(
        () => ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : () => controller.login(context),
          child: controller.isLoading.value
              ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.w,
                  ),
                )
              : Text(
                  l10n.login,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
