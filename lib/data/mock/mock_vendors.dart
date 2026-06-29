class MockVendor {
  final String id;
  final String name;
  final String location;
  final String phone;
  final String category; // 'retailer', 'rental'

  const MockVendor({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.category,
  });
}

final List<MockVendor> mockVendors = [
  const MockVendor(
    id: 'VEN011',
    name: 'Abraar',
    location: 'Aligarh',
    phone: '9876543210',
    category: 'retailer',
  ),
  const MockVendor(
    id: 'VEN025',
    name: 'Ankit Singh',
    location: 'Hathras',
    phone: '9876501234',
    category: 'retailer',
  ),
  const MockVendor(
    id: 'VEN089',
    name: 'Global Rentals Ltd',
    location: 'Agra Road',
    phone: '9997778888',
    category: 'rental',
  ),
  const MockVendor(
    id: 'VEN042',
    name: 'Apex Logistics',
    location: 'Aligarh',
    phone: '9997775553',
    category: 'rental',
  ),
  const MockVendor(
    id: 'VEN001',
    name: 'Mallu',
    location: 'Aligarh',
    phone: '9876543210',
    category: 'retailer',
  ),
  const MockVendor(
    id: 'VEN002',
    name: 'Dabbu',
    location: 'Hathras',
    phone: '9876501234',
    category: 'retailer',
  ),
  const MockVendor(
    id: 'VEN003',
    name: 'Sonu',
    location: 'Kasganj',
    phone: '9876512345',
    category: 'retailer',
  ),
  const MockVendor(
    id: 'RNV001',
    name: 'Panchwati Guest House',
    location: 'Aligarh',
    phone: '9997775553',
    category: 'rental',
  ),
  const MockVendor(
    id: 'RNV002',
    name: 'R S Marriage Hall',
    location: 'Agra Road',
    phone: '9997778888',
    category: 'rental',
  ),
];
