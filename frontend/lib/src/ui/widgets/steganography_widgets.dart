import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SteganographyOptionSheet extends StatefulWidget {
  final String fileName;
  final Function(String secretMessage) onProcess;

  const SteganographyOptionSheet({
    super.key,
    required this.fileName,
    required this.onProcess,
  });

  @override
  State<SteganographyOptionSheet> createState() => _SteganographyOptionSheetState();
}

class _SteganographyOptionSheetState extends State<SteganographyOptionSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isEmbedding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.enhanced_encryption, color: AppTheme.electricCyan, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Steganography Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hide a secret message inside ${widget.fileName}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter secret message...',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.primaryBlue.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.electricCyan, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_controller.text.trim().isEmpty || _isEmbedding)
                ? null
                : () async {
                    setState(() => _isEmbedding = true);
                    await widget.onProcess(_controller.text.trim());
                    if (mounted) Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCyan,
              foregroundColor: AppTheme.backgroundDeep,
              disabledBackgroundColor: AppTheme.electricCyan.withOpacity(0.1),
              disabledForegroundColor: AppTheme.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isEmbedding
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.backgroundDeep),
                  )
                : const Text('Embed & Send', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class ExtractMessageDialog extends StatelessWidget {
  final String secretMessage;

  const ExtractMessageDialog({super.key, required this.secretMessage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.vpn_key_rounded, size: 48, color: AppTheme.electricCyan),
            const SizedBox(height: 16),
            const Text(
              'Extracted Message',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  secretMessage,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),

            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class HiddenDataIndicator extends StatelessWidget {
  const HiddenDataIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.electricCyan.withOpacity(0.5), width: 0.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 10, color: AppTheme.electricCyan),
          SizedBox(width: 4),
          Text(
            'HIDDEN DATA',
            style: TextStyle(
              color: AppTheme.electricCyan,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
