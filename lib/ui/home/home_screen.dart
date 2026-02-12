import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../common/app_dialogs.dart';
import 'home_viewmodel.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().init();
    });
  }

  Map<String, String> _getGreetingData() {
    var hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return {'text': 'Selamat Pagi', 'emoji': '☀️'};
    }
    if (hour >= 11 && hour < 15) {
      return {'text': 'Selamat Siang', 'emoji': '🌤️'};
    }
    if (hour >= 15 && hour < 18) {
      return {'text': 'Selamat Sore', 'emoji': '🌇'};
    }
    return {'text': 'Selamat Malam', 'emoji': '🌙'};
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.user == null && !viewModel.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.init();
          });
        }

        final userName = viewModel.user?.user.name ?? "Pengguna";
        final greetingData = _getGreetingData();
        final fullGreeting =
            "${greetingData['text']}, $userName ${greetingData['emoji']}";

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.blue,
              elevation: 0,
              toolbarHeight: 60,
              automaticallyImplyLeading: false,
              centerTitle: false,
              titleSpacing: 20,
              title: Text(
                fullGreeting,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Consumer<HomeViewModel>(
                    builder: (context, viewModel, child) {
                      final user = viewModel.user?.user;
                      final photoUrl = user?.profilePictureUrl;

                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.profile);
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          radius: 20,
                          child: ClipOval(
                            child: (photoUrl != null && photoUrl.isNotEmpty)
                                ? Image.network(
                                    photoUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                  )
                                : const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),

                          _bigMenuButton(
                            icon: Icons.check_circle_outline,
                            label: 'Pengecekan',
                            onTap: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                AppRoutes.scanCamera,
                              );

                              if (result == "TIMEOUT_BY_SYSTEM" && context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Info"),
                                    content: const Text(
                                      "Kamera ditutup karena tidak ada aktivitas.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),

                          _bigMenuButton(
                            icon: Icons.list_alt,
                            label: 'Daftar Cycle',
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.cycleList);
                            },
                            color: Colors.green,
                          ),

                          const SizedBox(height: 16),
                          _bigMenuButton(
                            icon: Icons.line_style_outlined,
                            label: 'Master Data',
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.assetList);
                            },
                            color: Colors.orange,
                          ),

                          if (viewModel.isAdmin) ...[
                            const SizedBox(height: 16),
                            _bigMenuButton(
                              icon: Icons.groups_outlined,
                              label: 'Pengguna',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.userList,
                                );
                              },
                              color: Colors.deepPurple,
                            ),
                          ],
                          const SizedBox(height: 16),

                          _bigMenuButton(
                            icon: Icons.logout,
                            label: 'Logout',
                            onTap: _handleLogout,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bigMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return SizedBox(
      height: 120,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 90, color: Colors.white.withValues(alpha: 0.18)),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    showConfirmationDialog(
      context,
      'Konfirmasi Logout',
      'Apakah Anda yakin ingin keluar?',
      () async {
        showLoadingDialog(context);

        try {
          final response = await context.read<HomeViewModel>().logout();

          if (!mounted) return;

          Navigator.of(context).pop();

          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
            arguments: response.message,
          );
        } catch (e) {
          if (!mounted) return;

          Navigator.of(context).pop();

          showErrorDialog(
            context,
            "Logout Gagal: ${e.toString().replaceAll('Exception: ', '')}",
          );
        }
      },
    );
  }
}
