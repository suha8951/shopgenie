import 'package:flutter/material.dart';
import '../services/demo_data.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';

class WorkerManagementScreen extends StatefulWidget {
  const WorkerManagementScreen({super.key});

  @override
  State<WorkerManagementScreen> createState() => _WorkerManagementScreenState();
}

class _WorkerManagementScreenState extends State<WorkerManagementScreen> {
  final List<DemoWorker> _workers = DemoData.demoWorkers;

  void _onAddWorker() {
    if (DemoService().isDemoMode) {
      DemoService().showDemoActionDisabledDialog(
        context,
        actionName: 'Worker creation',
        customExplanation:
            'Adding new store staff is disabled in Demo Mode.\n\n'
            'A real authenticated shopkeeper login is required to register worker credentials and assign POS permissions.',
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff creation requires live backend connection.')),
    );
  }

  void _onWorkerAction(DemoWorker worker, String action) {
    if (DemoService().isDemoMode) {
      DemoService().showDemoActionDisabledDialog(
        context,
        actionName: '$action for ${worker.name}',
        customExplanation:
            'Staff modifications are disabled in Demo Mode.\n\n'
            'A real authenticated shopkeeper login is required to modify shift timings or permissions.',
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _workers.where((w) => w.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Add Worker',
            onPressed: _onAddWorker,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddWorker,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Worker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header summary banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.badge_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kirana Staff & Operators',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_workers.length} staff members • $activeCount active on shift today',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Demo notice card
            if (DemoService().isDemoMode) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Demo Mode: Showing sample worker roster. Staff creation and role edits are simulated and disabled.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Store Team Roster',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Workers List
            ..._workers.map((worker) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                              child: Text(
                                worker.name.substring(0, 1),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          worker.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: worker.isActive
                                              ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                                              : Colors.orange.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          worker.isActive ? 'Active Shift' : 'On Leave',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: worker.isActive ? AppTheme.primaryGreen : Colors.orange.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    worker.role,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0288D1),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 14, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        worker.shift,
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        worker.phone,
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        // Assigned permissions
                        const Text(
                          'Assigned Permissions:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: worker.permissions
                              .map(
                                (perm) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Text(
                                    perm,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _onWorkerAction(worker, 'Edit permissions'),
                              icon: const Icon(Icons.edit_outlined, size: 15),
                              label: const Text('Edit Role', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _onWorkerAction(worker, 'Remove worker'),
                              icon: const Icon(Icons.delete_outline, size: 15, color: AppTheme.dangerRed),
                              label: const Text('Remove', style: TextStyle(fontSize: 12, color: AppTheme.dangerRed)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 60), // Space for FAB
          ],
        ),
      ),
    );
  }
}
