import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/crop_input.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_overlay.dart';
import '../crop_data/crop_data_screen.dart';

/// Shows all past crop data submissions fetched from Firestore.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _firestoreService = FirestoreService();
  List<CropInput>? _records;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId =
          context.read<AuthService>().currentUser?.uid ?? 'demo-user-001';
      final records = await _firestoreService.getUserHistory(userId);
      setState(() => _records = records);
    } catch (e) {
      setState(() => _error = 'Failed to load history. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord(String id, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Record',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete this record?',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteCropInput(id);
        setState(() => _records!.removeAt(index));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Record deleted',
                  style: GoogleFonts.poppins(fontSize: 13)),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete record',
                  style: GoogleFonts.poppins(fontSize: 13)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📜 Prediction History',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'All your past crop analyses',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _fetchHistory,
                tooltip: 'Refresh',
              ),
            ],
          ),

          // ── Content ──────────────────────────────────────────
          if (_isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ShimmerCard(),
                childCount: 5,
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: AppErrorWidget(
                message: _error!,
                onRetry: _fetchHistory,
              ),
            )
          else if (_records == null || _records!.isEmpty)
            SliverFillRemaining(
              child: EmptyStateWidget(
                title: 'No Predictions Yet',
                subtitle:
                    'Start by entering your crop data and get your first yield prediction!',
                icon: Icons.grass_rounded,
                actionLabel: 'Add Crop Data',
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CropDataScreen()),
                ),
              ),
            )
          else ...[
            // ── Summary Bar ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: _SummaryBar(records: _records!),
              ),
            ),

            // ── Record List ──────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _HistoryCard(
                    record: _records![i],
                    index: i,
                    onDelete: () => _deleteRecord(_records![i].id!, i),
                  ),
                  childCount: _records!.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }
}

// ─── Summary Bar ─────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final List<CropInput> records;
  const _SummaryBar({required this.records});

  @override
  Widget build(BuildContext context) {
    final avgYield = records
            .where((r) => r.predictedYield != null)
            .fold(0.0, (sum, r) => sum + r.predictedYield!) /
        (records.where((r) => r.predictedYield != null).length.toDouble());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          _StatBox(
            label: 'Total',
            value: '${records.length}',
            emoji: '📊',
          ),
          _divider(),
          _StatBox(
            label: 'Avg Yield',
            value: '${avgYield.toStringAsFixed(1)}t/ha',
            emoji: '🌾',
          ),
          _divider(),
          _StatBox(
            label: 'Latest',
            value: _latestCrop(records),
            emoji: '🌱',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: AppTheme.divider,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );

  String _latestCrop(List<CropInput> records) {
    if (records.isEmpty) return '—';
    return records.first.cropType.split(' ').first;
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _StatBox(
      {required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final CropInput record;
  final int index;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.record,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMM yyyy  •  hh:mm a').format(record.timestamp);
    final yield_ = record.predictedYield;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetailSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Top Row ────────────────────────────────
                Row(
                  children: [
                    // Crop emoji container
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.paleGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _cropEmoji(record.cropType),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.cropType,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            '📍 ${record.location}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Yield badge
                    if (yield_ != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${yield_}t',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // ── Bottom Row ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _MiniChip(
                          label: record.soilType.split(' ').first,
                          color: AppTheme.soil,
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.delete_outline_rounded,
                                size: 16, color: Colors.red.shade400),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(record: record),
    );
  }

  String _cropEmoji(String crop) {
    final map = {
      'Rice': '🌾',
      'Wheat': '🌾',
      'Maize': '🌽',
      'Sugarcane': '🎋',
      'Cotton': '☁️',
      'Soybean': '🫘',
      'Potato': '🥔',
      'Tomato': '🍅',
      'Onion': '🧅',
      'Groundnut': '🥜',
    };
    for (final key in map.keys) {
      if (crop.contains(key)) return map[key]!;
    }
    return '🌿';
  }
}

// ─── Mini Chip ───────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ─── Detail Bottom Sheet ─────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final CropInput record;
  const _DetailSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '📋 ${record.cropType} Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow('Location', '📍 ${record.location}'),
          _DetailRow('Soil Type', '🪨 ${record.soilType}'),
          _DetailRow('Rainfall', '🌧 ${record.rainfall} mm'),
          _DetailRow('Temperature', '🌡 ${record.temperature}°C'),
          _DetailRow('Humidity', '💧 ${record.humidity}%'),
          if (record.predictedYield != null)
            _DetailRow('Predicted Yield',
                '🏆 ${record.predictedYield} tons/hectare',
                highlight: true),
          if (record.suggestedCrop != null)
            _DetailRow('Suggested Variety', '🌱 ${record.suggestedCrop!}'),
          _DetailRow('Date',
              DateFormat('dd MMM yyyy, hh:mm a').format(record.timestamp)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _DetailRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppTheme.primaryGreen : AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Loading Card ────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
