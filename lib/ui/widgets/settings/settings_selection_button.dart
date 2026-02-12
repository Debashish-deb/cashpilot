import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SettingsSelectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showLock;

  const SettingsSelectionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.showLock = false,
  });

  @override
  Widget build(BuildContext context) {
    // We don't have ref here, convert to ConsumerWidget if needed or just use Theme
    // It is a StatelessWidget, so we use Theme.of(context)
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Colors based on selection and theme
    // Electric switch style: High contrast active state (Monochrome), clean inactive
    final activeColor = isDark ? Colors.white : Colors.black;
    
    // Active background: Removed as per request, using side bar only
    final activeBg = Colors.transparent; 
    // Inactive: Transparent or very subtle surface
    final inactiveBg = Colors.transparent; 

    final textColor = isSelected 
        ? activeColor 
        : (isDark ? Colors.white : Colors.black); // Full contrast for inactive too
        
    final iconColor = isSelected 
        ? activeColor 
        : (isDark ? Colors.white : Colors.black);

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), // More compact
                decoration: BoxDecoration(
                  color: inactiveBg, // Always transparent/inactive background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: iconColor,
                        size: 20, // Reduced icon
                      ),
                      const SizedBox(height: 2), // More compact spacing
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: textColor,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 10, // Reduced font
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          if (isSelected)
            Positioned(
              left: 4,
              top: 12,
              bottom: 12,
              width: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                     BoxShadow(color: activeColor.withOpacity(0.6), blurRadius: 4),
                  ],
                ),
              ),
            ),
          
          if (showLock)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.lock,
                size: 10,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
        ],
      ),
    );
  }
}
