import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:iot_app/models/devices.dart';
import 'package:iot_app/models/users.dart';
import 'package:iot_app/provider/data_user.dart';

class DataFirebase {
  // get data user
  static Future<Users> getUserRealTime(Users u) async {
    try {
      // Fetch data from Realtime Database
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('users').child(u.userID);
      DataSnapshot snapshot = await userRef.get();
      Map<dynamic, dynamic>? userData =
          snapshot.value as Map<dynamic, dynamic>?;

      if (userData != null) {
        // Create Users object from the retrieved data
        Map<String, dynamic> systems = userData['systems'] != null
            ? Map<String, dynamic>.from(userData['systems'])
            : {};

        Users user = Users.realTimeCloud(
          username: userData['user_name'],
          address: userData['address'],
          email: u.email,
          userID: u.userID,
          image: userData['image'],
          systems: systems,
        );
        return user;
      }
      throw e;
    } catch (e) {
      throw e;
    }
  }

  // get name of a system
  static Future<String> getNameOfSystem(String idSystem) async {
    try {
      DatabaseReference systemRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(idSystem)
          .child("idName");
      DataSnapshot snapshot = await systemRef.get();
      if (snapshot.exists) {
        return snapshot.value as String;
      } else {
        return "";
      }
    } catch (e) {
      print("Error getting system name: ${e.toString()}");
      return "";
    }
  }

  // add a system
  static Future<bool> addSystem(String idSystem, String key, Users u) async {
    try {
      DatabaseReference systemRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(idSystem)
          .child("Key");
      DataSnapshot snapshot = await systemRef.get();
      // if no exception throw, idSystem exist
      if (snapshot.exists) {
        DatabaseReference r = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(u.userID)
            .child("systems")
            .child(idSystem);
        print(snapshot.value);
        if (key.trim() != null && snapshot.value == key) {
          // is admin
          await r.update({"admin": 1});
        } else {
          // is not admin
          await r.update({"admin": 0});
        }
      }

      return true;
    } catch (e) {
      // idSystem not exist
      print("Error getting system name: ${e.toString()}");
      return false;
    }
  }

  // update name for a system
  static Future<bool> setNameOfSystem(String idSystem, String data) async {
    try {
      DatabaseReference systemRef =
          FirebaseDatabase.instance.ref().child('Systems').child(idSystem);
      await systemRef.update({"idName": data});
      return true;
    } catch (e) {
      print("Error setting system name: ${e.toString()}");
      return false;
    }
  }

  // stream device

  static Stream<Device> getStreamDevice(String systemID) {
    final StreamController<Device> controller = StreamController<Device>();

    try {
      final DatabaseReference deviceRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(systemID)
          .child("Data");

      deviceRef.onValue.listen((DatabaseEvent event) {
        if (event.snapshot.value == null) {
          controller.addError("Snapshot value is null");
          return;
        }
        try {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(event.snapshot.value as Map);
          final Device device = Device.fromJson(data);
          controller.add(device);
        } catch (e) {
          controller.addError("Error parsing device data: $e");
        }
      }, onError: (error) {
        controller.addError("Firebase stream error: $error");
      });
    } catch (e) {
      print("Error streaming device: ${e.toString()}");
      controller.addError(e);
    }

    return controller.stream;
  }

  // remove systerm id
  static Future<void> removeSystem(String idSystem) async {
    try {
      Users user = await SharedPreferencesProvider.getDataUser();
      DatabaseReference deviceRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.userID)
          .child("systems")
          .child(idSystem);
      await deviceRef.remove();
    } catch (e) {
      print("Error remove system: ${e.toString()}");
    }
  }
}
