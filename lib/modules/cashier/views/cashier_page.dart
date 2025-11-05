import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/cashier_controller.dart';

class CashierPage extends GetView<CashierController> {
  const CashierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          '收银页面',
          style: TextStyle(fontSize: 24.sp, color: const Color(0xFF333333)),
        ),
      ),
    );
  }
}
