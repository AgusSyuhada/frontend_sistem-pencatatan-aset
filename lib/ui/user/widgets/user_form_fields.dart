import 'package:flutter/material.dart';
import '../../common/custom_dropdown_field.dart';
import '../../../data/models/response/user/role_response.dart';

class UserFormFields extends StatefulWidget {
  final TextEditingController? idController;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController? passwordController;
  final List<Role>? availableRoles;
  final int? selectedRoleId;
  final bool? isActive;
  final String? idInitialValue;
  final bool isIdEditable;
  final bool showPasswordField;
  final bool showStatusField;
  final bool isEditing;
  final Function(int?)? onRoleChanged;
  final Function(bool?)? onStatusChanged;
  final VoidCallback? onFieldChanged;

  const UserFormFields({
    super.key,
    this.availableRoles,
    this.idController,
    required this.nameController,
    required this.emailController,
    this.passwordController,
    this.selectedRoleId,
    this.isActive,
    this.idInitialValue,
    this.isIdEditable = true,
    this.showPasswordField = true,
    this.showStatusField = false,
    this.isEditing = true,
    this.onRoleChanged,
    this.onStatusChanged,
    this.onFieldChanged,
  });

  @override
  State<UserFormFields> createState() => _UserFormFieldsState();
}

class _UserFormFieldsState extends State<UserFormFields> {
  bool _obscurePassword = true;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("ID Karyawan"),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.idController,
          initialValue: widget.idController == null
              ? widget.idInitialValue
              : null,
          enabled: widget.isIdEditable,
          keyboardType: TextInputType.number,
          onChanged: (_) => widget.onFieldChanged?.call(),
          decoration: _inputDecoration(
            hint: "Masukkan ID",
            isEnabled: widget.isIdEditable,
          ),
          validator: (val) {
            if (!widget.isIdEditable) return null;
            if (val == null || val.isEmpty) return "ID Karyawan wajib diisi";
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildLabel("Nama"),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.nameController,
          enabled: widget.isEditing,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => widget.onFieldChanged?.call(),
          decoration: _inputDecoration(
            hint: "Masukkan Nama Lengkap",
            isEnabled: widget.isEditing,
          ),
          validator: (val) => val!.isEmpty ? "Nama wajib diisi" : null,
        ),
        const SizedBox(height: 16),

        _buildLabel("Email"),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.emailController,
          enabled: widget.isEditing,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => widget.onFieldChanged?.call(),
          decoration: _inputDecoration(
            hint: "contoh@email.com",
            isEnabled: widget.isEditing,
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return "Email wajib diisi";
            if (!val.contains('@')) return "Format email tidak valid";
            return null;
          },
        ),
        const SizedBox(height: 16),

        CustomSearchableDropdown<int>(
          label: "Peran",
          hint: "Pilih Peran",
          hideSearch: true,
          controller: TextEditingController(
            text: widget.selectedRoleId == 1
                ? "Admin"
                : (widget.selectedRoleId == 2 ? "User" : ""),
          ),
          readOnly: !widget.isEditing,
          futureRequest: (query) async {
            final roles = [
              {'id': 1, 'name': 'Admin'},
              {'id': 2, 'name': 'User'},
            ];

            if (query.isEmpty) return roles.map((r) => r['id'] as int).toList();

            return roles
                .where(
                  (r) => r['name'].toString().toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .map((r) => r['id'] as int)
                .toList();
          },
          displayItem: (id) => id == 1 ? "Admin" : "User",
          onSelected: (val) {
            widget.onRoleChanged?.call(val);
            widget.onFieldChanged?.call();
          },
        ),

        if (widget.showStatusField) ...[
          const SizedBox(height: 8),
          CustomSearchableDropdown<bool>(
            label: "Status Akun",
            hint: "Pilih Status",
            hideSearch: true,
            controller: TextEditingController(
              text: widget.isActive == true
                  ? "Aktif"
                  : (widget.isActive == false ? "Non-Aktif" : ""),
            ),
            readOnly: !widget.isEditing,
            futureRequest: (query) async {
              return [true, false];
            },
            displayItem: (s) => s ? "Aktif" : "Non-Aktif",
            onSelected: (val) {
              widget.onStatusChanged?.call(val);
              widget.onFieldChanged?.call();
            },
          ),
        ],

        if (widget.showPasswordField && widget.passwordController != null) ...[
          const SizedBox(height: 16),
          _buildLabel(widget.isIdEditable ? "Password" : "Password Baru"),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.passwordController,
            obscureText: _obscurePassword,
            enabled: widget.isEditing,
            onChanged: (_) => widget.onFieldChanged?.call(),
            decoration: _inputDecoration(
              hint: "******",
              helperText: widget.isIdEditable
                  ? "Minimal 6 karakter"
                  : "Kosongkan jika tidak diubah",
              isEnabled: widget.isEditing,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],
      ],
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
}
