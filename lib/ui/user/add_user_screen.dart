import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/request/user/user_create_request.dart';
import 'user_add_viewmodel.dart';
import '../common/app_dialogs.dart';
import 'widgets/user_form_fields.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  int _roleId = 2;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserAddViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tambah Pengguna Baru",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Isi Informasi Pengguna",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Consumer<UserAddViewModel>(
                      builder: (context, vm, child) {
                        return UserFormFields(
                          idController: _idController,
                          nameController: _nameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          selectedRoleId: _roleId,

                          availableRoles: vm.availableRoles,
                          isIdEditable: true,
                          showPasswordField: true,
                          showStatusField: false,
                          isEditing: true,
                          onRoleChanged: (val) {
                            if (val != null) setState(() => _roleId = val);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: Consumer<UserAddViewModel>(
                        builder: (context, addVm, _) {
                          return ElevatedButton(
                            onPressed: addVm.state == UserAddState.loading
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: addVm.state == UserAddState.loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Simpan Pengguna",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final vm = context.read<UserAddViewModel>();

      final req = UserCreateRequest(
        userId: int.parse(_idController.text),
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        roleId: _roleId,
      );

      final successMessage = await vm.addUser(req);

      if (mounted) {
        if (successMessage != null) {
          showSuccessDialog(context, successMessage, () {
            Navigator.pop(context, true);
          });
        } else {
          showErrorDialog(
            context,
            vm.errorMessage ?? "Gagal menambahkan user.",
          );
        }
      }
    }
  }
}