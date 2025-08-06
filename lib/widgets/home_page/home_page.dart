import 'dart:io';
import 'package:carduible/providers/bluetooth_provider.dart';
import 'package:carduible/providers/settings_provider.dart';
import 'package:carduible/services/navigation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';

String debugDeviceId = 'DebugEECamp';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<BluetoothDevice> devicesListPlus = [];
  StreamSubscription? scanSubscription;
  bool isScanning = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart,
    ));
    checkPermissions();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> checkPermissions() async {
    if (kIsWeb) {
      // Web platform does not require any permissions
      startScan();
    } else if (Platform.isIOS) {
      var locationPermission = await Permission.location.request();
      var bluetoothPermission = await Permission.bluetooth.request();

      if (locationPermission.isGranted && bluetoothPermission.isGranted) {
        startScan();
      } else {
        if (!locationPermission.isGranted) {
          locationPermission = await Permission.location.request();
        }
        if (!bluetoothPermission.isGranted) {
          bluetoothPermission = await Permission.bluetooth.request();
        }
      }
    } else if (Platform.isAndroid) {
      var locationPermission = await Permission.location.request();
      var bluetoothPermission = await Permission.bluetoothScan.request();

      if (locationPermission.isGranted && bluetoothPermission.isGranted) {
        if (Platform.isAndroid) {
          await FlutterBluePlus.turnOn();
        }
        safeStartScan();
        // startScan();
      } else {
        if (!locationPermission.isGranted) {
          locationPermission = await Permission.location.request();
        }
        if (!bluetoothPermission.isGranted) {
          bluetoothPermission = await Permission.bluetoothScan.request();
        }
      }
    } else {
      debugPrint("Unsupported platform\n");
    }
  }

  Future<void> safeStartScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // ✅ 停止上次掃描
      await FlutterBluePlus.stopScan();
      await scanSubscription?.cancel();
      scanSubscription = null;

      // ✅ 要求權限
      final statusLocation = await Permission.location.request();
      final statusScan = await Permission.bluetoothScan.request();
      final statusConnect = await Permission.bluetoothConnect.request();

      if (!statusLocation.isGranted ||
          !statusScan.isGranted ||
          !statusConnect.isGranted) {
        debugPrint("❌ 權限不足，無法掃描藍牙裝置");
        return;
      }

      // ✅ 等待 BLE 變成 ON
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        debugPrint("🔌 藍牙未開啟，嘗試呼叫 turnOn()");
        await FlutterBluePlus.turnOn();
        await Future.delayed(const Duration(seconds: 2));

        final checkAgain = await FlutterBluePlus.adapterState.first;
        if (checkAgain != BluetoothAdapterState.on) {
          debugPrint("❌ 藍牙仍未開啟，掃描取消");
          return;
        }
      }

      // ✅ 正式開始掃描
      debugPrint("🔍 開始藍牙掃描...");
      devicesListPlus.clear();

      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            devicesListPlus = results
                .map((r) => r.device)
                .where((d) => d.platformName.isNotEmpty)
                .toSet()
                .toList();
          });
        }
      });

      await FlutterBluePlus.startScan(timeout: timeout);

      setState(() {
        isScanning = true;
      });
      _controller.repeat();

      // 等待掃描結束
      await Future.delayed(timeout);
    } catch (e, stack) {
      debugPrint('❌ 發生掃描錯誤: $e');
      debugPrint(stack.toString());
    } finally {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
        _controller.stop();
      }
      debugPrint("✅ 掃描結束");
    }
  }

  Future<void> startScan() async {
    if (isScanning) return;

    await FlutterBluePlus.stopScan();
    await scanSubscription?.cancel();
    scanSubscription = null;

    setState(() {
      isScanning = true;
    });
    _controller.repeat();

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          devicesListPlus = results
              .map((r) => r.device)
              .where((device) => device.platformName != '') // 排除空名字裝置
              .toList();
        });
      }
    });

    await Future.delayed(const Duration(seconds: 15));
    if (mounted) {
      setState(() {
        isScanning = false;
      });
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRacingMode =
        Provider.of<ButtonSettingsProvider>(context, listen: true)
            .getButtonState(9);
    final nav = Provider.of<NavigationService>(context, listen: false);
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            floating: false,
            stretch: true,
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            foregroundColor: Theme.of(context).colorScheme.onTertiary,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              centerTitle: true,
              title: Text(
                'Carduible',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
              background: Image.asset(
                'assets/sliver_app_bar_background.png',
                fit: BoxFit.fitWidth,
              ),
            ),
            actions: [
              RotationTransition(
                turns: _animation,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: isScanning ? null : checkPermissions,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  nav.goSettings();
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // 如果是最後一個 index，就顯示 debug item
                if (index == 0) {
                  return ListTile(
                    title: const Text('🛠 Debug'),
                    subtitle: const Text('Enter debugging mode'),
                    trailing: const Icon(Icons.bug_report),
                    tileColor: Theme.of(context).colorScheme.surfaceContainer,
                    onTap: () {
                      if (isRacingMode) {
                        nav.goRacingPanel(deviceId: debugDeviceId);
                      } else {
                        nav.goControlPanel(deviceId: debugDeviceId);
                      }
                    },
                  );
                }

                // 否則就顯示一般裝置
                final device = devicesListPlus[index - 1];
                return ListTile(
                  title: Text(device.platformName),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: const Icon(Icons.bluetooth),
                  tileColor: Theme.of(context).colorScheme.surfaceContainer,
                  onTap: () {
                    Provider.of<BluetoothProvider>(context, listen: false)
                        .setSelectedDevice(device);
                    nav.goControlPanel(deviceId: device.remoteId.toString());
                  },
                );
              },
              childCount: devicesListPlus.length + 1, // 多加一個 for debug
            ),
          ),
          // SliverList(
          //   delegate: SliverChildBuilderDelegate(
          //     childCount: devicesListPlus.length,
          //     (context, index) {
          //       return ListTile(
          //         title: Text(devicesListPlus[index].platformName),
          //         subtitle: Text(devicesListPlus[index].remoteId.toString()),
          //         trailing: const Icon(Icons.bluetooth),
          //         tileColor: Theme.of(context).colorScheme.surfaceContainer,
          //         onTap: () {
          //           Provider.of<BluetoothProvider>(context, listen: false)
          //               .setSelectedDevice(devicesListPlus[index]);
          //           if (isRacingMode) {
          //             nav.goRacingPanel(
          //                 deviceId: devicesListPlus[index].remoteId.toString());
          //           } else {
          //             nav.goControlPanel(
          //                 deviceId: devicesListPlus[index].remoteId.toString());
          //           }
          //         },
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}
