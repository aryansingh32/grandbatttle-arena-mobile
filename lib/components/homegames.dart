import 'package:flutter/material.dart';
import 'package:grand_battle_arena/items/circularavatar.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class Homegames extends StatelessWidget {
  const Homegames({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: const Text(
            "Games",
            style: TextStyle(
              
              fontWeight: FontWeight.w400,
              fontSize: 25,
              letterSpacing: 1,
              color: Appcolor.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16,right: 16,top: 8,bottom: 20),
          child: Row(
            children: [
              CircularProfile(
                navigationLocation: '/tournament',
                imageLink: 'assets/images/freefire.webp',
                iconText: 'Free Fire',
              ),
              SizedBox(width: 10),
              CircularProfile(
                navigationLocation: '/tournament',
                imageLink: 'assets/images/pubg.webp',
                iconText: 'Pubg',
              ),
              SizedBox(width: 10),
              CircularProfile(
                navigationLocation: '/tournament',
                imageLink: 'assets/images/cod.webp',
                iconText: 'Call Of Duty',
              ),
              SizedBox(width: 20),
              Text(
                "More Coming Soon...",
                style: TextStyle(
                
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                  letterSpacing: 1,
                  color: Appcolor.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
