import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.rating,
    this.isPopular = false,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String imageUrl;
  final double rating;
  final bool isPopular;
  final bool isAvailable;

  MenuItem copyWith({
    String? name,
    String? description,
    String? category,
    double? price,
    String? imageUrl,
    double? rating,
    bool? isPopular,
    bool? isAvailable,
  }) => MenuItem(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    price: price ?? this.price,
    imageUrl: imageUrl ?? this.imageUrl,
    rating: rating ?? this.rating,
    isPopular: isPopular ?? this.isPopular,
    isAvailable: isAvailable ?? this.isAvailable,
  );

  Map<String, Object?> toFirestore() => {
    'name': name,
    'description': description,
    'category': category,
    'price': price,
    'imageUrl': imageUrl,
    'rating': rating,
    'isPopular': isPopular,
    'isAvailable': isAvailable,
    'deleted': false,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory MenuItem.fromFirestore(String id, Map<String, dynamic> data) =>
      MenuItem(
        id: id,
        name: data['name']?.toString() ?? 'Untitled dish',
        description: data['description']?.toString() ?? '',
        category: data['category']?.toString() ?? 'Other',
        price: (data['price'] as num?)?.toDouble() ?? 0,
        imageUrl: data['imageUrl']?.toString() ?? '',
        rating: (data['rating'] as num?)?.toDouble() ?? 5,
        isPopular: data['isPopular'] == true,
        isAvailable: data['isAvailable'] != false,
      );

  static const samples = <MenuItem>[
    MenuItem(
      id: 'wood-fired-pizza',
      name: 'Wood-fired Margherita',
      description: 'San Marzano tomato, fior di latte, basil, olive oil',
      category: 'Pizza',
      price: 18.50,
      rating: 4.9,
      isPopular: true,
      imageUrl:
          'https://images.unsplash.com/photo-1579751626657-72bc17010498?auto=format&fit=crop&w=900&q=85',
    ),
    MenuItem(
      id: 'wagyu-burger',
      name: 'Truffle Wagyu Burger',
      description: 'Aged cheddar, truffle aioli, butter lettuce, brioche',
      category: 'Burgers',
      price: 22.00,
      rating: 4.8,
      isPopular: true,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=85',
    ),
    MenuItem(
      id: 'salmon-bowl',
      name: 'Miso-glazed Salmon Bowl',
      description: 'Charred salmon, sushi rice, greens, sesame dressing',
      category: 'Bowls',
      price: 19.50,
      rating: 4.7,
      imageUrl:
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=900&q=85',
    ),
    MenuItem(
      id: 'sushi-platter',
      name: 'Chef’s Sushi Selection',
      description: 'Salmon nigiri, tuna sashimi, avocado maki',
      category: 'Sushi',
      price: 26.00,
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=900&q=85',
    ),
    MenuItem(
      id: 'pasta-alfredo',
      name: 'Wild Mushroom Pappardelle',
      description: 'Hand-cut pasta, wild mushrooms, parmesan, sage',
      category: 'Pasta',
      price: 21.00,
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=900&q=85',
    ),
    MenuItem(
      id: 'burrata-salad',
      name: 'Heirloom Tomato Burrata',
      description: 'Creamy burrata, basil oil, grilled sourdough',
      category: 'Small plates',
      price: 16.00,
      rating: 4.6,
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=900&q=85',
    ),
    MenuItem(
      id: 'tiramisu',
      name: 'Classic Tiramisu',
      description: 'Espresso-soaked ladyfingers, mascarpone, cocoa',
      category: 'Desserts',
      price: 9.00,
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?auto=format&fit=crop&w=900&q=85',
    ),
    MenuItem(
      id: 'lemonade',
      name: 'Basil Citrus Spritz',
      description: 'Fresh lemon, basil, sparkling water',
      category: 'Drinks',
      price: 6.50,
      rating: 4.7,
      imageUrl:
          'https://images.unsplash.com/photo-1513558161293-cdaf765edfd7?auto=format&fit=crop&w=900&q=85',
    ),
  ];

  static const defaultCategories = <String>[
    'All',
    'Pizza',
    'Burgers',
    'Bowls',
    'Sushi',
    'Pasta',
    'Small plates',
    'Desserts',
    'Drinks',
  ];

  static List<String> categoriesFor(Iterable<MenuItem> items) {
    final categories = <String>{...defaultCategories};
    categories.addAll(items.map((item) => item.category));
    return categories.toList();
  }
}
