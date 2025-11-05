import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../controllers/bind_cashier_controller.dart';

/// 绑定收银台页面
class BindCashierPage extends GetView<BindCashierController> {
  const BindCashierPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 将 context 传递给 controller
    controller.setContext(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Container(
          width: 900.w,
          padding: EdgeInsets.all(56.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitle(),
              SizedBox(height: 16.h),
              _buildDescription(),
              SizedBox(height: 48.h),
              _buildDeviceIdInput(),
              SizedBox(height: 32.h),
              _buildTypeSelector(),
              SizedBox(height: 48.h),
              _buildSubmitButton(),
            ],
          ),
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
              controller: controller.deviceIdController,
              readOnly: true,
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
          child: Obx(
            () => Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: controller.selectedType.value != null
                      ? AppTheme.primaryColor
                      : const Color(0xFFE0E0E0),
                  width: 1.5.w,
                ),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: controller.selectedType.value,
                  isExpanded: true,
                  icon: Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: controller.selectedType.value != null
                          ? AppTheme.primaryColor
                          : const Color(0xFFCCCCCC),
                      size: 22.sp,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                  hint: Text(
                    '请选择点位类型',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: const Color(0xFFBBBBBB),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        '请选择点位类型',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFFBBBBBB),
                        ),
                      ),
                    ),
                    ...controller.typeOptions.map((String type) {
                      return DropdownMenuItem<String?>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                  ],
                  onChanged: (String? newValue) {
                    controller.selectedType.value = newValue;
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: controller.handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        child: Text(
          '提交绑定',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
