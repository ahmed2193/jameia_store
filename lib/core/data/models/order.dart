/// Order lifecycle models.
class KeetaOrder {
  final String id;
  final String shopName;
  final String shopLogo;
  final String status; // delivering | completed | preparing | cancelled
  final int statusStep; // 1..5 for the tracking stepper
  final double total;
  final String date;
  final List<OrderItem> items;
  final Rider? rider;

  const KeetaOrder({
    required this.id,
    required this.shopName,
    required this.shopLogo,
    required this.status,
    required this.statusStep,
    required this.total,
    required this.date,
    required this.items,
    required this.rider,
  });

  bool get isActive => status == 'delivering' || status == 'preparing';

  int get itemCount => items.fold(0, (s, i) => s + i.qty);

  factory KeetaOrder.fromJson(Map<String, dynamic> j) => KeetaOrder(
        id: j['id'] as String,
        shopName: j['shopName'] as String? ?? '',
        shopLogo: j['shopLogo'] as String? ?? '',
        status: j['status'] as String? ?? 'completed',
        statusStep: (j['statusStep'] as num?)?.toInt() ?? 1,
        total: (j['total'] as num?)?.toDouble() ?? 0,
        date: j['date'] as String? ?? '',
        items: (j['items'] as List?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        rider: j['rider'] == null
            ? null
            : Rider.fromJson(j['rider'] as Map<String, dynamic>),
      );
}

class OrderItem {
  final String name;
  final int qty;
  final double price;

  const OrderItem({required this.name, required this.qty, required this.price});

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: j['name'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );
}

class Rider {
  final String name;
  final String phone;
  final String vehicle; // motorbike | car

  const Rider({required this.name, required this.phone, required this.vehicle});

  factory Rider.fromJson(Map<String, dynamic> j) => Rider(
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        vehicle: j['vehicle'] as String? ?? 'motorbike',
      );
}
