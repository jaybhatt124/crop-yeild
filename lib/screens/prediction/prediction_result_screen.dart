import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../models/crop_input.dart';
import '../../services/prediction_service.dart';
import '../../utils/app_theme.dart';
import '../crop_data/crop_data_screen.dart';

/// Displays the AI yield prediction result with animated cards and tips.
class PredictionResultScreen extends StatefulWidget {
  final PredictionResult result;
  final CropInput cropInput;

  const PredictionResultScreen({
    super.key,
    required this.result,
    required this.cropInput,
  });

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _cardsCtrl;
  late Animation<double> _heroFade;
  late Animation<double> _heroScale;
  late List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();

    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _cardsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _heroFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
    _heroScale = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _heroCtrl, curve: Curves.elasticOut));

    // Stagger card slide-in animations
    _cardSlides = List.generate(4, (i) {
      final start = i * 0.15;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardsCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });

    _heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final input = widget.cropInput;
    final confidence = r.confidencePercent / 100;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.darkGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: _shareResult,
                tooltip: 'Share Result',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                child: SafeArea(
                  child: FadeTransition(
                    opacity: _heroFade,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        // ── Success Icon ──────────────────────
                        ScaleTransition(
                          scale: _heroScale,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2),
                            ),
                            child: const Center(
                              child: Text('🏆',
                                  style: TextStyle(fontSize: 44)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Prediction Ready!',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          r.cropType,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Yield Badge ───────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${r.yieldValue}',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                r.unit,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Predicted Yield',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Confidence Card ─────────────────────────
                  _AnimatedCard(
                    slideAnim: _cardSlides[0],
                    child: _ConfidenceCard(confidence: confidence),
                  ),
                  const SizedBox(height: 16),

                  // ── Suggested Crop ──────────────────────────
                  _AnimatedCard(
                    slideAnim: _cardSlides[1],
                    child: _SuggestedCropCard(suggestedCrop: r.suggestedCrop),
                  ),
                  const SizedBox(height: 16),

                  // ── Input Summary ───────────────────────────
                  _AnimatedCard(
                    slideAnim: _cardSlides[1],
                    child: _InputSummaryCard(input: input),
                  ),
                  const SizedBox(height: 20),

                  // ── Tips Header ─────────────────────────────
                  Text(
                    '💡 Expert Recommendations',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Water Tip ───────────────────────────────
                  _AnimatedCard(
                    slideAnim: _cardSlides[2],
                    child: _TipCard(
                      emoji: '💧',
                      title: 'Water Management',
                      tip: r.waterTip,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Fertilizer Tip ──────────────────────────
                  _AnimatedCard(
                    slideAnim: _cardSlides[2],
                    child: _TipCard(
                      emoji: '🧪',
                      title: 'Fertilizer Guide',
                      tip: r.fertilizerTip,
                      color: AppTheme.amber,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── General Tip ─────────────────────────────
                  _AnimatedCard(
                    slideAnim: _cardSlides[3],
                    child: _TipCard(
                      emoji: '🌿',
                      title: 'General Advice',
                      tip: r.generalTip,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Action Buttons ──────────────────────────
                  _AnimatedCard(
                    slideAnim: _cardSlides[3],
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CropDataScreen()),
                            ),
                            icon: const Text('🔄',
                                style: TextStyle(fontSize: 18)),
                            label: Text(
                              'New Prediction',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppTheme.primaryGreen),
                            label: Text(
                              'Back to Dashboard',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppTheme.primaryGreen, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareResult() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📤 Sharing: ${widget.result.cropType} yield = ${widget.result.yieldValue} ${widget.result.unit}',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Animated Card Wrapper ────────────────────────────────────

class _AnimatedCard extends StatelessWidget {
  final Animation<Offset> slideAnim;
  final Widget child;
  const _AnimatedCard({required this.slideAnim, required this.child});

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(
        opacity: slideAnim.drive(
          Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeOut)),
        ),
        child: child,
      ),
    );
  }
}

// ─── Confidence Card ─────────────────────────────────────────

class _ConfidenceCard extends StatelessWidget {
  final double confidence;
  const _ConfidenceCard({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 42,
            lineWidth: 8,
            percent: confidence,
            center: Text(
              '${(confidence * 100).toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
            progressColor: AppTheme.lightGreen,
            backgroundColor: AppTheme.paleGreen,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1200,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Model Confidence',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getConfidenceLabel(confidence),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getConfidenceLabel(double c) {
    if (c >= 0.9) return '🟢 Excellent match. High accuracy prediction.';
    if (c >= 0.75) return '🟡 Good accuracy. Suitable for planning.';
    return '🟠 Moderate accuracy. Consider local expert advice.';
  }
}

// ─── Suggested Crop Card ─────────────────────────────────────

class _SuggestedCropCard extends StatelessWidget {
  final String suggestedCrop;
  const _SuggestedCropCard({required this.suggestedCrop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🌱', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Variety',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
                Text(
                  suggestedCrop,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Optimal',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input Summary Card ──────────────────────────────────────

class _InputSummaryCard extends StatelessWidget {
  final CropInput input;
  const _InputSummaryCard({required this.input});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Input Summary',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryChip(label: '📍 ${input.location}'),
              _SummaryChip(label: '🪨 ${input.soilType}'),
              _SummaryChip(label: '🌱 ${input.cropType}'),
              _SummaryChip(label: '🌧 ${input.rainfall}mm'),
              _SummaryChip(label: '🌡 ${input.temperature}°C'),
              _SummaryChip(label: '💧 ${input.humidity}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  const _SummaryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.paleGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Tip Card ────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String tip;
  final Color color;

  const _TipCard({
    required this.emoji,
    required this.title,
    required this.tip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
