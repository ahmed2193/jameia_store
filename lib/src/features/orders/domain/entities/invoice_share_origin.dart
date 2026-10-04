import 'package:equatable/equatable.dart';

/// Where on the screen the share sheet comes from (the Share button's box,
/// in logical pixels). An iPad shows the sheet as a popover pointing at it;
/// phones ignore it.
class InvoiceShareOrigin extends Equatable {
  const InvoiceShareOrigin({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  @override
  List<Object?> get props => [left, top, width, height];
}
