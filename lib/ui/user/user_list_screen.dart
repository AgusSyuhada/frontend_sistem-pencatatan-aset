import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../common/app_dialogs.dart';
import '../common/generic_data_table.dart';
import 'user_list_viewmodel.dart';
import '../../data/models/response/user/user.dart';
import 'user_detail_edit_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late UserListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserListViewModel>().initialize();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<UserListViewModel>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();

    _viewModel.resetState();

    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (currentScroll >= (maxScroll - 200)) {
        _viewModel.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daftar Pengguna Aktif",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.userAdd);

          if (result == true && mounted) {
            _viewModel.refreshManual();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Cari ID, Nama, atau Email...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _viewModel.search("");
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (val) => _viewModel.search(val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Consumer<UserListViewModel>(
                    builder: (context, vm, _) {
                      bool isFilterActive = vm.selectedRoles.length < 2;
                      return SizedBox(
                        height: 48,
                        width: 48,
                        child: InkWell(
                          onTap: () => _showFilterDialog(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isFilterActive
                                  ? Colors.orange.shade50
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFilterActive
                                    ? Colors.orange.shade200
                                    : Colors.blue.shade100,
                              ),
                            ),
                            child: Icon(
                              Icons.filter_list,
                              color: isFilterActive
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Consumer<UserListViewModel>(
                builder: (ctx, vm, _) {
                  if (vm.selectedRoles.length < 2) {
                    List<String> filters = [];
                    if (!vm.selectedRoles.contains(1)) {
                      filters.add("Hanya User");
                    }
                    if (!vm.selectedRoles.contains(2)) {
                      filters.add("Hanya Admin");
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Filter: ${filters.join(", ")}",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              Expanded(
                child: Consumer<UserListViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.state == UserListState.error &&
                        viewModel.users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 8),
                            Text(viewModel.errorMessage ?? "Gagal memuat data"),
                            TextButton(
                              onPressed: () => viewModel.refreshManual(),
                              child: const Text("Coba Lagi"),
                            ),
                          ],
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        GenericDataTable<User>(
                          scrollController: _scrollController,
                          isLoading: viewModel.state == UserListState.loading,
                          data: viewModel.users,
                          minWidth: isMobile ? 800 : 1000,
                          onRefresh: () async {
                            await viewModel.refreshManual();
                          },

                          onRowTap: (user) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserDetailEditScreen(
                                  user: user,
                                  startEditing: false,
                                ),
                              ),
                            );
                          },
                          headers: [
                            DataHeader(
                              text: "No",
                              width: 50,
                              textAlign: TextAlign.center,
                            ),
                            DataHeader(
                              text: "ID",
                              width: 100,
                              textAlign: TextAlign.left,
                              onSort: () => viewModel.sort('id'),
                              isAscending: viewModel.sortColumn == 'id'
                                  ? viewModel.isAscending
                                  : null,
                            ),
                            DataHeader(
                              text: "Nama Lengkap",
                              flex: 2,
                              textAlign: TextAlign.left,
                              onSort: () => viewModel.sort('name'),
                              isAscending: viewModel.sortColumn == 'name'
                                  ? viewModel.isAscending
                                  : null,
                            ),
                            DataHeader(
                              text: "Email",
                              flex: 2,
                              textAlign: TextAlign.left,
                            ),
                            DataHeader(
                              text: "Peran",
                              width: 80,
                              textAlign: TextAlign.left,
                            ),
                            DataHeader(
                              text: "Aksi",
                              width: 60,
                              textAlign: TextAlign.center,
                            ),
                          ],
                          rowBuilder: (context, index, user) {
                            return Row(
                              children: [
                                DataCellWidget(
                                  text: "${index + 1}",
                                  width: 50,
                                  textAlign: TextAlign.center,
                                ),
                                DataCellWidget(
                                  text: user.userId.toString(),
                                  width: 100,
                                  textAlign: TextAlign.left,
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                DataCellWidget(
                                  text: user.email,
                                  flex: 2,
                                  color: Colors.grey.shade600,
                                  textAlign: TextAlign.left,
                                ),
                                DataCellWidget(
                                  text: user.roleName ?? "N/A",
                                  width: 80,
                                  color: Colors.grey.shade600,
                                  textAlign: TextAlign.left,
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Center(
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.grey,
                                      ),

                                      onPressed: () =>
                                          _showActions(context, user),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (viewModel.isLoadingMore)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.9),
                              padding: const EdgeInsets.all(8.0),
                              child: const Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    FocusScope.of(context).unfocus();

    Set<int> tempRoles = Set.from(_viewModel.selectedRoles);

    showGenericFilterDialog(
      context: context,
      title: "Filter Role User",
      onReset: () => _viewModel.resetFilters(),
      onApply: () => _viewModel.applyFilters(roles: tempRoles),
      content: StatefulBuilder(
        builder: (context, setStateContent) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Pilih Role",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _viewModel.availableRoles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3,
                ),
                itemBuilder: (ctx, index) {
                  final role = _viewModel.availableRoles[index];
                  return _buildFilterToggleButton(
                    label: role.roleName,
                    isSelected: tempRoles.contains(role.roleId),
                    onTap: () {
                      setStateContent(() {
                        if (tempRoles.contains(role.roleId)) {
                          if (tempRoles.length > 1) {
                            tempRoles.remove(role.roleId);
                          }
                        } else {
                          tempRoles.add(role.roleId);
                        }
                      });
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.blue.shade900
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context, User user) {
    FocusScope.of(context).unfocus();

    showSelectionActionDialog(
      context: context,
      title: "Aksi: ${user.name}",
      actions: [
        DialogActionItem(
          label: "Lihat Detail",
          icon: Icons.assignment_ind,
          color: Colors.blue,
          id: 'view_detail',
        ),
        DialogActionItem(
          label: "Edit Data",
          icon: Icons.edit,
          color: Colors.orange,
          id: 'edit_direct',
        ),
        DialogActionItem(
          label: "Nonaktifkan (Hapus)",
          icon: Icons.delete_outline,
          color: Colors.red,
          id: 'deactivate_user',
        ),
      ],
      onSelected: (actionId) async {
        if (actionId == 'view_detail') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  UserDetailEditScreen(user: user, startEditing: false),
            ),
          );
        } else if (actionId == 'edit_direct') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  UserDetailEditScreen(user: user, startEditing: true),
            ),
          );
        } else if (actionId == 'deactivate_user') {
          _confirmDeactivation(context, user);
        }
      },
    );
  }

  void _confirmDeactivation(BuildContext context, User user) {
    showConfirmationDialog(
      context,
      "Hapus Akses Pengguna?",
      "Data pengguna ${user.name} akan hilang dari daftar dan tidak dapat diakses kembali melalui aplikasi. Lanjutkan?",
      () async {
        showLoadingDialog(context);

        final successMessage = await _viewModel.deactivateUser(user.userId);

        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (context.mounted) {
          if (successMessage != null) {
            showSuccessDialog(
              context,
              "Pengguna berhasil dinonaktifkan dan dihapus dari daftar.",
              () {},
            );
          } else {
            showErrorDialog(
              context,
              _viewModel.errorMessage ?? "Gagal menonaktifkan pengguna.",
            );
          }
        }
      },
    );
  }
}
