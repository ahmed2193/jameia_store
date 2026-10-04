import '../../domain/entities/invoice_page_image.dart';
import '../models/invoice_page_raster_model.dart';

extension InvoicePageRasterMapper on InvoicePageRasterModel {
  InvoicePageImage toEntity() =>
      InvoicePageImage(index: index, png: png, width: width, height: height);
}
