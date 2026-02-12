import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../../../ui/common/app_dialogs.dart';
import 'forgot_password_viewmodel.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<ForgotPasswordViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lupa Password',
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
                                'Atur Ulang Password',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Masukkan email Anda. Kami akan mengirimkan kode OTP untuk mereset password.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 32),
                              Consumer<ForgotPasswordViewModel>(
                                builder: (context, vm, _) => TextField(
                                  controller: vm.emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !vm.isLoading,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Consumer<ForgotPasswordViewModel>(
                                builder: (context, vm, _) => SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: vm.isLoading
                                        ? null
                                        : () async {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();

                                            final success = await vm
                                                .requestOtp();
                                            if (success && context.mounted) {
                                              showSuccessDialog(
                                                context,
                                                vm.successMessage ??
                                                    'Kode OTP Terkirim', 
                                                () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    AppRoutes.otpVerification,
                                                  );
                                                },
                                              );
                                            } else if (vm.errorMessage !=
                                                    null &&
                                                context.mounted) {
                                              showErrorDialog(
                                                context,
                                                vm.errorMessage!,
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
                                        : const Text('Kirim Kode'),
                                  ),
                                ),
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
