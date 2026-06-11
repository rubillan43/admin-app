import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';
import 'report_detail_page.dart';

const _maroon = Color(0xFF800000);
const _maroonDark = Color(0xFF5C0000);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _filter = 'all'; // all | pending | matched | resolved | sensitive

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snap) {
          final allDocs = snap.data?.docs ?? [];

          // Summary counts
          final counts = {
            'pending': allDocs
                .where((d) =>
                    (d.data() as Map)['status'] == 'pending')
                .length,
            'matched': allDocs
                .where((d) =>
                    (d.data() as Map)['status'] == 'matched')
                .length,
            'resolved': allDocs
                .where((d) =>
                    (d.data() as Map)['status'] == 'resolved')
                .length,
            'sensitive': allDocs
                .where((d) =>
                    (d.data() as Map)['status'] == 'sensitive')
                .length,
          };

          // Filtered docs
          final docs = _filter == 'all'
              ? allDocs
              : allDocs
                  .where((d) =>
                      (d.data() as Map)['status'] == _filter)
                  .toList();

          return CustomScrollView(
            slivers: [
              // ── AppBar ────────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 130,
                pinned: true,
                backgroundColor: _maroon,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Sign out',
                    onPressed: _signOut,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_maroonDark, _maroon],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Colors.white70,
                                    size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'ADMIN PANEL',
                                  style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.85),
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'UTM Secure',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${allDocs.length} reports total',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Summary stat tiles ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      _StatTile(
                        label: 'Pending',
                        count: counts['pending']!,
                        color: Colors.grey.shade600,
                        icon: Icons.hourglass_empty_rounded,
                        selected: _filter == 'pending',
                        onTap: () => setState(() => _filter =
                            _filter == 'pending' ? 'all' : 'pending'),
                      ),
                      const SizedBox(width: 8),
                      _StatTile(
                        label: 'Matched',
                        count: counts['matched']!,
                        color: Colors.blue.shade700,
                        icon: Icons.link_rounded,
                        selected: _filter == 'matched',
                        onTap: () => setState(() => _filter =
                            _filter == 'matched' ? 'all' : 'matched'),
                      ),
                      const SizedBox(width: 8),
                      _StatTile(
                        label: 'Resolved',
                        count: counts['resolved']!,
                        color: Colors.green.shade700,
                        icon: Icons.check_circle_outline_rounded,
                        selected: _filter == 'resolved',
                        onTap: () => setState(() => _filter =
                            _filter == 'resolved' ? 'all' : 'resolved'),
                      ),
                      const SizedBox(width: 8),
                      _StatTile(
                        label: 'Sensitive',
                        count: counts['sensitive']!,
                        color: Colors.orange.shade700,
                        icon: Icons.warning_amber_rounded,
                        selected: _filter == 'sensitive',
                        onTap: () => setState(() => _filter =
                            _filter == 'sensitive' ? 'all' : 'sensitive'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Filter label ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        _filter == 'all'
                            ? 'All Reports'
                            : '${_filter[0].toUpperCase()}${_filter.substring(1)} Reports',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${docs.length} items',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Report list ───────────────────────────────────────────────
              snap.connectionState == ConnectionState.waiting
                  ? const SliverFillRemaining(
                      child: Center(
                          child: CircularProgressIndicator(color: _maroon)),
                    )
                  : docs.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 56,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No reports found',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final doc = docs[i];
                              final data =
                                  doc.data() as Map<String, dynamic>;
                              return _ReportCard(
                                  docId: doc.id, data: data);
                            },
                            childCount: docs.length,
                          ),
                        ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
// Stat tile (tappable filter)
// ─────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _StatTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.shade200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? color : Colors.grey.shade500,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Report card row
// ─────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _ReportCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? '';
    final category = data['category'] as String? ?? 'Unknown';
    final status = data['status'] as String? ?? 'pending';
    final location = data['location'] as String? ?? '—';
    final ts = data['timestamp'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
        : '—';

    final isLost = type == 'Lost';
    final typeColor = isLost ? _maroon : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ReportDetailPage(docId: docId, data: data),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLost ? Icons.search_rounded : Icons.inventory_2_outlined,
                  color: typeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusChip(status: status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          dateStr,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded,
                  color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Status chip
// ─────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Map<String, (Color, Color, IconData)> cfg = {
      'pending': (Colors.grey.shade100, Colors.grey.shade600,
          Icons.hourglass_empty_rounded),
      'matched': (Colors.blue.shade50, Colors.blue.shade700,
          Icons.link_rounded),
      'resolved': (Colors.green.shade50, Colors.green.shade700,
          Icons.check_circle_outline_rounded),
      'sensitive': (Colors.orange.shade50, Colors.orange.shade700,
          Icons.warning_amber_rounded),
    };
    final style = cfg[status] ??
        (Colors.grey.shade100, Colors.grey.shade600,
            Icons.hourglass_empty_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: style.$1,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.$3, size: 10, color: style.$2),
          const SizedBox(width: 3),
          Text(
            '${status[0].toUpperCase()}${status.substring(1)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: style.$2,
            ),
          ),
        ],
      ),
    );
  }
}
