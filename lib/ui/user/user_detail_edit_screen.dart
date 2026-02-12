import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/response/user/user.dart';
import '../../data/models/request/user/user_admin_update_request.dart';
import 'user_detail_edit_viewmodel.dart';
import '../common/app_dialogs.dart';
import 'widgets/user_form_fields.dart';

class UserDetailEditScreen extends StatefulWidget {
  final User user;
  final bool startEditing;

  const UserDetailEditScreen({
    super.key,
    required this.user,
    this.startEditing = false,
  });

  @override
  State<UserDetailEditScreen> createState() => _UserDetailEditScreenState();
}

class _UserDetailEditScreenState extends State<UserDetailEditScreen> {
  late bool _isEditing;
  late bool _hasChanges;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _newPasswordController;

  int? _selectedRoleId;
  late bool _isActive;
  bool _editPassword = false;
  bool _obscurePassword = true;
  bool _userHasInteracted = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startEditing;
    _hasChanges = false;
    _newPasswordController = TextEditingController();
    _initializeControllers(widget.user);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<UserDetailEditViewModel>();
      vm.initialize(widget.user);
      vm.loadUserDetail(widget.user.userId);
    });
  }

  void _initializeControllers(User data) {
    _nameController = TextEditingController(text: data.name);
    _emailController = TextEditingController(text: data.email);
    _selectedRoleId = data.roleId;
    _isActive = data.isActive;
    _editPassword = false;
    _obscurePassword = true;
    _newPasswordController.clear();
    _nameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
  }

  void _updateFormDataIfNeeded(User newData) {
    if (!_hasChanges && !_userHasInteracted) {
      if (_nameController.text != newData.name) {
        _nameController.text = newData.name;
      }
      if (_emailController.text != newData.email) {
        _emailController.text = newData.email;
      }
      if (_selectedRoleId != newData.roleId) {
        setState(() => _selectedRoleId = newData.roleId);
      }
      if (_isActive != newData.isActive) {
        setState(() => _isActive = newData.isActive);
      }
    }
  }

  void _checkForChanges() {
    _userHasInteracted = true;

    final currentUser =
        context.read<UserDetailEditViewModel>().currentUser ?? widget.user;

    bool hasChanged =
        _nameController.text != currentUser.name ||
        _emailController.text != currentUser.email ||
        _selectedRoleId != currentUser.roleId ||
        _isActive != currentUser.isActive ||
        (_editPassword && _newPasswordController.text.isNotEmpty);

    if (_hasChanges != hasChanged) {
      setState(() {
        _hasChanges = hasChanged;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing && _hasChanges) {
      showConfirmationDialog(
        context,
        "Batalkan Perubahan?",
        "Perubahan yang Anda buat akan hilang.",
        () {
          if (widget.startEditing) {
            Navigator.pop(context);
          } else {
            setState(() {
              _isEditing = false;
              _hasChanges = false;
              _userHasInteracted = false;
              final validData =
                  context.read<UserDetailEditViewModel>().currentUser ??
                  widget.user;
              _nameController.text = validData.name;
              _emailController.text = validData.email;
              _selectedRoleId = validData.roleId;
              _isActive = validData.isActive;
              _newPasswordController.clear();
              _editPassword = false;
              _obscurePassword = true;
            });
          }
        },
      );
    } else {
      setState(() {
        _isEditing = !_isEditing;
        if (!_isEditing) {
          _userHasInteracted = false;
        }
      });
    }
  }

  InputDecoration _inputDecoration({
    String? hint,
    String? helperText,
    bool isEnabled = true,
    Widget? suffixIcon,
  }) {
    final OutlineInputBorder commonBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return InputDecoration(
      suffixIcon: suffixIcon,
      hintText: hint,
      helperText: helperText,
      filled: true,
      fillColor: isEnabled ? Colors.white : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: commonBorder,
      enabledBorder: commonBorder,
      focusedBorder: commonBorder.copyWith(
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      disabledBorder: commonBorder,
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges || (_isEditing && _hasChanges)) {
      bool confirm = false;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Simpan Perubahan?"),
          content: const Text(
            "Anda memiliki perubahan yang belum disimpan. Keluar sekarang?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                confirm = true;
                Navigator.pop(ctx);
              },
              child: const Text("Ya, Keluar"),
            ),
          ],
        ),
      );
      return confirm;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<UserDetailEditViewModel>(
            builder: (context, vm, child) {
              final displayName = vm.currentUser?.name ?? widget.user.name;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detail Pengguna",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
          centerTitle: false,
          actions: [
            Consumer<UserDetailEditViewModel>(
              builder: (context, vm, _) {
                if (vm.state == UserDetailEditState.loading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Consumer<UserDetailEditViewModel>(
                builder: (context, vm, _) {
                  if (vm.currentUser != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _updateFormDataIfNeeded(vm.currentUser!);
                    });
                  }

                  if (vm.state == UserDetailEditState.error &&
                      vm.currentUser == null) {
                    return Center(child: Text("Error: ${vm.errorMessage}"));
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          UserFormFields(
                            idInitialValue: widget.user.userId.toString(),
                            nameController: _nameController,
                            emailController: _emailController,
                            passwordController: _newPasswordController,
                            selectedRoleId: _selectedRoleId,
                            availableRoles: vm.availableRoles,
                            isActive: _isActive,
                            isIdEditable: false,
                            isEditing: _isEditing,
                            showStatusField: false,
                            showPasswordField: false,
                            onRoleChanged: (val) => setState(() {
                              _selectedRoleId = val;
                              _checkForChanges();
                            }),
                            onStatusChanged: (val) => setState(() {
                              if (val != null) _isActive = val;
                              _checkForChanges();
                            }),
                            onFieldChanged: _checkForChanges,
                          ),

                          if (_isEditing) ...[
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade300),
                            const SizedBox(height: 16),

                            InkWell(
                              onTap: () {
                                setState(() {
                                  _editPassword = !_editPassword;
                                  if (!_editPassword) {
                                    _newPasswordController.clear();
                                  }
                                  _checkForChanges();
                                });
                              },
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _editPassword,
                                      activeColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _editPassword = val ?? false;
                                          if (!_editPassword) {
                                            _newPasswordController.clear();
                                          }
                                          _checkForChanges();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Ubah Password Pengguna",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (_editPassword) ...[
                              const SizedBox(height: 16),
                              _buildLabel("Password Baru"),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: _obscurePassword,
                                enabled: true,
                                onChanged: (_) => _checkForChanges(),
                                decoration: _inputDecoration(
                                  hint: "******",
                                  helperText: "Minimal 6 karakter",
                                  isEnabled: true,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val != null &&
                                      val.isNotEmpty &&
                                      val.length < 6) {
                                    return "Password minimal 6 karakter";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],

                          const SizedBox(height: 32),
                          _buildActionButtons(vm),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildActionButtons(UserDetailEditViewModel vm) {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: vm.state == UserDetailEditState.loading
                  ? null
                  : _toggleEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Batal",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  (_hasChanges && vm.state != UserDetailEditState.loading)
                  ? _saveChanges
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: vm.state == UserDetailEditState.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Simpan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
              label: const Text("Edit Data User"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          if (_isActive) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _deactivateUser(vm),
                icon: const Icon(Icons.block, color: Colors.red, size: 18),
                label: const Text("Nonaktifkan Akun"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }
  }

  Future<void> _deactivateUser(UserDetailEditViewModel vm) async {
    showConfirmationDialog(
      context,
      "Nonaktifkan Akun?",
      "Akun ini tidak akan bisa digunakan lagi. Apakah Anda yakin?",
      () async {
        showLoadingDialog(context);

        final request = UserAdminUpdateRequest(
          name: _nameController.text,
          email: _emailController.text,
          roleId: _selectedRoleId,
          isActive: false,
        );

        final message = await vm.updateUser(widget.user.userId, request);

        if (!mounted) return;
        Navigator.pop(context);

        if (message != null) {
          showSuccessDialog(context, "Akun berhasil dinonaktifkan.", () {
            setState(() {
              _isActive = false;
              _checkForChanges();
            });
          });
        } else {
          showErrorDialog(
            context,
            vm.errorMessage ?? "Gagal menonaktifkan akun.",
          );
        }
      },
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final vm = context.read<UserDetailEditViewModel>();
    bool updateSuccess = true;
    String finalMessage = "";

    final request = UserAdminUpdateRequest(
      name: _nameController.text,
      email: _emailController.text,
      roleId: _selectedRoleId,
      isActive: _isActive,
    );

    final profileMsg = await vm.updateUser(widget.user.userId, request);

    if (profileMsg != null) {
      finalMessage = profileMsg;
    } else {
      updateSuccess = false;
      finalMessage = vm.errorMessage ?? "Gagal update profil";
    }

    if (updateSuccess &&
        _editPassword &&
        _newPasswordController.text.isNotEmpty) {
      final passMsg = await vm.resetUserPassword(
        widget.user.userId,
        _newPasswordController.text,
      );

      if (passMsg != null) {
        finalMessage += "\n\n$passMsg";
      } else {
        updateSuccess = false;
        finalMessage =
            "Profil tersimpan, tapi password gagal direset: ${vm.errorMessage}";
      }
    }

    if (mounted) {
      if (updateSuccess) {
        showSuccessDialog(context, finalMessage, () {
          if (widget.startEditing) {
            Navigator.pop(context, true);
          } else {
            setState(() {
              _isEditing = false;
              _hasChanges = false;
              _editPassword = false;
              _newPasswordController.clear();
              _userHasInteracted = false;
            });
          }
        });
      } else {
        showErrorDialog(context, finalMessage);
      }
    }
  }
}
