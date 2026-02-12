import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/app_dialogs.dart';
import 'profile_viewmodel.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProfileViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ganti Password',
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Amankan Akun Anda',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pastikan password baru Anda kuat dan belum pernah digunakan sebelumnya.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _currentPassController,
                                  obscureText: _obscureCurrent,
                                  decoration: InputDecoration(
                                    labelText: 'Password Saat Ini',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureCurrent
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () => setState(
                                        () =>
                                            _obscureCurrent = !_obscureCurrent,
                                      ),
                                    ),
                                  ),
                                  validator: (val) =>
                                      val!.isEmpty ? 'Wajib diisi' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _newPassController,
                                  obscureText: _obscureNew,
                                  decoration: InputDecoration(
                                    labelText: 'Password Baru',
                                    prefixIcon: const Icon(
                                      Icons.vpn_key_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNew
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureNew = !_obscureNew,
                                      ),
                                    ),
                                  ),
                                  validator: (val) =>
                                      (val == null || val.length < 6)
                                      ? 'Minimal 6 karakter'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPassController,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    labelText: 'Ulangi Password Baru',
                                    prefixIcon: const Icon(
                                      Icons.vpn_key_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                    ),
                                  ),
                                  validator: (val) =>
                                      (val != _newPassController.text)
                                      ? 'Password tidak sama'
                                      : null,
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        FocusScope.of(context).unfocus();
                                        showLoadingDialog(context);

                                        final serverMessage = await viewModel
                                            .changePassword(
                                              _currentPassController.text,
                                              _newPassController.text,
                                            );

                                        if (context.mounted) {
                                          Navigator.pop(context);

                                          if (serverMessage != null) {
                                            showSuccessDialog(
                                              context,
                                              serverMessage,
                                              () {
                                                Navigator.pop(context);
                                              },
                                            );
                                          } else {
                                            showErrorDialog(
                                              context,
                                              viewModel.errorMessage ??
                                                  'Gagal mengganti password',
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: const Text('Simpan Password Baru'),
                                  ),
                                ),
                              ],
                            ),
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
