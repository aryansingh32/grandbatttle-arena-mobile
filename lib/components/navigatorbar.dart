import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:grand_battle_arena/theme/appcolor.dart';

class NavigatorBar extends StatefulWidget {
  final Function(int)? onPageChanged;
  final int currentIndex; // Accept current index from parent
  
  const NavigatorBar({
    super.key, 
    this.onPageChanged,
    this.currentIndex = 0, // Default to 0
  });

  @override
  State<NavigatorBar> createState() => _NavigatorBarState();
}

class _NavigatorBarState extends State<NavigatorBar> {
  late int _selectedPageIndex;

  List<IconData> icons = [
    Icons.home,
    Icons.sports_esports,
    Icons.account_balance_wallet,
  ];

  // If you want to use image assets instead:
  List<String> imgIconPaths = [
    "assets/icons/home.png",
    "assets/icons/vs.png", 
    "assets/icons/wallet.png"
  ];

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(NavigatorBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected index when parent changes currentIndex
    if (widget.currentIndex != oldWidget.currentIndex) {
      setState(() {
        _selectedPageIndex = widget.currentIndex;
      });
    }
  }

  void onIconTap(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
    // Callback to parent widget
    widget.onPageChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            // Reduced blur for better performance
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Appcolor.primary.withOpacity(0.85), // Slightly more opaque
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1), // Reduced opacity
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10, // Reduced blur radius
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(icons.length, (index) {
                  bool isSelected = _selectedPageIndex == index;
                  return GestureDetector(
                    onTap: () => onIconTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200), // Faster animation
                      curve: Curves.easeInOut,
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Appcolor.white.withOpacity(0.9)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Appcolor.white.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icons[index],
                        color: isSelected ? Appcolor.primary : Appcolor.white,
                        size: 24,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}