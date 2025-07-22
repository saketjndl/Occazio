import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String? items;
  final IconData icon;
  final Color color; // Keep the specific color for the icon/accent
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    this.items,
    required this.icon,
    required this.color, // Keep this for the distinct category look
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme data
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine appropriate background and text colors based on theme
    final cardBackgroundColor = theme.cardColor; // Use theme's card background
    final titleColor = colorScheme.onSurface; // Use theme's primary text color for surfaces
    final itemsColor = colorScheme.onSurface.withOpacity(0.7); // Use theme's secondary text color

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // --- Use themed background ---
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [ // Keep subtle shadow, maybe adjust color based on theme
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
          // Optional: Add subtle border in dark mode if needed for definition
          // border: isDarkMode ? Border.all(color: Colors.grey.shade700, width: 0.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // --- Use the category color with less opacity ---
                color: color.withOpacity(0.15), // Slightly more opaque for visibility? Test this.
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color, // Use the passed-in category color for the icon itself
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text( // Title text
              title,
              style: theme.textTheme.titleMedium?.copyWith( // Use theme text style
                fontWeight: FontWeight.bold,
                color: titleColor, // Use determined title color
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (items != null && items!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                items!,
                style: theme.textTheme.bodySmall?.copyWith( // Use theme text style
                  color: itemsColor, // Use determined items color
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}