import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/distribution.dart';

class ReceiptWidget extends StatelessWidget {
  final Distribution distribution;
  final Customer? customer;

  const ReceiptWidget({
    super.key,
    required this.distribution,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = intl.NumberFormat("#,##0.00", "en_US");
    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');

    // نستخدم Container بخلفية بيضاء وعرض محدد لمحاكاة ورقة الإيصال
    return Container(
      color: Colors.white,
      width: 380, // عرض مناسب لدقة الطباعة (High Density for 58mm)
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- الرأس ---
            const Text(
              'توزيع الألبان',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سند استلام / توزيع',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const Divider(thickness: 2, color: Colors.black),

            // --- المعلومات الأساسية ---
            _buildInfoRow('التاريخ:', dateFormat.format(distribution.distributionDate)),
            _buildInfoRow('رقم السند:', '#${distribution.id.substring(0, 8)}'),
            
            const SizedBox(height: 8),
            
            // --- بيانات العميل ---
            if (customer != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('العميل:', customer!.name, isBold: true),
                    if (customer!.phone.isNotEmpty)
                      _buildInfoRow('الهاتف:', customer!.phone),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- جدول المنتجات ---
            Row(
              children: const [
                Expanded(flex: 4, child: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black))),
                Expanded(flex: 2, child: Text('الكمية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black))),
                Expanded(flex: 3, child: Text('المجموع', textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black))),
              ],
            ),
            const Divider(color: Colors.black),

            ...distribution.items.map((item) {
              // التحقق إذا كان المنتج مجانياً
              final isFree = item.price == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                    Row(
                      children: [
                        Expanded(
                          flex: 4, 
                          child: Text(
                            isFree ? '(مجاني)' : '@ ${currencyFormat.format(item.price)}', 
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                        Expanded(
                          flex: 2, 
                          child: Text(
                            item.quantity.toStringAsFixed(1), 
                            textAlign: TextAlign.center, 
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                        Expanded(
                          flex: 3, 
                          child: Text(
                            currencyFormat.format(item.subtotal), 
                            textAlign: TextAlign.left, 
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const Divider(thickness: 2, color: Colors.black),

            // --- الإجماليات ---
            _buildTotalRow('الإجمالي:', distribution.totalAmount, currencyFormat, isBold: true, fontSize: 18),
            _buildTotalRow('المدفوع:', distribution.paidAmount, currencyFormat),
            _buildTotalRow('المتبقي:', distribution.totalAmount - distribution.paidAmount, currencyFormat),

            const SizedBox(height: 24),
            
            // --- التذييل ---
            const Text(
              'شكراً لتعاملكم معنا',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            const Text(
              'Powered by Project Guardian',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
                fontSize: 14, 
                color: Colors.black
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, intl.NumberFormat format, {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize, color: Colors.black)),
          Text(
            format.format(value), 
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize, color: Colors.black),
          ),
        ],
      ),
    );
  }
}