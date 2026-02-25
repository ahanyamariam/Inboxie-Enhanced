import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/features/home/widgets/filter_tabs.dart';

class HeaderBanner extends StatelessWidget {
  final int selectedTabIndex;
  final bool isSearchActive;
  final TextEditingController searchController;
  final Function(int) onTabSelected;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  const HeaderBanner({
    super.key,
    required this.selectedTabIndex,
    required this.isSearchActive,
    required this.searchController,
    required this.onTabSelected,
    this.onSearchTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.getHeaderGradient(context),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Row: Logo + Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo or Search Bar
                      if (isSearchActive)
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              ),
                            ),
                            child: TextField(
                              controller: searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search emails...',
                                hintStyle: TextStyle(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.5),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  color: AppColors.primaryBlue,
                                  onPressed: onSearchTap, // Close search
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        // Logo
                        Row(
                          children: [
                            // Icon Container
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.accentYellow,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Wordmark
                            Row(
                              children: [
                                const Text(
                                  'Inb',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryBlue,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentYellow,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'xie',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Actions
                        Row(
                          children: [
                            // Search Toggle
                            GestureDetector(
                              onTap: onSearchTap,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Profile
                            GestureDetector(
                              onTap: onProfileTap,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.accentYellow,
                                      AppColors.waveYellowDark,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Filter Tabs
                FilterTabs(
                  selectedIndex: selectedTabIndex,
                  onTabSelected: onTabSelected,
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
