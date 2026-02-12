import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistem_pencatatan_aset/ui/asset/cycle/asset_cycle_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_theme.dart';
import 'config/app_routes.dart';
import 'ui/asset/cycle/asset_cycle_stats_screen.dart';
import 'data/models/response/asset_cycle/period_model.dart';
import 'di/app_providers.dart';
import 'data/models/response/user/user.dart';
import 'ui/asset/cycle/asset_cycle_by_period_screen.dart';
import 'ui/asset/cycle/create_period_screen.dart';
import 'ui/asset/master/asset_master_add_screen.dart';
import 'ui/splash/splash_screen.dart';
import 'ui/terms/terms_screen.dart';
import 'ui/auth/login/login_screen.dart';
import 'ui/auth/forgot_password/forgot_password_screen.dart';
import 'ui/auth/forgot_password/otp_verification_screen.dart';
import 'ui/auth/forgot_password/reset_password_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/profile/profile_screen.dart';
import 'ui/profile/change_password_screen.dart';
import 'ui/ocr/camera_ocr_screen.dart';
import 'ui/user/user_list_screen.dart';
import 'ui/user/add_user_screen.dart';
import 'ui/user/user_detail_edit_screen.dart';
import 'ui/asset/master/asset_master_list_screen.dart';
import 'ui/asset/cycle/asset_cycle_period_list_screen.dart';
import 'ui/asset/master/asset_master_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: MaterialApp(
        title: 'Asset Cycle',
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        debugShowCheckedModeBanner: false,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.terms: (context) => const TermsScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
          AppRoutes.changePassword: (context) => const ChangePasswordScreen(),
          AppRoutes.scanCamera: (context) => const CameraOcrScreen(),
          AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
          AppRoutes.otpVerification: (context) => const OtpVerificationScreen(),
          AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),
          AppRoutes.userList: (context) => const UserListScreen(),
          AppRoutes.userAdd: (context) => const AddUserScreen(),

          AppRoutes.userDetail: (context) {
            final user = ModalRoute.of(context)!.settings.arguments as User;
            return UserDetailEditScreen(user: user);
          },

          AppRoutes.assetList: (context) => const AssetMasterListScreen(),
          AppRoutes.cycleList: (context) => const AssetCycleListScreen(),
          AppRoutes.createPeriod: (context) => const CreatePeriodScreen(),
          AppRoutes.cycleCheck: (context) {
            final period =
                ModalRoute.of(context)!.settings.arguments as PeriodModel;
            return AssetCycleByPeriodScreen(period: period);
          },
          AppRoutes.assetDetail: (context) => const AssetMasterDetailScreen(),
          AppRoutes.assetForm: (context) => const AssetMasterAddScreen(),
          AppRoutes.assetCycleDetail: (context) =>
              const AssetCycleDetailScreen(),
          AppRoutes.cycleStats: (context) {
            final period =
                ModalRoute.of(context)!.settings.arguments as PeriodModel;
            return AssetCycleStatsScreen(period: period);
          },
        },
      ),
    );
  }
}
