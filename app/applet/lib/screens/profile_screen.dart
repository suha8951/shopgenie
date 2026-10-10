import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool showAdvancedSettings = false;

  String djangoServerUrl = 'http://10.0.2.2:8000';
  String phoneCameraDescription = 'Uses this device camera';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STORE PROFILE
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      child: Icon(
                        Icons.storefront_outlined,
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'ShopGenie Store',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Owner: Shopkeeper',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // CONNECTION STATUS
            const Text(
              'Connection Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  _ConnectionRow(
                    icon: Icons.dns_outlined,
                    title: 'Django Server',
                    status: 'Connected',
                    connected: true,
                  ),

                  const Divider(height: 1),

                  _ConnectionRow(
                    icon: Icons.camera_alt_outlined,
                    title: 'Phone Camera',
                    status: 'Connected',
                    connected: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // PHONE CAMERA
            const Text(
              'Phone Camera',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.camera_alt_outlined,
                  ),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Connected',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.green.withValues(alpha: 0.12),
                  ),
                  child: const Text(
                    'Ready',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ADVANCED SETTINGS
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.settings_outlined,
                    ),
                    title: const Text(
                      'Advanced Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Server, camera and system configuration',
                    ),
                    trailing: Icon(
                      showAdvancedSettings
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                    onTap: () {
                      setState(() {
                        showAdvancedSettings =
                        !showAdvancedSettings;
                      });
                    },
                  ),

                  if (showAdvancedSettings) ...[
                    const Divider(height: 1),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // DJANGO
                          const Text(
                            'Django API Server',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller: TextEditingController(
                              text: djangoServerUrl,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Server URL',
                              prefixIcon: Icon(
                                Icons.dns_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              djangoServerUrl = value;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Phone camera
                          const Text(
                            'Phone Camera',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller: TextEditingController(
                              text: phoneCameraDescription,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Camera source',
                              prefixIcon: Icon(
                                Icons.camera_alt_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              phoneCameraDescription = value;
                            },
                          ),

                          const SizedBox(height: 20),

                          // SYSTEM ARCHITECTURE
                          const Text(
                            'System Architecture',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(12),
                              color: Colors.grey.shade100,
                            ),
                            child: const Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Flutter Mobile App',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text('↓'),
                                SizedBox(height: 6),
                                Text(
                                  'Django REST API',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text('↓'),
                                SizedBox(height: 6),
                                Text(
                                  'PostgreSQL Database',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Phone Camera → Vision / CV Engine',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Connection settings saved.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.save_outlined,
                              ),
                              label: const Text(
                                'Save Connection Settings',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ConnectionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final bool connected;

  const _ConnectionRow({
    required this.icon,
    required this.title,
    required this.status,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: connected ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}