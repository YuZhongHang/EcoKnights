import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

class PasswordValidations extends StatelessWidget {
  final bool hasMinLength;
  final bool hasSpecialChar;

  const PasswordValidations({
    super.key,
    required this.hasMinLength,
    required this.hasSpecialChar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildValidationRow('At least 8 characters', hasMinLength),
        Gap(6.h),
        buildValidationRow('At least 1 special character (!@#\$...)', hasSpecialChar),
      ],
    );
  }

  Widget buildValidationRow(String text, bool hasValidated) {
    return Row(
      children: [
      hasValidated
          ? const Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green,
            )
          : const CircleAvatar(
              radius: 3,
              backgroundColor: ColorsManager.gray,
            ),
        Gap(6.w),
        Text(
          text,
          style: TextStyles.font14DarkBlue500Weight.copyWith(
            color: hasValidated ? Colors.green : ColorsManager.gray,
          ),
        )
      ],
    );
  }
}
