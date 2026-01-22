import 'package:flutter/material.dart';

/// Password Strength Indicator Widget
/// Displays visual feedback for password strength with color coding
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showRequirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  @override
  Widget build(BuildContext context) {
    final strength = _calculatePasswordStrength(password);
    final requirements = _getPasswordRequirements(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength.value,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strength.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: strength.color,
              ),
            ),
          ],
        ),

        // Requirements checklist
        if (showRequirements && password.isNotEmpty) ...[
          const SizedBox(height: 12),
          _RequirementItem(
            label: 'At least 8 characters',
            isMet: requirements['minLength'] ?? false,
          ),
          _RequirementItem(
            label: 'Contains uppercase letter',
            isMet: requirements['hasUppercase'] ?? false,
          ),
          _RequirementItem(
            label: 'Contains lowercase letter',
            isMet: requirements['hasLowercase'] ?? false,
          ),
          _RequirementItem(
            label: 'Contains number',
            isMet: requirements['hasNumber'] ?? false,
          ),
          _RequirementItem(
            label: 'Contains special character',
            isMet: requirements['hasSpecialChar'] ?? false,
          ),
        ],
      ],
    );
  }

  /// Calculate password strength
  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return const PasswordStrength(
        value: 0.0,
        label: 'No Password',
        color: Colors.grey,
      );
    }

    int score = 0;
    final requirements = _getPasswordRequirements(password);

    // Score based on requirements met
    if (requirements['minLength'] ?? false) score += 20;
    if (requirements['hasUppercase'] ?? false) score += 20;
    if (requirements['hasLowercase'] ?? false) score += 20;
    if (requirements['hasNumber'] ?? false) score += 20;
    if (requirements['hasSpecialChar'] ?? false) score += 20;

    // Bonus for length
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;

    // Penalty for common patterns
    if (_hasCommonPattern(password)) score -= 20;

    // Normalize score
    score = score.clamp(0, 100);

    // Determine strength level
    if (score < 30) {
      return const PasswordStrength(
        value: 0.25,
        label: 'Weak',
        color: Colors.red,
      );
    } else if (score < 50) {
      return const PasswordStrength(
        value: 0.5,
        label: 'Fair',
        color: Colors.orange,
      );
    } else if (score < 75) {
      return const PasswordStrength(
        value: 0.75,
        label: 'Good',
        color: Colors.amber,
      );
    } else {
      return const PasswordStrength(
        value: 1.0,
        label: 'Strong',
        color: Colors.green,
      );
    }
  }

  /// Get password requirements status
  Map<String, bool> _getPasswordRequirements(String password) {
    return {
      'minLength': password.length >= 8,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasNumber': password.contains(RegExp(r'[0-9]')),
      'hasSpecialChar': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  /// Check for common password patterns
  bool _hasCommonPattern(String password) {
    final lowerPassword = password.toLowerCase();

    // Common patterns
    final commonPatterns = [
      'password',
      '123456',
      'qwerty',
      'abc123',
      'letmein',
      'welcome',
      'admin',
      'user',
    ];

    for (final pattern in commonPatterns) {
      if (lowerPassword.contains(pattern)) return true;
    }

    // Sequential characters
    if (RegExp(
      r'(abc|bcd|cde|123|234|345|456|567|678|789)',
    ).hasMatch(lowerPassword)) {
      return true;
    }

    // Repeating characters
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      return true;
    }

    return false;
  }
}

/// Requirement item widget
class _RequirementItem extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RequirementItem({required this.label, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isMet
                  ? Colors.green.shade700
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Password strength data class
class PasswordStrength {
  final double value;
  final String label;
  final Color color;

  const PasswordStrength({
    required this.value,
    required this.label,
    required this.color,
  });
}
