import 'package:flutter/material.dart';
import 'package:grand_battle_arena/items/circularavatar.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class LeaderBoardProfile extends StatelessWidget {
  final int rank;
  final bool isFirst;
  final String name;
  final String coins;
  final String matchInfo;
  final String imageLink;
  final String gameIcon;

  const LeaderBoardProfile({
    super.key,
    this.rank = 1,
    this.name = 'Jhonny Sins',
    this.coins = '4200',
    this.matchInfo = '40+ Matches',
    this.imageLink = 'assets/images/jhonny.webp',
    this.gameIcon = 'assets/images/garenalogo.png',
  }) : isFirst = rank == 1;


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 71,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Appcolor.cardsColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isFirst
              ? Image.asset('assets/icons/first.png', width: 25)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "$rank",
                    style: const TextStyle(
                   
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: CircularProfile(
              imageLink: imageLink,
              navigationLocation: '#',
              // size: 40,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style:  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
            
                    color: const Color.fromARGB(255, 224, 224, 224),
                  ),
                ),
                Row(
                  children: [
                    Image.asset(gameIcon, width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(
                      matchInfo,
                      style: TextStyle(
                        color: Colors.white60,
                       
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 5),
          Image.asset(
            'assets/icons/dollar.png', // silver coin icon
            width: 18,
            height: 18,
          ),
          const SizedBox(width: 4),
          Text(
            coins,
            style: const TextStyle(
             
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF9CB35),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
