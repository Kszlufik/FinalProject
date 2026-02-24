import 'package:flutter/material.dart';

class LeftPanel extends StatelessWidget {
  const LeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Categories / Links',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Action'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('RPG'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Indie'),
              onTap: () {},
            ),
            // Add more links here
          ],
        ),
      ),
    );
  }
}
