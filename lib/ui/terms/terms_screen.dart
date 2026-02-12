import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../common/app_dialogs.dart';
import 'terms_viewmodel.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  late final TermsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<TermsViewModel>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initialize();
    });

    _viewModel.addListener(_onViewModelUpdate);
  }

  void _onViewModelUpdate() {
    if (!mounted) return;

    if (_viewModel.errorMessage != null) {
      showErrorDialog(context, _viewModel.errorMessage!);
    }

    if (_viewModel.permissionResult != null) {
      switch (_viewModel.permissionResult!) {
        case PermissionResult.granted:
          showSuccessDialog(
            context,
            'Persetujuan berhasil & Izin Lokasi serta Kamera diberikan!',
            () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          );
          break;
        case PermissionResult.denied:
          showPermissionDialog(
            context,
            'Izin Ditolak',
            _viewModel.permissionMessage,
          );
          break;
        case PermissionResult.permanentlyDenied:
          showPermissionDialog(
            context,
            'Izin Diperlukan',
            _viewModel.permissionMessage,
            onSettingsPressed: () => _viewModel.openSettings(),
          );
          break;
        case PermissionResult.error:
          break;
      }
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TermsViewModel>(
      builder: (context, viewModel, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: SingleChildScrollView(
                    controller: viewModel.scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Syarat dan Ketentuan',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Selamat Datang!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Harap baca syarat dan ketentuan layanan kami dengan saksama sebelum menggunakan aplikasi ini. Dengan menggunakan aplikasi ini, Anda dianggap telah membaca, memahami, dan menyetujui untuk terikat oleh semua syarat dan ketentuan yang tercantum di bawah ini.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '1. Penerimaan Persyaratan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Dengan mengakses atau menggunakan Layanan kami, Anda setuju untuk terikat oleh Syarat ini. Jika Anda tidak setuju dengan bagian mana pun dari persyaratan ini, maka Anda tidak diizinkan untuk mengakses Layanan.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '2. Perubahan Persyaratan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kami berhak, atas kebijakan kami sendiri, untuk mengubah atau mengganti Syarat ini kapan saja. Jika revisi bersifat material, kami akan memberikan pemberitahuan setidaknya 30 hari sebelum persyaratan baru berlaku.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '3. Izin Akses (Lokasi & Kamera)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Aplikasi ini memerlukan akses ke Lokasi (GPS) untuk validasi area kerja, penyimpanan/foto untuk mengunggah foto profil dan bukti pendukung, dan akses Kamera untuk verifikasi foto pekerjaan. Dengan menyetujui syarat ini, Anda mengizinkan aplikasi untuk mengakses fitur tersebut pada perangkat Anda.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '4. Akun Pengguna',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Saat Anda membuat akun dengan kami, Anda harus memberikan informasi yang akurat, lengkap, dan terkini setiap saat. Kegagalan untuk melakukannya merupakan pelanggaran terhadap Persyaratan.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 40),

                        InkWell(
                          onTap: () =>
                              viewModel.setAgreement(!viewModel.isAgreed),

                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Row(
                            children: [
                              Checkbox(
                                value: viewModel.isAgreed,
                                onChanged: (val) => viewModel.setAgreement(val),
                              ),
                              Expanded(
                                child: const Text(
                                  'Saya telah membaca dan menyetujui Syarat & Ketentuan yang berlaku.',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50.0,
                          child: ElevatedButton(
                            onPressed:
                                viewModel.isLoading || !viewModel.isAgreed
                                ? null
                                : viewModel.proceed,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),

                              backgroundColor: viewModel.isAgreed
                                  ? Colors.blue
                                  : Colors.grey[300],
                              foregroundColor: viewModel.isAgreed
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                            child: viewModel.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'LANJUTKAN & IZINKAN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            floatingActionButton: !viewModel.isScrolledToEnd
                ? FloatingActionButton(
                    onPressed: () => viewModel.scrollController.animateTo(
                      viewModel.scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                    ),
                    tooltip: 'Scroll ke Bawah',
                    child: const Icon(Icons.arrow_downward),
                  )
                : null,
          ),
        );
      },
    );
  }
}
