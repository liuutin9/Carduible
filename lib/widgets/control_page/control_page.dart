import 'package:carduible/providers/bluetooth_provider.dart';
import 'package:carduible/services/navigation_service.dart';
import 'package:carduible/widgets/control_page/control_panel.dart';
import 'package:carduible/widgets/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceId = GoRouterState.of(context).pathParameters['deviceId'];
    if (deviceId == debugDeviceId) {
      return PopScope(
        canPop: true,
        // use onPopInvokedWithResult if you need to know if the user popped the scope
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          if (context.mounted) {
            Provider.of<NavigationService>(context, listen: false).goHome();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (context.mounted) {
                  Provider.of<NavigationService>(context, listen: false).goHome();
                }
              },
            ),
            title: const Text('Debug Mode'),
          ),
          body: const ControlPanel(),
        ),
      );
    } else {
      BluetoothProvider bluetooth = Provider.of<BluetoothProvider>(context, listen: false);
      return FutureBuilder(
        future: bluetooth.connectToDevice(bluetooth.selectedDevice!, context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return PopScope(
              canPop: false,
              child: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text('Connecting to ${bluetooth.selectedDevice?.platformName}'),
                    ],
                  ),
                ),
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.done && snapshot.hasError) {
            return PopScope(
              canPop: false,
              // onPopInvoked: (bool didPop) async {
              //   await bluetooth.disconnectFromDevice();
              //   if (context.mounted) {
              //     Provider.of<NavigationService>(context, listen: false).goHome();
              //   }
              // },
              // use onPopInvokedWithResult if you need to know if the user popped the scope
              onPopInvokedWithResult: (bool didPop, Object? result) async {
                if (didPop) {
                  return;
                }
                await bluetooth.disconnectFromDevice();
                if (context.mounted) {
                  Provider.of<NavigationService>(context, listen: false).goHome();
                }
              },
              child: Scaffold(
                body: Center(
                  child: Text('Failed to connect: ${snapshot.error}'),
                ),
              ),
            );
          } else {
            return PopScope(
              canPop: false,
              // onPopInvoked: (bool didPop) async {
              //   await bluetooth.disconnectFromDevice();
              //   if (context.mounted) {
              //     Provider.of<NavigationService>(context, listen: false).goHome();
              //   }
              // },
              // use onPopInvokedWithResult if you need to know if the user popped the scope
              onPopInvokedWithResult: (bool didPop, Object? result) async {
                if (didPop) {
                  return;
                }
                await bluetooth.disconnectFromDevice();
                if (context.mounted) {
                  Provider.of<NavigationService>(context, listen: false).goHome();
                }
              },
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      await bluetooth.disconnectFromDevice();
                      if (context.mounted) {
                        Provider.of<NavigationService>(context, listen: false).goHome();
                      }
                    },
                  ),
                  title: Text(bluetooth.selectedDevice?.platformName ?? 'Device'),
                ),
                body: const ControlPanel(),
              ),
            );
          }
        },
      );
    }
  }
}