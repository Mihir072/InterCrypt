import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../../services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationPickerModal extends ConsumerStatefulWidget {
  final Function(double lat, double lon, double radius, String? label) onSave;

  const LocationPickerModal({super.key, required this.onSave});

  @override
  ConsumerState<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends ConsumerState<LocationPickerModal> {
  LatLng? _selectedLocation;
  double _radius = 500.0;
  final TextEditingController _labelController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    final pos = await ref.read(locationServiceProvider).getCurrentLocation();
    if (pos != null) {
      setState(() {
        _selectedLocation = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCyan))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.electricCyan),
                    const SizedBox(width: 12),
                    const Text(
                      'Location Restriction',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Map
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation ?? const LatLng(0, 0),
                        zoom: 15,
                      ),
                      onTap: (pos) => setState(() => _selectedLocation = pos),
                      markers: _selectedLocation == null ? {} : {
                        Marker(
                          markerId: const MarkerId('selected'),
                          position: _selectedLocation!,
                        ),
                      },
                      circles: _selectedLocation == null ? {} : {
                        Circle(
                          circleId: const CircleId('radius'),
                          center: _selectedLocation!,
                          radius: _radius,
                          fillColor: AppTheme.electricCyan.withOpacity(0.2),
                          strokeColor: AppTheme.electricCyan,
                          strokeWidth: 2,
                        ),
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapToolbarEnabled: false,
                    ),
                    if (_selectedLocation == null)
                      const Center(
                        child: Card(
                          color: AppTheme.surfaceDark,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Tap map to select location', style: TextStyle(color: AppTheme.textPrimary)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Radius Slider
                    Row(
                      children: [
                        const Text('Radius:', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: _radius,
                            min: 100,
                            max: 5000,
                            divisions: 49,
                            activeColor: AppTheme.electricCyan,
                            onChanged: (v) => setState(() => _radius = v),
                          ),
                        ),
                        Text('${_radius.round()}m', style: const TextStyle(color: AppTheme.electricCyan, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Label
                    TextField(
                      controller: _labelController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Location Name (e.g. Headquarters)',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.label_outline, color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.primaryBlue.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedLocation == null 
                          ? null 
                          : () {
                              widget.onSave(
                                _selectedLocation!.latitude,
                                _selectedLocation!.longitude,
                                _radius,
                                _labelController.text.isEmpty ? null : _labelController.text,
                              );
                              Navigator.pop(context);
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCyan,
                          foregroundColor: AppTheme.backgroundDeep,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirm Restriction', style: TextStyle(fontWeight: FontWeight.bold)),
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

class RestrictedContentWarning extends StatelessWidget {
  final String? locationName;
  final double radius;
  final double? currentDistance;
  final VoidCallback onRefresh;

  const RestrictedContentWarning({
    super.key,
    this.locationName,
    required this.radius,
    this.currentDistance,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_disabled_rounded, size: 48, color: AppTheme.errorRed),
            ),
            const SizedBox(height: 20),
            const Text(
              'Access Restricted',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'This content is geofenced. You must be within ${radius.round()}m of ${locationName ?? "the authorized location"} to view it.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            if (currentDistance != null) ...[
              const SizedBox(height: 16),
              Text(
                'Current distance: ${(currentDistance! / 1000).toStringAsFixed(2)} km',
                style: const TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: AppTheme.backgroundDeep,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Refresh Location', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
