// screens/error/error_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../routing/routes.dart';

class ErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final String? errorTitle;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final bool showHomeButton;
  final bool showBackButton;

  const ErrorScreen({
    super.key,
    this.errorMessage,
    this.errorTitle,
    this.onRetry,
    this.showRetryButton = true,
    this.showHomeButton = true,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(errorTitle ?? 'Error'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: showBackButton,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Error Icon with Animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 120.w,
                            height: 120.h,
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red.shade300,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: 60.sp,
                              color: Colors.red.shade600,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 32.h),

                    // Error Title
                    Text(
                      errorTitle ?? 'Oops! Something went wrong',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Error Message
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            errorMessage ??
                                'We encountered an unexpected error. Please try again or contact support if the problem persists.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),

                          if (errorMessage != null && errorMessage!.length > 50) ...[
                            SizedBox(height: 12.h),
                            // Copy Error Button
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: errorMessage!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error message copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.copy,
                                size: 16.sp,
                                color: Colors.red.shade600,
                              ),
                              label: Text(
                                'Copy Error',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Helpful Tips
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.blue.shade600,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'What you can try:',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          _buildTipItem('Check your internet connection'),
                          _buildTipItem('Close and reopen the app'),
                          _buildTipItem('Update the app if available'),
                          _buildTipItem('Contact support if problem persists'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Buttons
              Column(
                children: [
                  if (showRetryButton && onRetry != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],

                  if (showHomeButton)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            Routes.home,
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Go to Home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 28.w, top: 6.h),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 16.sp, color: Colors.blue.shade400),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
