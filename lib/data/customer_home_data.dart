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
