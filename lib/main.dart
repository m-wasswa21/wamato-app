import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth/auth_cubit.dart';
import 'bloc/property/property_cubit.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_repository.dart';
import 'core/services/property_repository.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const WamatoApp());
}

class WamatoApp extends StatefulWidget {
  const WamatoApp({super.key});

  @override
  State<WamatoApp> createState() => _WamatoAppState();
}

class _WamatoAppState extends State<WamatoApp> {
  late final AuthCubit _authCubit;
  late final PropertyCubit _propertyCubit;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(AuthRepository());
    _propertyCubit = PropertyCubit(const PropertyRepository());
    // Restore token and kick off property load in parallel
    _authCubit.checkSession();
    _propertyCubit.loadHome();
  }

  @override
  void dispose() {
    _authCubit.close();
    _propertyCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _propertyCubit),
      ],
      child: _RouterWrapper(authCubit: _authCubit),
    );
  }
}

class _RouterWrapper extends StatefulWidget {
  final AuthCubit authCubit;
  const _RouterWrapper({required this.authCubit});

  @override
  State<_RouterWrapper> createState() => _RouterWrapperState();
}

class _RouterWrapperState extends State<_RouterWrapper> {
  late final router = createRouter(widget.authCubit);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Wamato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
