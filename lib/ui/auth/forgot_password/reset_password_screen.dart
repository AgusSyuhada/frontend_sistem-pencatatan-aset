import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../../../ui/common/app_dialogs.dart';
import 'forgot_password_viewmodel.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buat Password Baru',
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
                                'Password Baru',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Consumer<ForgotPasswordViewModel>(
                                builder: (context, vm, _) => Column(
                                  children: [
                                    TextField(
                                      controller: vm.newPasswordController,
                                      obscureText: _obscurePass,
                                      decoration: InputDecoration(
                                        labelText: 'Password Baru',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePass
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePass = !_obscurePass,
                                          ),
                                        ),
                                      ),
                                      enabled: !vm.isLoading,
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: vm.confirmPasswordController,
                                      obscureText: _obscureConfirm,
                                      decoration: InputDecoration(
                                        labelText: 'Konfirmasi Password Baru',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirm
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscureConfirm =
                                                !_obscureConfirm,
                                          ),
                                        ),
                                      ),
                                      enabled: !vm.isLoading,
                                    ),
                                  ],
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
                                            final success = await vm
                                                .submitResetPassword();
                                            if (success && context.mounted) {
                                              showSuccessDialog(
                                                context,
                                                vm.successMessage ??
                                                    'Password Berhasil Direset',
                                                () {
                                                  vm.clearState();
                                                  Navigator.pushNamedAndRemoveUntil(
                                                    context,
                                                    AppRoutes.login,
                                                    (route) => false,
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
                                            ),
                                          )
                                        : const Text('Simpan Password'),
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
