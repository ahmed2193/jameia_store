import '../../../../core/data/models/models.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/entities/support_order.dart';
import '../../domain/entities/support_order_line.dart';
import '../models/faq_model.dart';

extension SupportOrderMapper on HeroOrder {
  SupportOrder toSupportOrder() => SupportOrder(
    id: id,
    shopName: shopName,
    shopNameAr: shopNameAr,
    shopLogo: shopLogo,
    total: total,
    date: date,
    dateAr: dateAr,
    lines: [
      for (final item in items)
        SupportOrderLine(name: item.name, nameAr: item.nameAr, qty: item.qty),
    ],
  );
}

extension FaqMapper on FaqModel {
  FaqItem toEntity() => FaqItem(questionKey: questionKey, answerKey: answerKey);
}
