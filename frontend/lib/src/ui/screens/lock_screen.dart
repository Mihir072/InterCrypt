import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../theme/app_theme.dart';

/// Lock Screen — Stitch cyberpunk session lock
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _passwordController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late BiometricService _biometricService;

  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _biometricService = BiometricService(ref.read(secureStorageProvider));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    _checkBiometric();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() => _isBiometricAvailable = isAvailable && isEnabled);
    }
  }

  Future<void> _handleUnlock() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Enter vault key to proceed');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final authNotifier = ref.read(authProvider.notifier);
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Session expired. Re-authentication required.';
      });
      await authNotifier.logout();
      if (mounted) context.go('/login');
      return;
    }
    await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
        context.pop();
      }
  }

  Future<void> _handleBiometricUnlock() async {
    try {
      final authenticated = await _biometricService.authenticate(
        reason: 'Unlock IntelCrypt',
      );
      if (authenticated && mounted) {
        context.pop();
        context.pop();
      }
    } on BiometricException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Biometric unlock failed');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminate Session'),
        content: const Text(
          'You will be logged out and all local data will remain encrypted. Re-authentication will be required.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.electricCyan.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lock icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.backgroundDeep,
                            ],
                          ),
                          border: Border.all(
                            color: AppTheme.electricCyan.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.electricCyan.withOpacity(0.12),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 44,
                          color: AppTheme.electricCyan,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        'Vault Locked',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentUser != null
                            ? 'Welcome back, ${currentUser.username}'
                            : 'SESSION SECURED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.electricCyan.withOpacity(0.6),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Error
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.errorRed.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppTheme.errorRed, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.errorRed,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Password field
                      Text(
                        'VAULT KEY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.5),
                          ),
                          color: AppTheme.backgroundDeep.withOpacity(0.5),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          enabled: !_isLoading,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter vault key',
                            hintStyle: TextStyle(color: AppTheme.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                  () => _showPassword = !_showPassword),
                              child: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                            ),
                          ),
                          onChanged: (v) {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Unlock button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleUnlock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.electricCyan,
                            foregroundColor: AppTheme.backgroundDeep,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.backgroundDeep,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'DECRYPT & UNLOCK',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.lock_open, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Biometric
                      if (_isBiometricAvailable)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isLoading ? null : _handleBiometricUnlock,
                            icon: const Icon(Icons.fingerprint, size: 24),
                            label: const Text(
                              'BIOMETRIC UNLOCK',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.electricCyan,
                              side: BorderSide(
                                color:
                                    AppTheme.electricCyan.withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Logout
                      TextButton.icon(
                        onPressed: _isLoading ? null : _handleLogout,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Terminate Session'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorRed.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Security info
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                          ),
                          color: AppTheme.primaryBlue.withOpacity(0.08),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppTheme.electricCyan.withOpacity(0.5),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your vault was locked for security. All data remains encrypted at rest.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
