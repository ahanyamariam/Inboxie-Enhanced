import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showArrow = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconColor = isDestructive
        ? Colors.red
        : (iconColor ?? AppColors.primaryBlue);
    
    final Color effectiveIconBg = isDestructive
        ? Colors.red.withValues(alpha: 0.1)
        : (iconBackgroundColor ?? AppColors.primaryBlue.withValues(alpha: 0.1));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: effectiveIconColor,
                ),
              ),
              
              const SizedBox(width: 14),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive 
                            ? Colors.red 
                            : AppColors.getTextPrimary(context),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              if (trailing != null) trailing!,
              
              if (showArrow && trailing == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.getTextSecondary(context),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleTile({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primaryBlue,
      ),
      onTap: () => onChanged(!value),
    );
  }
}

class SettingsSelectorTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? subtitle;
  final String value;
  final VoidCallback onTap;

  const SettingsSelectorTile({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      title: title,
      subtitle: subtitle,
      showArrow: true,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.getTextSecondary(context),
            size: 22,
          ),
        ],
      ),
    );
  }
}

class SettingsCountTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? subtitle;
  final int count;
  final VoidCallback onTap;

  const SettingsCountTile({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      title: title,
      subtitle: subtitle,
      showArrow: true,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.getTextSecondary(context),
            size: 22,
          ),
        ],
      ),
    );
  }
}