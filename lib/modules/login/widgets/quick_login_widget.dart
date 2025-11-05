import 'package:ailand_pos/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/quick_login_controller.dart';
import '../../../data/models/auth/quick_login_user.dart';

class QuickLoginWidget extends StatelessWidget {
  const QuickLoginWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller 已在路由配置中创建,这里直接使用
    final controller = Get.find<QuickLoginController>();

    return Obx(() {
      final users = controller.savedUsers;
      final allUsers = [QuickLoginUser(username: '', name: '新用户'), ...users];

      return Column(children: [_buildCarousel(context, controller, allUsers)]);
    });
  }

  Widget _buildCarousel(
    BuildContext context,
    QuickLoginController controller,
    List<QuickLoginUser> users,
  ) {
    return SizedBox(
      height: 340.h,
      child: Stack(
        children: [
          Obx(() => _buildAvatarList(context, controller, users)),
          _buildArrowButtons(controller, users),
        ],
      ),
    );
  }

  Widget _buildAvatarList(
    BuildContext context,
    QuickLoginController controller,
    List<QuickLoginUser> users,
  ) {
    final currentIndex = controller.currentIndex.value;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: Center(
        key: ValueKey(currentIndex),
        child: SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(users.length > 3 ? 3 : users.length, (
              index,
            ) {
              final actualIndex = _getActualIndex(
                currentIndex,
                index,
                users.length,
              );
              final user = users[actualIndex];
              final isCenter = index == 1 || (users.length == 1 && index == 0);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isCenter) {
                      // actualIndex 是 allUsers 的索引，需要转换回 controller 的索引
                      // allUsers[0] = 新用户 -> controller index = -1
                      // allUsers[1+] = 已保存用户 -> controller index = 0+
                      final controllerIndex = actualIndex - 1;
                      controller.setCurrentIndex(controllerIndex);
                    }
                  },
                  child: _buildAvatar(
                    user,
                    isCenter,
                    actualIndex,
                    controller,
                    context,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  int _getActualIndex(int currentIndex, int position, int totalCount) {
    if (totalCount == 1) return 0;

    // currentIndex 是基于 controller 的索引（-1 表示新用户，0+ 表示已保存用户）
    // 需要转换为 allUsers 数组的索引（0 是新用户，1+ 是已保存用户）
    final centerIndexInArray = currentIndex + 1;

    if (totalCount == 2) {
      // 只有2个用户时，position 0 显示左边，position 1 显示中心（当前选中）
      // 左边显示前一个，中心显示当前
      if (position == 0) {
        return (centerIndexInArray - 1 + totalCount) % totalCount;
      } else {
        return centerIndexInArray % totalCount;
      }
    }

    // 3个或以上用户时，显示前一个、当前、下一个
    // position 0 = 左边（前一个），position 1 = 中心（当前），position 2 = 右边（下一个）
    final offset = position - 1;
    return (centerIndexInArray + offset + totalCount) % totalCount;
  }

  Widget _buildAvatar(
    QuickLoginUser user,
    bool isCenter,
    int actualIndex,
    QuickLoginController controller,
    BuildContext context,
  ) {
    final isNewUser = user.username.isEmpty;
    final color = isCenter ? Colors.green : Colors.grey;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      tween: Tween(begin: isCenter ? 1.0 : 0.7, end: isCenter ? 1.0 : 0.7),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.1),
                      border: Border.all(color: color, width: isCenter ? 3 : 2),
                    ),
                    child: Center(
                      child: isNewUser
                          ? Icon(Icons.add, size: 50.w, color: color)
                          : Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 40.sp,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                    ),
                  ),
                  if (isCenter && !isNewUser)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: GestureDetector(
                        onTap: () => _showDeleteDialog(
                          context,
                          controller,
                          actualIndex - 1,
                          user.name,
                        ),
                        child: Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18.w,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                user.name,
                style: TextStyle(
                  fontSize: isCenter ? 16.sp : 14.sp,
                  fontWeight: isCenter ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArrowButtons(
    QuickLoginController controller,
    List<QuickLoginUser> users,
  ) {
    if (users.length <= 1) return const SizedBox.shrink();

    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: controller.previousUser,
            icon: Icon(Icons.chevron_left, size: 40.w),
          ),
          IconButton(
            onPressed: controller.nextUser,
            icon: Icon(Icons.chevron_right, size: 40.w),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    QuickLoginController controller,
    int index,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除账号', style: TextStyle(fontSize: 18.sp)),
        content: Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 14.sp),
            children: [
              const TextSpan(text: '是否确认将员工 '),
              TextSpan(
                text: name,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' 的账户删除显示?\n\n删除后需要重新输入账号密码登录'),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            child: Text('取消', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeUser(index);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            child: Text('删除', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}
