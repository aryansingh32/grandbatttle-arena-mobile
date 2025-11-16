// lib/components/banner_slider.dart
// STEP 4: Dynamic banner slider with admin panel integration

import 'package:carousel_slider/carousel_controller.dart' as ts;
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// STEP 4.1: Banner model for API integration
class BannerModel {
  final int id;
  final String imageUrl;
  final String? title;
  final String? description;
  final String? actionUrl; // YouTube link or external URL
  final String type; // 'image', 'video', 'ad'
  final int order;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.description,
    this.actionUrl,
    required this.type,
    required this.order,
    this.isActive = true,
    this.startDate,
    this.endDate,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int,
      imageUrl: json['imageUrl'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      actionUrl: json['actionUrl'] as String?,
      type: json['type'] as String? ?? 'image',
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : null,
    );
  }

  // Check if banner is currently valid
  bool get isValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    
    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }
    
    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }
    
    return true;
  }
}

// STEP 4.2: Add this to your ApiService
/*
class ApiService {
  // ... existing code ...
  
  static const String banners = '$_api/banners';
  
  static Future<List<BannerModel>> getActiveBanners() async {
    try {
      final response = await _get(banners, requireAuth: false);
      final data = _handleResponse(response) as List;
      
      final banners = data
          .map((json) => BannerModel.fromJson(json))
          .where((banner) => banner.isValid)
          .toList();
      
      // Sort by order
      banners.sort((a, b) => a.order.compareTo(b.order));
      
      return banners;
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
  }
}
*/

// STEP 4.3: Banner Slider Widget
class BannerSlider extends StatefulWidget {
  final double height;
  final Duration autoPlayInterval;
  final bool autoPlay;
  
  const BannerSlider({
    super.key,
    this.height = 200,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.autoPlay = true,
  });

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final ts.CarouselSliderController _carouselController = ts.CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _loadBanners();
    
    // STEP 4.4: Auto-refresh every 5 minutes for new banners
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        _loadBanners(silent: true);
        _startAutoRefresh();
      }
    });
  }

  // STEP 4.5: Load banners from API
  Future<void> _loadBanners({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      // TODO: Replace with actual API call
      // final banners = await ApiService.getActiveBanners();
      
      // TEMP: Mock data for demonstration
      final banners = _getMockBanners();
      
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading banners: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // STEP 4.6: Mock banners (remove when API is ready)
  List<BannerModel> _getMockBanners() {
    return [
      BannerModel(
        id: 1,
        imageUrl: 'assets/images/freefirebanner4.webp',
        title: 'Free Fire Tournament',
        description: 'Win big prizes!',
        type: 'image',
        order: 1,
      ),
      BannerModel(
        id: 2,
        imageUrl: 'assets/images/freefirebanner.webp',
        title: 'PUBG Championship',
        description: 'Join now!',
        actionUrl: 'https://youtube.com/watch?v=example',
        type: 'video',
        order: 2,
      ),
      BannerModel(
        id: 3,
        imageUrl: 'assets/images/freefirebanner4.webp',
        title: 'Special Offer',
        description: '50% off entry fees',
        type: 'ad',
        order: 3,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerLoader();
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // STEP 4.7: Carousel Slider
        cs.CarouselSlider.builder(
          itemCount: _banners.length,
          carouselController: _carouselController,
          options: cs.CarouselOptions(
            height: widget.height,
            viewportFraction: 0.9,
            autoPlay: widget.autoPlay,
            autoPlayInterval: widget.autoPlayInterval,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final banner = _banners[index];
            return _buildBannerCard(banner);
          },
        ),
        
        const SizedBox(height: 12),
        
        // STEP 4.8: Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _carouselController.animateToPage(entry.key),
              child: Container(
                width: _currentIndex == entry.key ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentIndex == entry.key
                      ? Appcolor.secondary
                      : Appcolor.grey.withOpacity(0.4),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 4.9: Build banner card
  Widget _buildBannerCard(BannerModel banner) {
    return GestureDetector(
      onTap: () => _handleBannerTap(banner),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // STEP 4.10: Banner image with caching
              _buildBannerImage(banner),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              
              // STEP 4.11: Banner info
              if (banner.title != null || banner.description != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (banner.title != null)
                        Text(
                          banner.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (banner.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          banner.description!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              
              // STEP 4.12: Type indicator
              Positioned(
                top: 12,
                right: 12,
                child: _buildTypeIndicator(banner.type),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 4.13: Build banner image (with network/asset support)
  Widget _buildBannerImage(BannerModel banner) {
    if (banner.imageUrl.startsWith('http')) {
      // Network image with caching
      return CachedNetworkImage(
        imageUrl: banner.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Appcolor.cardsColor,
          child: const Center(
            child: CircularProgressIndicator(color: Appcolor.secondary),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Appcolor.cardsColor,
          child: const Center(
            child: Icon(Icons.error, color: Colors.red, size: 40),
          ),
        ),
      );
    } else {
      // Asset image
      return Image.asset(
        banner.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Appcolor.cardsColor,
            child: const Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
            ),
          );
        },
      );
    }
  }

  // STEP 4.14: Type indicator badge
  Widget _buildTypeIndicator(String type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'video':
        icon = Icons.play_circle_filled;
        color = Colors.red;
        break;
      case 'ad':
        icon = Icons.local_offer;
        color = Colors.orange;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 4.15: Handle banner tap
  Future<void> _handleBannerTap(BannerModel banner) async {
    if (banner.actionUrl == null || banner.actionUrl!.isEmpty) {
      return;
    }

    try {
      final uri = Uri.parse(banner.actionUrl!);
      
      // Check if it's a YouTube link
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        await _launchYouTube(banner.actionUrl!);
      } else {
        await _launchUrl(banner.actionUrl!);
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: ${banner.actionUrl}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // STEP 4.16: Launch YouTube video
  Future<void> _launchYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch YouTube: $url';
    }
  }

  // Launch external URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch URL: $url';
    }
  }

  // STEP 4.17: Shimmer loader
  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Appcolor.cardsColor,
      highlightColor: Appcolor.cardsColor.withOpacity(0.5),
      child: Container(
        height: widget.height,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Appcolor.cardsColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}