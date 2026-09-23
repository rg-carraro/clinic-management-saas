import 'package:flutter/material.dart';

import 'app_theme.dart';

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: AppBrand.gradient,
      borderRadius: BorderRadius.circular(size * .3),
    ),
    child: Icon(Icons.spa_outlined, color: Colors.white, size: size * .55),
  );
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionHeading(this.title, {super.key, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text,
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            if (action != null) ...[const SizedBox(width: 24), action!],
          ],
        );
      },
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyPanel(this.message, {super.key, this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppBrand.radius),
      border: Border.all(color: AppBrand.line),
    ),
    child: Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppBrand.pale,
          child: Icon(icon, color: AppBrand.blue),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class StatusBadge extends StatelessWidget {
  final String label;
  const StatusBadge(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppBrand.pale,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(color: AppBrand.navy, fontWeight: FontWeight.w600),
    ),
  );
}
