import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _icons = [
    'assets/figma/nav-tasks.svg',
    'assets/figma/nav-focus.svg',
    'assets/figma/nav-calendar.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: constraints.maxWidth < 232 ? constraints.maxWidth : 232,
        height: 43,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.navBarBackground,
          borderRadius: BorderRadius.circular(200),
          border: Border.all(color: const Color(0xFFE3E3E8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_icons.length, (index) {
            final selected = currentIndex == index;
            return Semantics(
              button: true,
              selected: selected,
              label: ['Tugas', 'Fokus', 'Kalender'][index],
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 35,
                  height: 29,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.navBarActive
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    _icons[index],
                    width: 12,
                    height: index == 2 ? 14.5 : 12,
                    colorFilter: ColorFilter.mode(
                      selected ? Colors.white : AppColors.navBarInactive,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
