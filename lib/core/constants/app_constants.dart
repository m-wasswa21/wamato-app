class AppConstants {
  static const String appName = 'Wamato';
  static const String appTagline = 'Uganda\'s Trusted Property Marketplace';

  static const List<String> propertyTypes = [
    'House',
    'Apartment',
    'Office',
    'Land',
    'Warehouse',
    'Commercial',
    'Airbnb',
    'Holiday Apt',
  ];

  static const List<String> districts = [
    'Kampala', 'Wakiso', 'Mukono', 'Entebbe', 'Jinja',
    'Mbarara', 'Gulu', 'Lira', 'Fort Portal', 'Mbale',
  ];

  static const Map<String, int> listingPackages = {
    'Basic Listing': 20000,
    'Premium Listing': 50000,
    'Featured Listing': 100000,
  };

  static const Map<String, int> unlockPackages = {
    'Single Property': 5000,
    '5 Properties': 20000,
    'Weekly Pass': 30000,
    'Monthly Pass': 100000,
  };

  // Placeholder property images (public Unsplash)
  static const List<String> sampleImages = [
    'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800',
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
    'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=800',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
  ];
}
