import 'package:carduible/providers/settings_provider.dart';
import 'package:carduible/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final List<IconData> icons = [
    Icons.north_west,Icons.north, Icons.north_east,
    Icons.rotate_left, Icons.circle_outlined, Icons.rotate_right,
    Icons.south_west, Icons.south, Icons.south_east,
  ];

  final List<String> sentChar = [
    'q', 'w', 'e',
    'a', 'x', 'd',
    'z', 's', 'c',
  ];

  @override
  Widget build(BuildContext context) {
    final buttonSettingsProvider = Provider.of<ButtonSettingsProvider>(context);
    
    // check if settings are loaded
    if (!buttonSettingsProvider.isLoaded) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          if (context.mounted) {
            Provider.of<NavigationService>(context, listen: false).goHome();
          }
        },
        child: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Loading settings configuration...'),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<ButtonSettingsProvider>(
      builder: (context, settingsProvider, child) {
        return PopScope(
          canPop: true,
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
                onPressed: () {
                  Provider.of<NavigationService>(context, listen: false).goHome();
                },
              ),
              title: const Text('Settings'),
            ),
            body: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        ...List.generate(ButtonSettingsProvider.numButtons, (index) {
                          return ListTile(
                            leading: Icon(icons[index]),
                            title: Text('Button ${index + 1}'),
                            subtitle: Text('Send \'${sentChar[index]}\' to BT05'),
                            trailing: Switch(
                              value: settingsProvider.getButtonState(index),
                              onChanged: (value) {
                                settingsProvider.setButtonState(index, value);
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton(
                            onPressed: () {
                              settingsProvider.resetToDefaults();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: const Text('Reset to Defaults'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}