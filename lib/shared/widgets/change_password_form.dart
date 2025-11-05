import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePasswordForm extends StatefulWidget {
  final VoidCallback? onConfirm;

  const ChangePasswordForm({
    super.key,
    this.onConfirm,
  });

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  late TextEditingController oldPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  @override
  void initState() {
    super.initState();
    oldPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (oldPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入旧密码', style: TextStyle(fontSize: 14.sp))),
      );
      return;
    }
    if (newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入新密码', style: TextStyle(fontSize: 14.sp))),
      );
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('两次输入的密码不一致', style: TextStyle(fontSize: 14.sp))),
      );
      return;
    }
    widget.onConfirm?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          TextField(
            controller: oldPasswordController,
            obscureText: true,
            style: TextStyle(fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: '请输入旧密码',
              hintStyle: TextStyle(fontSize: 16.sp),
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: newPasswordController,
            obscureText: true,
            style: TextStyle(fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: '请输入新密码',
              hintStyle: TextStyle(fontSize: 16.sp),
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: confirmPasswordController,
            obscureText: true,
            style: TextStyle(fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: '请再次输入新密码',
              hintStyle: TextStyle(fontSize: 16.sp),
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
                child: Text(
                  '取消',
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
                child: Text(
                  '确定',
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
