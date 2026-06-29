class MockGenerator {
  final String id;
  final String capacity;
  final String type;
  final String status; // 'active', 'offline'
  final String category; // 'retailer', 'permanent', 'emergency'
  final String? assignedVendor; // for permanent gensets

  const MockGenerator({
    required this.id,
    required this.capacity,
    required this.type,
    required this.status,
    required this.category,
    this.assignedVendor,
  });
}

final List<MockGenerator> mockGenerators = [
  const MockGenerator(
    id: 'GEN-100KVA-02',
    capacity: '100 kVA',
    type: '-',
    status: 'active',
    category: 'retailer',
  ),
  const MockGenerator(
    id: 'GEN-100KVA-6R-01',
    capacity: '100 kVA',
    type: '6R',
    status: 'active',
    category: 'retailer',
  ),
  const MockGenerator(
    id: 'GEN-125KVA-RD-SL90-02',
    capacity: '125 kVA',
    type: 'SL90',
    status: 'active',
    category: 'retailer',
  ),
  const MockGenerator(
    id: 'GEN-45KVA-HA-11',
    capacity: '45 kVA',
    type: 'HA',
    status: 'active',
    category: 'permanent',
    assignedVendor: 'R S Marriage Hall',
  ),
];
