import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/change_password_form.dart';

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '修改登录密码',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40.h),
              Container(
                constraints: BoxConstraints(maxWidth: 600.w),
                padding: EdgeInsets.all(12.w),
                child: ChangePasswordForm(
                  onConfirm: () {
                    // TODO: 调用修改密码 API
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
