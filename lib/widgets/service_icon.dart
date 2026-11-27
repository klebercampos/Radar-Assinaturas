import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class ServiceIcon extends StatelessWidget {
  const ServiceIcon({
    super.key,
    required this.iconKey,
    this.size = 44,
  });

  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color bg) = _resolve(iconKey);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: bg, size: size * 0.48),
    );
  }

  (IconData, Color) _resolve(String key) {
    switch (key) {
      case 'netflix':
        return (Icons.movie_outlined, const Color(0xFFE50914));
      case 'spotify':
        return (Icons.music_note_rounded, const Color(0xFF1DB954));
      case 'amazon':
        return (Icons.local_shipping_outlined, const Color(0xFFFF9900));
      case 'chatgpt':
        return (Icons.smart_toy_outlined, AppColors.primaryAlt);
      case 'cloud':
        return (Icons.cloud_outlined, AppColors.primary);
      case 'adobe':
        return (Icons.brush_outlined, const Color(0xFFED1C24));
      case 'fitness':
        return (Icons.fitness_center, AppColors.alert);
      default:
        return (Icons.subscriptions_outlined, AppColors.primary);
    }
  }
}
