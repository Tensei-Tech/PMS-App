import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final String? logoUrl;

  const AppLogo({
    super.key,
    this.size = 80,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.trim().isNotEmpty && logoUrl!.startsWith('http')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            logoUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultLogo(),
          ),
        ),
      );
    }
    return _buildDefaultLogo();
  }

  Widget _buildDefaultLogo() {
    return Icon(Icons.shield, size: size, color: const Color(0xFF1A3A6B));
  }
}
