import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const _maroon = Color(0xFF800000);

class ReportDetailPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const ReportDetailPage(
      {super.key, required this.docId, required this.data});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  bool _deleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Delete Report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will permanently delete the report, any linked matches, '
          'and chat history. This cannot be undone. Are you sure?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final db = FirebaseFirestore.instance;
      final docId = widget.docId;

      // Find all matches that reference this report (two queries — no OR across fields in Firestore)
      final results = await Future.wait([
        db.collection('Matches').where('reportId1', isEqualTo: docId).get(),
        db.collection('Matches').where('reportId2', isEqualTo: docId).get(),
      ]);

      final allMatches = [...results[0].docs, ...results[1].docs];

      for (final matchDoc in allMatches) {
        final matchData = matchDoc.data();
        final chatId = matchData['chatId'] as String?;

        if (chatId != null) {
          // Delete every message in the chat subcollection
          final messages = await db
              .collection('Chats')
              .doc(chatId)
              .collection('Messages')
              .get();
          for (final msg in messages.docs) {
            await msg.reference.delete();
          }
          // Delete the chat document itself
          await db.collection('Chats').doc(chatId).delete();
        }

        // Reset the OTHER report's status back to 'pending'
        final otherReportId = (matchData['reportId1'] as String?) == docId
            ? matchData['reportId2'] as String?
            : matchData['reportId1'] as String?;
        if (otherReportId != null) {
          await db
              .collection('Reports')
              .doc(otherReportId)
              .update({'status': 'pending'});
        }

        // Delete the match document
        await matchDoc.reference.delete();
      }

      // Finally delete the report itself
      await db.collection('Reports').doc(docId).delete();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.data['type'] as String? ?? '';
    final category = widget.data['category'] as String? ?? '—';
    final status = widget.data['status'] as String? ?? 'pending';
    final colour = widget.data['colour'] as String? ?? '—';
    final brand = widget.data['brand'] as String? ?? '—';
    final location = widget.data['location'] as String? ?? '—';
    final description = widget.data['description'] as String? ?? '—';
    final imageUrl = widget.data['imageUrl'] as String?;
    final ts = widget.data['timestamp'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
        : '—';

    final isLost = type == 'Lost';
    final typeColor = isLost ? _maroon : Colors.green.shade700;

    final statusCfg = _statusConfig(status);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // ── Image header ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: imageUrl != null ? 260 : 120,
            pinned: true,
            backgroundColor: _maroon,
            foregroundColor: Colors.white,
            actions: [
              _deleting
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Delete report',
                      onPressed: _confirmDelete,
                    ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx2, err, stack) =>
                          _placeholder(typeColor),
                    )
                  : _placeholder(typeColor),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status banner ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: statusCfg.$1,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(statusCfg.$3, size: 16, color: statusCfg.$2),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                        style: TextStyle(
                          color: statusCfg.$2,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Title row ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),

                // ── Details card ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.category_outlined,
                          label: 'Category',
                          value: category,
                        ),
                        _divider(),
                        _DetailRow(
                          icon: Icons.palette_outlined,
                          label: 'Colour',
                          value: colour,
                        ),
                        _divider(),
                        _DetailRow(
                          icon: Icons.label_outline,
                          label: 'Brand',
                          value: brand,
                        ),
                        _divider(),
                        _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: location,
                        ),
                        _divider(),
                        _DetailRow(
                          icon: Icons.notes_rounded,
                          label: 'Description',
                          value: description,
                          multiline: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Reporter UID (admin info) ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Reported by',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500)),
                              const SizedBox(height: 2),
                              Text(
                                widget.data['uid'] as String? ?? '—',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _placeholder(Color color) => Container(
        color: color.withValues(alpha: 0.08),
        child: Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 48, color: color.withValues(alpha: 0.3)),
        ),
      );

  (Color, Color, IconData) _statusConfig(String status) {
    switch (status) {
      case 'matched':
        return (Colors.blue.shade50, Colors.blue.shade700,
            Icons.link_rounded);
      case 'resolved':
        return (Colors.green.shade50, Colors.green.shade700,
            Icons.check_circle_outline_rounded);
      case 'sensitive':
        return (Colors.orange.shade50, Colors.orange.shade700,
            Icons.warning_amber_rounded);
      default:
        return (Colors.grey.shade100, Colors.grey.shade600,
            Icons.hourglass_empty_rounded);
    }
  }
}

// ─────────────────────────────────────────
// Detail row
// ─────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: _maroon),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
