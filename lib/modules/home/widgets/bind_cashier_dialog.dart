import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/theme/app_theme.dart';

/// 绑定收银台弹窗
class BindCashierDialog extends StatefulWidget {
  const BindCashierDialog({super.key});

  @override
  State<BindCashierDialog> createState() => _BindCashierDialogState();
}

class _BindCashierDialogState extends State<BindCashierDialog> {
  final TextEditingController _deviceIdController = TextEditingController();
  String _selectedType = '收银台';
  final List<String> _typeOptions = ['收银台', '自助机', '其他'];

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Container(
        width: 600.w,
        padding: EdgeInsets.all(40.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(),
            SizedBox(height: 32.h),
            _buildDescription(),
            SizedBox(height: 40.h),
            _buildDeviceIdInput(),
            SizedBox(height: 24.h),
            _buildTypeSelector(),
            SizedBox(height: 40.h),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      '此设备未绑定收银点',
      style: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      '请到安卓系统设置中找到设备ID,填入到输入框中,待总部审核后,完成收银点绑定',
      style: TextStyle(
        fontSize: 14.sp,
        color: const Color(0xFF666666),
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDeviceIdInput() {
    return Row(
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            '设备ID:',
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF333333)),
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Container(
            height: 48.h,

            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.w),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: TextField(
              controller: _deviceIdController,
              style: TextStyle(fontSize: 16.sp, color: const Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: '请输入',
                hintStyle: TextStyle(fontSize: 16.sp),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            '点位类型:',
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF333333)),
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.w),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color(0xFF999999),
                  size: 20.sp,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(0xFF333333),
                ),
                items: _typeOptions.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: 250.w,
      height: 48.h,
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        child: Text(
          '提交绑定',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _handleSubmit() {
    final deviceId = _deviceIdController.text.trim();

    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入设备ID', style: TextStyle(fontSize: 14.sp)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: 实际提交逻辑
    print('提交绑定 - 设备ID: $deviceId, 点位类型: $_selectedType');

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('绑定申请已提交,请等待审核', style: TextStyle(fontSize: 14.sp)),
        backgroundColor: Colors.green,
      ),
    );
  }
}
