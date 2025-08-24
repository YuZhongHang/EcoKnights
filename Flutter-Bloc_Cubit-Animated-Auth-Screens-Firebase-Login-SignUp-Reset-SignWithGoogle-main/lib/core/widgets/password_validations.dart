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
        const CircleAvatar(
          radius: 2.5,
          backgroundColor: ColorsManager.gray,
        ),
        Gap(6.w),
        Text(
          text,
          style: TextStyles.font14DarkBlue500Weight.copyWith(
            decoration: hasValidated ? TextDecoration.lineThrough : null,
            decorationColor: Colors.green,
            decorationThickness: 2,
            color: hasValidated ? ColorsManager.gray : ColorsManager.darkBlue,
          ),
        )
      ],
    );
  }
}
