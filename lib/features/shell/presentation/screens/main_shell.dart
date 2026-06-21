import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../account/presentation/screens/mine_screen.dart';

/// KeeTa MainTabActivity equivalent — 4 tabs (Home / Search / Orders / Mine) over
/// an [IndexedStack] so each tab keeps its scroll + state. The Orders tab carries
/// a cart-count badge fed by the global [CartCubit].
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  static const _tabs = [
    HomeScreen(),
    SearchScreen(),
    OrdersScreen(),
    MineScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _KeetaBottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _KeetaBottomNav extends StatelessWidget {
  const _KeetaBottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final cartQty = context.watch<CartCubit>().state.totalQty;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: index == 0,
                  onTap: () => onTap(0)),
              _NavItem(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  selected: index == 1,
                  onTap: () => onTap(1)),
              _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  selected: index == 2,
                  badge: cartQty,
                  onTap: () => onTap(2)),
              _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Mine',
                  selected: index == 3,
                  onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryText : AppColors.tertiaryText;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: color),
                if (badge > 0)
                  PositionedDirectional(
                    end: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(
                          color: AppColors.finalPrice, shape: BoxShape.circle),
                      child: Text('$badge',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: AppTextStyles.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.captionSmall.copyWith(
                    color: color,
                    fontWeight:
                        selected ? AppTextStyles.bold : AppTextStyles.regular)),
          ],
        ),
      ),
    );
  }
}
