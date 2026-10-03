class ProviderPreview {
  const ProviderPreview({
    required this.name,
    required this.imageUrl,
  });

  final String name;
  final String imageUrl;
}

class ServicePreview {
  const ServicePreview({
    required this.category,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.icon,
  });

  final String category;
  final String title;
  final String description;
  final String imageUrl;
  final String icon;
}

const customerProviders = [
  ProviderPreview(
    name: 'Dilan',
    imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=240&q=80',
  ),
  ProviderPreview(
    name: 'Kasun',
    imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=240&q=80',
  ),
  ProviderPreview(
    name: 'Kavindu',
    imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=240&q=80',
  ),
  ProviderPreview(
    name: 'Shehan',
    imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=240&q=80',
  ),
];

const customerServices = [
  ServicePreview(
    category: 'Cleaning',
    title: 'Cleaner',
    description: 'Deep home cleaning • Move-in ready',
    imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=900&q=80',
    icon: 'cleaning',
  ),
  ServicePreview(
    category: 'Carpentry',
    title: 'Carpenter',
    description: 'Furniture assembly • Custom shelving',
    imageUrl: 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=900&q=80',
    icon: 'carpentry',
  ),
];
