import 'package:flutter/material.dart';
import 'package:grand_battle_arena/components/navigatorbar.dart';
import 'package:grand_battle_arena/pages/home.dart';
import 'package:grand_battle_arena/pages/tournament.dart';
import 'package:grand_battle_arena/pages/wallet.dart';

class MainContainer extends StatefulWidget {
 
  final int currentIndex;  
  
  const MainContainer({  
    super.key,
    this.currentIndex = 0,
  });

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    print('MainContainer initState called'); // Debug log
    _currentIndex = widget.currentIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    Home(),
    TournamentContent(),
    Wallet(),
  ];

  @override
  Widget build(BuildContext context) {
    // print('MainContainer build called - currentIndex: $_currentIndex'); // Debug log
    
    return Scaffold(
      backgroundColor: const Color.fromRGBO(9, 11, 14, 1),
      body: Stack(
        children: [
          // Using IndexedStack to keep pages alive and prevent rebuilding
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavigatorBar(
              currentIndex: _currentIndex,
              onPageChanged: _onPageChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}