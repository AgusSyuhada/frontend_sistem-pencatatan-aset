import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../data/local/preferences/asset_cycle_preferences.dart';
import '../data/local/preferences/session_manager.dart';
import '../data/local/preferences/user_preferences.dart';
import '../ui/asset/cycle/asset_cycle_stats_viewmodel.dart';
import '../data/remote/services/auth_service.dart';
import '../data/remote/services/lookup_service.dart';
import '../data/remote/services/ocr_service.dart';
import '../data/remote/services/user_service.dart';
import '../data/remote/services/upload_service.dart';
import '../data/remote/services/asset_master_service.dart';
import '../data/remote/services/asset_cycle_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/lookup_repository.dart';
import '../data/repositories/ocr_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/upload_repository.dart';
import '../data/repositories/asset_master_repository.dart';
import '../data/repositories/asset_cycle_repository.dart';
import '../ui/asset/cycle/asset_cycle_by_period_viewmodel.dart';
import '../ui/asset/cycle/asset_cycle_detail_viewmodel.dart';
import '../ui/asset/cycle/create_period_viewmodel.dart';
import '../ui/asset/master/asset_master_add_viewmodel.dart';
import '../ui/splash/splash_viewmodel.dart';
import '../ui/terms/terms_viewmodel.dart';
import '../ui/auth/login/login_viewmodel.dart';
import '../ui/auth/forgot_password/forgot_password_viewmodel.dart';
import '../ui/home/home_viewmodel.dart';
import '../ui/profile/profile_viewmodel.dart';
import '../ui/ocr/ocr_viewmodel.dart';
import '../ui/user/user_add_viewmodel.dart';
import '../ui/user/user_detail_edit_viewmodel.dart';
import '../ui/user/user_list_viewmodel.dart';
import '../ui/asset/master/asset_master_list_viewmodel.dart';
import '../ui/asset/cycle/asset_cycle_period_list_viewmodel.dart';
import '../ui/asset/master/asset_master_detail_viewmodel.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
    Provider(create: (_) => SessionManager()),
    Provider(create: (_) => AuthService()),
    Provider(create: (_) => UserService()),
    Provider(create: (_) => OcrService()),
    Provider(create: (_) => UploadService()),
    Provider(create: (_) => AssetMasterService()),
    Provider(create: (_) => AssetCycleService()),
    Provider(create: (_) => LookupService()),
    Provider(create: (_) => UserPreferences()),

    Provider<AssetCyclePreferences>(create: (_) => AssetCyclePreferences()),

    ProxyProvider2<AuthService, SessionManager, AuthRepository>(
      update: (_, authService, sessionManager, __) =>
          AuthRepository(authService, sessionManager),
    ),

    ProxyProvider3<OcrService, SessionManager, AuthRepository, OcrRepository>(
      update: (_, ocrService, sessionManager, authRepository, __) =>
          OcrRepository(ocrService, sessionManager, authRepository),
    ),

    ProxyProvider4<
      UserService,
      SessionManager,
      UserPreferences,
      AuthRepository,
      UserRepository
    >(
      update:
          (
            _,
            userService,
            sessionManager,
            userPreferences,
            authRepository,
            __,
          ) => UserRepository(
            userService,
            sessionManager,
            userPreferences,
            authRepository,
          ),
    ),

    ProxyProvider3<
      UploadService,
      SessionManager,
      AuthRepository,
      UploadRepository
    >(
      update: (_, uploadService, sessionManager, authRepo, __) =>
          UploadRepository(uploadService, sessionManager, authRepo),
    ),

    ProxyProvider3<
      AssetMasterService,
      SessionManager,
      AuthRepository,
      AssetMasterRepository
    >(
      update: (_, service, session, auth, __) =>
          AssetMasterRepository(service, session, auth),
    ),

    ProxyProvider3<
      AssetCycleService,
      SessionManager,
      AuthRepository,
      AssetCycleRepository
    >(
      update: (_, service, session, auth, __) =>
          AssetCycleRepository(service, session, auth),
    ),

    ProxyProvider3<
      LookupService,
      SessionManager,
      AuthRepository,
      LookupRepository
    >(
      update: (_, service, session, auth, __) =>
          LookupRepository(service, session, auth),
    ),

    ChangeNotifierProxyProvider3<
      SessionManager,
      UserRepository,
      AuthRepository,
      SplashViewModel
    >(
      create: (context) => SplashViewModel(
        context.read<SessionManager>(),
        context.read<UserRepository>(),
        context.read<AuthRepository>(),
      ),
      update: (_, sessionManager, userRepository, authRepository, __) =>
          SplashViewModel(sessionManager, userRepository, authRepository),
    ),

    ChangeNotifierProvider(
      create: (context) => TermsViewModel(context.read<SessionManager>()),
    ),

    ChangeNotifierProxyProvider2<
      AuthRepository,
      UserRepository,
      LoginViewModel
    >(
      create: (context) => LoginViewModel(
        context.read<AuthRepository>(),
        context.read<UserRepository>(),
      ),
      update: (_, authRepo, userRepo, prev) =>
          LoginViewModel(authRepo, userRepo),
    ),

    ChangeNotifierProxyProvider<AuthRepository, ForgotPasswordViewModel>(
      create: (context) =>
          ForgotPasswordViewModel(context.read<AuthRepository>()),
      update: (_, repo, prev) => ForgotPasswordViewModel(repo),
    ),

    ChangeNotifierProxyProvider2<AuthRepository, UserRepository, HomeViewModel>(
      create: (context) => HomeViewModel(
        context.read<AuthRepository>(),
        context.read<UserRepository>(),
      ),
      update: (_, authRepository, userRepository, __) =>
          HomeViewModel(authRepository, userRepository),
    ),

    ChangeNotifierProxyProvider3<
      AuthRepository,
      UserRepository,
      UploadRepository,
      ProfileViewModel
    >(
      create: (context) => ProfileViewModel(
        context.read<AuthRepository>(),
        context.read<UserRepository>(),
        context.read<UploadRepository>(),
      ),
      update: (_, authRepo, userRepo, uploadRepo, prev) =>
          ProfileViewModel(authRepo, userRepo, uploadRepo),
    ),

    ChangeNotifierProxyProvider<OcrRepository, OcrViewModel>(
      create: (context) => OcrViewModel(context.read<OcrRepository>()),
      update: (_, repo, prev) => OcrViewModel(repo),
    ),

    ChangeNotifierProxyProvider<UserRepository, UserListViewModel>(
      create: (context) => UserListViewModel(context.read<UserRepository>()),
      update: (_, userRepo, prev) => UserListViewModel(userRepo),
    ),

    ChangeNotifierProxyProvider<UserRepository, UserAddViewModel>(
      create: (context) => UserAddViewModel(context.read<UserRepository>()),
      update: (_, userRepo, prev) => UserAddViewModel(userRepo),
    ),

    ChangeNotifierProxyProvider<UserRepository, UserDetailEditViewModel>(
      create: (context) =>
          UserDetailEditViewModel(context.read<UserRepository>()),
      update: (_, userRepo, prev) => UserDetailEditViewModel(userRepo),
    ),

    ChangeNotifierProxyProvider3<
      AssetMasterRepository,
      LookupRepository,
      UserRepository,
      AssetMasterListViewModel
    >(
      create: (context) => AssetMasterListViewModel(
        context.read<AssetMasterRepository>(),
        context.read<LookupRepository>(),
        context.read<UserRepository>(),
      ),
      update: (_, repo, lookup, user, prev) =>
          AssetMasterListViewModel(repo, lookup, user),
    ),

    ChangeNotifierProxyProvider2<
      AssetCycleRepository,
      SessionManager,
      AssetCyclePeriodListViewModel
    >(
      create: (context) => AssetCyclePeriodListViewModel(
        context.read<AssetCycleRepository>(),
        context.read<SessionManager>(),
      ),
      update: (_, repo, session, prev) =>
          AssetCyclePeriodListViewModel(repo, session),
    ),

    ChangeNotifierProxyProvider3<
      AssetMasterRepository,
      UserRepository,
      LookupRepository,
      AssetMasterDetailViewModel
    >(
      create: (context) => AssetMasterDetailViewModel(
        context.read<AssetMasterRepository>(),
        context.read<UserRepository>(),
        context.read<LookupRepository>(),
      ),
      update: (_, repo, user, lookup, prev) =>
          AssetMasterDetailViewModel(repo, user, lookup),
    ),

    ChangeNotifierProxyProvider3<
      AssetCycleRepository,
      UserRepository,
      LookupRepository,
      AssetCycleDetailViewModel
    >(
      create: (context) => AssetCycleDetailViewModel(
        context.read<AssetCycleRepository>(),
        context.read<UserRepository>(),
        context.read<LookupRepository>(),
      ),
      update: (_, repo, user, lookup, prev) =>
          AssetCycleDetailViewModel(repo, user, lookup),
    ),

    ChangeNotifierProxyProvider2<
      AssetCycleRepository,
      UserRepository,
      AssetCycleStatsViewModel
    >(
      create: (context) => AssetCycleStatsViewModel(
        context.read<AssetCycleRepository>(),
        context.read<UserRepository>(),
      ),
      update: (_, repo, user, prev) => AssetCycleStatsViewModel(repo, user),
    ),

    ChangeNotifierProxyProvider3<
      AssetMasterRepository,
      LookupRepository,
      UserRepository,
      AssetMasterAddViewModel
    >(
      create: (context) => AssetMasterAddViewModel(
        context.read<AssetMasterRepository>(),
        context.read<LookupRepository>(),
        context.read<UserRepository>(),
      ),
      update: (_, assetRepo, lookupRepo, userRepo, prev) =>
          AssetMasterAddViewModel(assetRepo, lookupRepo, userRepo),
    ),

    ChangeNotifierProvider(
      create: (context) => AssetCycleByPeriodViewModel(
        context.read<AssetCycleRepository>(),
        context.read<UserRepository>(),
      ),
    ),

    ChangeNotifierProxyProvider2<
      AssetCycleRepository,
      AssetMasterRepository,
      CreatePeriodViewModel
    >(
      create: (context) => CreatePeriodViewModel(
        context.read<AssetCycleRepository>(),
        context.read<AssetMasterRepository>(),
      ),
      update: (_, cycleRepo, assetRepo, prev) =>
          CreatePeriodViewModel(cycleRepo, assetRepo),
    ),
  ];
}
