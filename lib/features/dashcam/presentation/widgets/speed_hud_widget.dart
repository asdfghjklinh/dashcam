import 'package:flutter/material.dart';

class SpeedHudWidget extends StatelessWidget {
  final double speedKmH;
  final double totalDistanceM;
  final bool isPortrait;

  const SpeedHudWidget({
    super.key,
    required this.speedKmH,
    required this.totalDistanceM,
    required this.isPortrait,
  });

  @override
  Widget build(BuildContext context) {
    final double distanceKm = totalDistanceM / 1000;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisSize: isPortrait ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Khối hiển thị Tốc độ (Km/h)
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.cyanAccent, size: 28),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Đã sửa tên tham số chính xác
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    speedKmH.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'KM/H',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          if (isPortrait)
            const SizedBox(
              height: 30,
              child: VerticalDivider(color: Colors.white24),
            ),
          if (!isPortrait) const SizedBox(width: 16),

          // 2. Khối hiển thị Quãng đường (Km)
          Row(
            children: [
              const Icon(Icons.map_outlined, color: Colors.orangeAccent, size: 26),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Đã sửa tên tham số chính xác
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    distanceKm.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'QUÃNG ĐƯỜNG (KM)',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}