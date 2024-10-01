import 'package:location/location.dart';

String strToASCII(String data) {
  String requestStr = '';
  for (int i = 0; i < data.length; i++) {
    int aInt = data.codeUnitAt(i); // Get ASCII value of character
    requestStr += integerToHexString(aInt);
  }
  return requestStr;
}

String integerToHexString(int s) {
  String hexString = s.toRadixString(16); // Convert to hex string
  if (hexString.length % 2 != 0) {
    hexString = '0$hexString'; // Add padding if odd length
  }
  return hexString.toUpperCase();
}

List<int> hexStringToBytes(String hexString) {
  int len = hexString.length;
  List<int> byteArray = List<int>.filled(len ~/ 2, 0);

  for (int i = 0; i < len; i += 2) {
    String byteStr = hexString.substring(i, i + 2);
    byteArray[i ~/ 2] = int.parse(byteStr, radix: 16);
  }

  return byteArray;
}

Future<LocationData> getLatestPosition() async {
  Location location = Location();

  bool serviceEnabled;
  PermissionStatus permissionGranted;

  serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
  }

  permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      return Future.error('Location permissions are denied');
    }
  }

  return await location.getLocation();
}

Stream<LocationData> getStreamPosition(
    {int periodicInSecond = 20,
    void Function()? callbackAfterPermissionDone}) async* {
  Location location = Location();

  bool serviceEnabled;
  PermissionStatus permissionGranted;

  serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      yield* Stream.error('Location services are disabled.');
    }
  }
  if (serviceEnabled) {
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted == PermissionStatus.denied) {
        yield* Stream.error('Location permissions are denied');
      } else if (permissionGranted == PermissionStatus.deniedForever) {
        yield* Stream.error(
            'Location permissions are denied forever, you can enabled it from application setting');
      }
    }

    callbackAfterPermissionDone?.call();

    if (permissionGranted == PermissionStatus.granted) {
      location.changeSettings(interval: periodicInSecond * 1000);
      yield* location.onLocationChanged;
    }
  } else {
    callbackAfterPermissionDone?.call();
  }
}
