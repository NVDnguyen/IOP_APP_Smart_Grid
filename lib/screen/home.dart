// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iot_app/models/devices.dart';
import 'package:iot_app/screen/profile.dart';
import 'package:iot_app/screen/wellcome.dart';
import 'package:iot_app/services/realtime_firebase.dart';
import 'package:iot_app/models/users.dart';
import 'package:iot_app/provider/data_user.dart';
import 'package:iot_app/widgets/Dashboard/dashboard_widgets.dart';
import 'package:iot_app/widgets/Notice/notice_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Users user;
  bool isDataLoaded = false;
  bool isNotHaveSystem = false;
  bool isHome = true;
  late String helloSTR = "";

  // Create List of SystemLog Objects
  List<Widget> wNoSystem = [];
  List<String> listIdSys = [];
  List<Widget> wDevices = [];
  List<Widget> wSystems = [];

  String selectedSystem = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      //sys with cloud
      user = await SharedPreferencesProvider.getDataUser();
      Users userNew = await DataFirebase.getUserRealTime(user);

      if (userNew != user) {
        user = userNew;
        SharedPreferencesProvider.setDataUser(user);
      } //

      // buid dash board
      await buildSystemList();
      setState(() {
        DataFirebase.addSystem("ESP_3470400_1458270", "", user);
        listIdSys = user.getSystemIDs();
        helloSTR = "Hi, " + user.username + " !";

        isDataLoaded = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  Future<void> buildSystemList() async {
    try {
      Users userNew = await DataFirebase.getUserRealTime(user);
      if (userNew != user) {
        user = userNew;
        SharedPreferencesProvider.setDataUser(user);
      }
      List<String> listSystems = userNew.getSystemIDs();
      List<Widget> wListSt = []; //
      // parallel
      List<Future> futures = listSystems.map((e) async {
        var systemNameFuture = DataFirebase.getNameOfSystem(e);
        return Future.wait([systemNameFuture, Future.value(e)]);
      }).toList();

      // wait for all done
      var results = await Future.wait(futures);

      // process results
      for (var result in results) {
        String systemName = result[0];
        String idSystem = result[1];

        wListSt.add(
          BuildHomeWidgets.buildSystemCard(
            idSystem == selectedSystem,
            systemName,
            'https://img.freepik.com/premium-photo/concept-home-devices-multiple-houses-conected-networked_1059430-54450.jpg',
            onTap: () {
              wDevices.clear();
              //system ontap
              setState(() {
                isHome = false;
                //fetchUserData();
                buildSystemList();
                selectedSystem = idSystem;
                wDevices.add(BuildHomeWidgets.buildDeviceWidget(idSystem));
              });
            },
            onLongPress: () {
              _settingSystem(idSystem);
            },
          ),
        );
      }
      //

      setState(() {
        wListSt.isEmpty ? isNotHaveSystem = true : isNotHaveSystem = false;
        wSystems = wListSt;
        wNoSystem = [
          BuildHomeWidgets.buildInfoCard(
              "Bạn chưa lắp đặt hệ thống thiết bị nào",
              "Hãy lắp đặt các thiết bị an toàn, để bảo vệ bản thân, gia đình và mọi người xung quanh.",
              "Hướng cài đặt và sử dụng thiết bị",
              onTap: () => _launchUrl(Uri.parse('https://shopee.vn/'))),
          const SizedBox(
            height: 20,
          ),
        ];
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error building system list: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController systemIDcontroller = TextEditingController();
    final TextEditingController systemKeycontroller = TextEditingController();
    List<Widget> wHome = [];

    Future.delayed(const Duration(minutes: 30), () {
      if (!isDataLoaded) {
        // Check if the data is still not loaded
        showSnackBar(context, "Data Error");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  WellcomeScreen()), // Redirect to TimeoutScreen
          (Route<dynamic> route) => false, // Remove all routes below
        );
      }
    });
    return isDataLoaded
        ? Scaffold(
            backgroundColor: const Color(0xFFF7F8FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF7F8FA),
              elevation: 0,
              title: Text(
                helloSTR,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: CircleAvatar(
                      backgroundImage: FileImage(File(user
                          .image)), // Replace with the actual URL or asset image
                    ),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          BuildHomeWidgets.buildDeviceCard("Center", Icons.home,
                              onTap: () {
                            setState(() {
                              isHome = true;
                              selectedSystem = "H";
                              buildSystemList();
                            });
                          }),
                          ...wSystems,
                          BuildHomeWidgets.buildDeviceCard(
                            "Add Systems",
                            Icons.add_circle_outline,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                      "Add New System",
                                      textAlign: TextAlign.center,
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          "Please enter the System ID *",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: systemIDcontroller,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'System ID',
                                            prefixIcon: Icon(Icons.device_hub),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Please enter the Admin key",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: systemKeycontroller,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Key',
                                            prefixIcon: Icon(Icons.key),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          addSystem(systemIDcontroller.text,
                                              systemKeycontroller.text);
                                          setState(() {
                                            fetchUserData();
                                            buildSystemList();
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ...(isNotHaveSystem ? wNoSystem : []),
                    ...(isHome ? wHome : wDevices),
                  ],
                ),
              ),
            ))
        : const Center(
            child:
                CircularProgressIndicator(backgroundColor: Color(0xFFF7F8FA)));
  }

  Future<void> addSystem(String idSystem, String key) async {
    try {
      if (await DataFirebase.addSystem(idSystem, key, user)) {
        showSnackBar(context, "Add System Successfully");
      } else {
        showSnackBar(context, "Add System Fail");
      }
    } catch (e) {
      showSnackBar(context, "Add System Fail");
    }
  }

  Future<void> updateDeviceName(Device device, String text) async {}

  Future<void> _launchUrl(Uri _url) async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _settingSystem(String idSystem) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning,
                  color: Color.fromARGB(255, 255, 77, 7),
                  size: 40.0,
                ),
                SizedBox(height: 10.0),
                Text(
                  "This action cannot be undone. \n Are you sure you want to delete?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  print(idSystem);
                  DataFirebase.removeSystem(idSystem);
                  setState(() {
                    fetchUserData();
                    buildSystemList();
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('DELETE'),
              ),
            ],
          );
        });
  }
}
