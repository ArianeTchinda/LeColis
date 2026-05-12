import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:rive/rive.dart';
import '../../../core/constants/app_colors.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  bool _isExpanded = false;

  static const _items = [
    _NavItemData(artboard: 'HOME', stateMachine: 'HOME_interactivity', label: 'Publications'),
    _NavItemData(artboard: 'BELL', stateMachine: 'BELL_Interactivity', label: 'Abonnements'),
    _NavItemData(artboard: 'USER', stateMachine: 'USER_Interactivity', label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1200) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: _isExpanded ? 260 : 80, // Largeur stable
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Bouton Hamburger
            IconButton(
              icon: Icon(
                _isExpanded ? Icons.menu_open : Icons.menu,
                color: AppColors.textPrimary,
              ),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RailItem(
                    data: _items[i],
                    isSelected: widget.currentIndex == i,
                    onTap: () => widget.onTap(i),
                    isExpanded: _isExpanded,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _MobileBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      items: _items,
    );
  }
}

class _RailItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isExpanded;

  const _RailItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack( // Utilisation d'un Stack pour éviter que le texte ne pousse l'icône
          children: [
            // L'icône : Toujours centrée par rapport à la largeur réduite (80px - padding)
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 56, // Largeur fixe égale à la hauteur pour faire un carré
                child: Center(
                  child: _RiveNavIcon(
                    key: ValueKey(data.artboard),
                    artboard: data.artboard,
                    stateMachine: data.stateMachine,
                    isSelected: isSelected,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Le Texte : On utilise Positioned pour qu'il "flotte" à côté de l'icône
            Positioned(
              left: 56,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isExpanded ? 1.0 : 0.0,
                child: Center(
                  child: Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// RIVE ICON (Stable)
// ─────────────────────────────────────────────────────────
class _RiveNavIcon extends StatefulWidget {
  final String artboard;
  final String stateMachine;
  final bool isSelected;
  final double size;

  const _RiveNavIcon({
    super.key,
    required this.artboard,
    required this.stateMachine,
    required this.isSelected,
    required this.size,
  });

  @override
  State<_RiveNavIcon> createState() => _RiveNavIconState();
}

class _RiveNavIconState extends State<_RiveNavIcon> {
  SMIBool? _active;

  void _onRiveInit(Artboard ab) {
    final ctrl = StateMachineController.fromArtboard(ab, widget.stateMachine);
    if (ctrl == null) return;
    ab.addController(ctrl);
    _active = ctrl.findInput<bool>('active') as SMIBool?;
    if (_active != null) _active!.value = widget.isSelected;
  }

  @override
  void didUpdateWidget(covariant _RiveNavIcon old) {
    super.didUpdateWidget(old);
    if (old.isSelected != widget.isSelected) {
      _active?.value = widget.isSelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RiveAnimation.asset(
        'assets/rive/animated-icon-set-1-color.riv',
        artboard: widget.artboard,
        fit: BoxFit.contain,
        onInit: _onRiveInit,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// MOBILE BAR (Stable)
// ─────────────────────────────────────────────────────────
class _MobileBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<_NavItemData> items;

  const _MobileBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withOpacity(0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.primaryPink.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                items.length,
                (i) => _MobileNavItem(
                  data: items[i],
                  isSelected: currentIndex == i,
                  onTap: () => onTap(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RiveNavIcon(
            artboard: data.artboard,
            stateMachine: data.stateMachine,
            isSelected: isSelected,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primaryPinkSoft : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final String artboard;
  final String stateMachine;
  final String label;

  const _NavItemData({
    required this.artboard,
    required this.stateMachine,
    required this.label,
  });
}