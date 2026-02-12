import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../../../ui/common/app_dialogs.dart';
import 'forgot_password_viewmodel.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    Provider.of<ForgotPasswordViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verifikasi OTP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Masukkan Kode',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Consumer<ForgotPasswordViewModel>(
                                builder: (context, vm, _) => Text(
                                  'Kode 6 digit telah dikirim ke:\n${vm.emailController.text}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Consumer<ForgotPasswordViewModel>(
                                builder: (context, vm, _) => TextField(
                                  controller: vm.otpController,
                                  decoration: const InputDecoration(
                                    labelText: 'Kode OTP',
                                    hintText: 'xxxxxx',
                                    border: OutlineInputBorder(),
                                    counterText: "",
                                  ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 6,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    letterSpacing: 8,
                                  ),
                                  enabled: !vm.isLoading,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 50,
                                child: Consumer<ForgotPasswordViewModel>(
                                  builder: (context, vm, _) => ElevatedButton(
                                    onPressed: vm.isLoading
                                        ? null
                                        : () async {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();

                                            if (vm.otpController.text.length !=
                                                6) {
                                              showErrorDialog(
                                                context,
                                                "OTP harus terdiri dari 6 digit angka.",
                                              );
                                              return;
                                            }

                                            final success = await vm
                                                .verifyOtpAction();

                                            if (!context.mounted) return;

                                            if (success) {
                                              showSuccessDialog(
                                                context,
                                                vm.successMessage ??
                                                    'Kode OTP Valid',
                                                () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    AppRoutes.resetPassword,
                                                  );
                                                },
                                              );
                                            } else {
                                              showErrorDialog(
                                                context,
                                                vm.errorMessage ??
                                                    "Verifikasi OTP gagal.",
                                              );
                                            }
                                          },
                                    child: vm.isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Verifikasi'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Consumer<ForgotPasswordViewModel>(
                                builder: (context, vm, _) {
                                  final isRunning = vm.isTimerRunning;

                                  return TextButton(
                                    onPressed: (vm.isLoading || isRunning)
                                        ? null
                                        : () async {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();

                                            final success = await vm
                                                .requestOtp();

                                            if (!context.mounted) return;

                                            if (success) {
                                              showSuccessDialog(
                                                context,
                                                vm.successMessage ??
                                                    "Kode OTP terkirim",
                                                () {},
                                              );
                                            } else if (vm.errorMessage !=
                                                null) {
                                              showErrorDialog(
                                                context,
                                                vm.errorMessage!,
                                              );
                                            }
                                          },
                                    child: Text(
                                      isRunning
                                          ? 'Kirim Ulang dalam ${vm.remainingTime}s'
                                          : 'Tidak terima kode? Kirim Ulang',
                                      style: TextStyle(
                                        color: isRunning
                                            ? Colors.grey
                                            : Colors.blue,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 7),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
