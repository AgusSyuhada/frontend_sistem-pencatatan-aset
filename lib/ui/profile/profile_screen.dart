import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../common/app_dialogs.dart';
import '../../../utils/helpers/permission_helper.dart';
import './profile_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _viewModel;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final PermissionHelper _permissionHelper = PermissionHelper();

  bool _isEditingName = false;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<ProfileViewModel>(context, listen: false);
    _viewModel.addListener(_onViewModelChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initialize();

      _syncControllers();
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _idController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    _syncControllers();
  }

  void _syncControllers() {
    final user = _viewModel.user?.user;
    if (user != null) {
      if (!_isEditingName && _nameController.text != user.name) {
        _nameController.text = user.name;
      }
      _idController.text = user.userId.toString();
      _emailController.text = user.email;
      _roleController.text = user.roleId == 1 ? "Admin" : "User";

      if (mounted) setState(() {});
    }
  }

  void _handleProfilePictureTap() {
    if (Platform.isWindows) {
      _pickImage(ImageSource.gallery);
      return;
    }
    _showImageSourceDialog();
  }

  void _showImageSourceDialog() {
    showSelectionActionDialog(
      context: context,
      title: "Ganti Foto Profil",
      actions: [
        DialogActionItem(
          label: "Kamera",
          icon: Icons.camera_alt,
          color: Colors.blue,
          id: 'camera',
        ),
        DialogActionItem(
          label: "Galeri",
          icon: Icons.photo_library,
          color: Colors.orange,
          id: 'gallery',
        ),
      ],
      onSelected: (actionId) async {
        if (actionId == 'camera') {
          final hasPermission = await _permissionHelper
              .requestCameraPermission();
          if (mounted && hasPermission) _pickImage(ImageSource.camera);
        } else if (actionId == 'gallery') {
          final hasPermission = await _permissionHelper
              .requestStoragePermission();
          if (mounted && hasPermission) _pickImage(ImageSource.gallery);
        }
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) _handleUpload(File(pickedFile.path));
    } catch (e) {
      if (mounted) showErrorDialog(context, "Gagal mengambil gambar.");
    }
  }

  Future<void> _handleUpload(File file) async {
    showLoadingDialog(context);
    await _viewModel.updateProfilePicture(file);
    if (!mounted) return;
    Navigator.pop(context);
    if (_viewModel.state == ProfileState.success) {
      showSuccessDialog(
        context,
        _viewModel.successMessage ?? "Foto profil berhasil diperbarui.",
        () {},
      );
    } else if (_viewModel.state == ProfileState.error) {
      showErrorDialog(
        context,
        _viewModel.errorMessage ?? "Gagal mengupload foto.",
      );
    }
  }

  void _toggleEditName() async {
    if (_isEditingName) {
      if (_nameController.text.trim().length < 3) return;
      showLoadingDialog(context);
      final serverMessage = await _viewModel.updateName(_nameController.text);
      if (mounted) {
        Navigator.pop(context);
        if (serverMessage != null) {
          setState(() => _isEditingName = false);
          showSuccessDialog(context, serverMessage, () {});
        } else {
          showErrorDialog(
            context,
            _viewModel.errorMessage ?? "Gagal menyimpan perubahan.",
          );
        }
      }
    } else {
      setState(() => _isEditingName = true);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => FocusScope.of(context).requestFocus(_nameFocusNode),
      );
    }
  }

  bool _isValidUrl(String? url) =>
      url != null && url.isNotEmpty && url.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Pengguna',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          final user = viewModel.user?.user;
          if (viewModel.state == ProfileState.loading && user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.initialize(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.grey.shade200,
                              child: ClipOval(
                                child: _isValidUrl(user?.profilePictureUrl)
                                    ? Image.network(
                                        user!.profilePictureUrl!,
                                        width: 140,
                                        height: 140,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.person,
                                                  size: 70,
                                                  color: Colors.grey,
                                                ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _handleProfilePictureTap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildLabel("ID Karyawan"),
                      const SizedBox(height: 6),
                      _buildReadOnlyField(controller: _idController),

                      const SizedBox(height: 12),

                      _buildLabel("Nama"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        readOnly: !_isEditingName,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isEditingName ? Icons.save : Icons.edit,
                              color: _isEditingName ? Colors.blue : Colors.grey,
                              size: 20,
                            ),
                            onPressed: _toggleEditName,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _isEditingName
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: _isEditingName
                              ? Colors.white
                              : Colors.grey.shade100,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildLabel("Email"),
                      const SizedBox(height: 6),
                      _buildReadOnlyField(controller: _emailController),

                      const SizedBox(height: 12),

                      _buildLabel("Jabatan"),
                      const SizedBox(height: 6),
                      _buildReadOnlyField(controller: _roleController),

                      const SizedBox(height: 12),

                      _buildLabel("Keamanan"),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.changePassword,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Ganti Password",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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

  Widget _buildReadOnlyField({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      enabled: false,
      style: const TextStyle(color: Colors.black54, fontSize: 15),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
