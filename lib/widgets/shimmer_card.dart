import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[800]!, // Colore di base scuro
        highlightColor: Colors.grey[600]!, // Il riflesso di luce che scorre
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          title: Container(
            height: 16,
            width: double.infinity,
            color: Colors.white,
          ),
          subtitle: Container(
            height: 12,
            width: 100,
            color: Colors.white,
            margin: const EdgeInsets.only(top: 8),
          ),
          trailing: Container(
            width: 60,
            height: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}