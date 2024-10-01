import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hautomate/src/data/preference/app_preference.dart';
import 'package:hautomate/src/serial_app2.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  // usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  // await setupServices();
  // runApp(const MyApp());
  await requestPermissions();
  runApp(const SerialApp());
}

Future<void> requestPermissions() async {
  if (await Permission.storage.request().isGranted &&
      await Permission.manageExternalStorage.request().isGranted) {
    print("Semua izin diberikan.");
  } else {
    print("Tidak semua izin diberikan.");
  }
}

Future<void> setupServices() async {
  //dependecy injection
  await registerDI();
  //logger
  Logger.level = kDebugMode ? Level.trace : Level.off;

  await registerFirebase();

  await GetIt.I.getAsync<AppPreference>();

  //DO NOT REMOVE/CHANGE THIS : SETUP SERVICES
}

Future<void> registerDI() async {
  var inject = GetIt.I;
  //app preferences
  inject.registerLazySingletonAsync<AppPreference>(
      () => AppPreference().initialize());

  inject.registerLazySingleton(() => Logger());

  /* // use like this : inject()
  
  // examples :
  inject.registerLazySingleton(() => SerialNumberRemoteDatasource(inject()));
  inject.registerLazySingleton<ISerialNumberRepository>(() => SerialNumberRepository(inject()));
  inject.registerFactory(() => CheckAppUpdateUseCase(inject()));
  */

  //DO NOT REMOVE/CHANGE THIS : REGISTER DI
}

Future<void> registerFirebase() async {
  //firebase and the children
}
