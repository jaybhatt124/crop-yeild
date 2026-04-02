import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/crop_input.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/prediction_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../prediction/prediction_result_screen.dart';

/// Screen for entering crop parameters and triggering yield prediction.
class CropDataScreen extends StatefulWidget {
  const CropDataScreen({super.key});

  @override
  State<CropDataScreen> createState() => _CropDataScreenState();
}

class _CropDataScreenState extends State<CropDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rainfallCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _humidityCtrl = TextEditingController();

  String? _location;
  String? _soilType;
  String? _cropType;
  bool _isLoading = false;
  String? _error;

  final _firestoreService = FirestoreService();
  final _predictionService = PredictionService();

  @override
  void dispose() {
    _rainfallCtrl.dispose();
    _tempCtrl.dispose();
    _humidityCtrl.dispose();
    super.dispose();
  }

  Future<void> _predictYield() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null || _soilType == null || _cropType == null) {
      setState(() => _error = 'Please fill in all dropdown fields.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId =
          context.read<AuthService>().currentUser?.uid ?? 'anonymous';

      // ── Get prediction from service ──────────────────────────
      final result = await _predictionService.predictYield(
        cropType: _cropType!,
        soilType: _soilType!,
        location: _location!,
        rainfall: double.parse(_rainfallCtrl.text),
        temperature: double.parse(_tempCtrl.text),
        humidity: double.parse(_humidityCtrl.text),
      );

      // ── Save to Firestore ────────────────────────────────────
      final input = CropInput(
        userId: userId,
        location: _location!,
        soilType: _soilType!,
        cropType: _cropType!,
        rainfall: double.parse(_rainfallCtrl.text),
        temperature: double.parse(_tempCtrl.text),
        humidity: double.parse(_humidityCtrl.text),
        timestamp: DateTime.now(),
        predictedYield: result.yieldValue,
        suggestedCrop: result.suggestedCrop,
      );

      await _firestoreService.saveCropInput(input);

      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                PredictionResultScreen(result: result, cropInput: input),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: '🤖 Analyzing crop data...',
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AppTheme.primaryGreen,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🌾 Crop Data Entry',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Fill in your field details to get yield prediction',
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
            ),

            // ── Form ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section: Location ──────────────────
                      _sectionLabel('📍 Location Details'),
                      const SizedBox(height: 12),
                      CustomDropdown(
                        label: 'State / Region',
                        value: _location,
                        items: AppConstants.locations,
                        prefixIcon: Icons.location_on_outlined,
                        onChanged: (v) => setState(() => _location = v),
                        validator: (v) =>
                            v == null ? 'Please select a location' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomDropdown(
                        label: 'Soil Type',
                        value: _soilType,
                        items: AppConstants.soilTypes,
                        prefixIcon: Icons.layers_outlined,
                        onChanged: (v) => setState(() => _soilType = v),
                        validator: (v) =>
                            v == null ? 'Please select soil type' : null,
                      ),

                      const SizedBox(height: 28),

                      // ── Section: Crop ──────────────────────
                      _sectionLabel('🌱 Crop Details'),
                      const SizedBox(height: 12),
                      CustomDropdown(
                        label: 'Crop Type',
                        value: _cropType,
                        items: AppConstants.cropTypes,
                        prefixIcon: Icons.eco_outlined,
                        onChanged: (v) => setState(() => _cropType = v),
                        validator: (v) =>
                            v == null ? 'Please select crop type' : null,
                      ),

                      const SizedBox(height: 28),

                      // ── Section: Environmental ─────────────
                      _sectionLabel('🌦 Environmental Parameters'),
                      const SizedBox(height: 12),

                      // Rainfall
                      CustomTextField(
                        label: 'Annual Rainfall (mm)',
                        hint: 'e.g. 750',
                        controller: _rainfallCtrl,
                        prefixIcon: Icons.water_drop_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val < 0 || val > 5000) {
                            return 'Enter a valid rainfall (0-5000 mm)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Temperature
                      CustomTextField(
                        label: 'Average Temperature (°C)',
                        hint: 'e.g. 25',
                        controller: _tempCtrl,
                        prefixIcon: Icons.thermostat_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val < -20 || val > 60) {
                            return 'Enter a valid temperature (-20 to 60°C)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Humidity
                      CustomTextField(
                        label: 'Average Humidity (%)',
                        hint: 'e.g. 65',
                        controller: _humidityCtrl,
                        prefixIcon: Icons.water_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val < 0 || val > 100) {
                            return 'Enter a valid humidity (0-100%)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // ── Error Message ──────────────────────
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.red.shade600, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Predict Button ─────────────────────
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _predictYield,
                          icon: const Text('🤖', style: TextStyle(fontSize: 20)),
                          label: Text(
                            'Predict Yield',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Note ───────────────────────────────
                      Center(
                        child: Text(
                          '📡 Data will be saved to Firestore automatically',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }
}
