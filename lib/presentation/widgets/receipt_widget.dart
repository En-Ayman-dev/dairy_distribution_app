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
    final remaining = distribution.totalAmount - distribution.paidAmount;

    // نستخدم Container بخلفية بيضاء وعرض محدد لمحاكاة ورقة الإيصال
    return Container(
      color: Colors.white,
      width: 380, // عرض مناسب لدقة الطباعة (High Density for 58mm)
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // محتوى الفاتورة الفعلي
            final content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- الرأس ---
                // تصميم رأس الفاتورة الجديد مع اسم الشركة والنص المطلوب
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      'الذهبي واخوان للتجاره العامه وتسويق',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8860B), // ذهبي اللون
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'توزيع منتجات نانا',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '777762992 / 777210653 / 772030608',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
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
                _buildInfoRow(
                  'التاريخ:',
                  dateFormat.format(distribution.distributionDate),
                ),
                _buildInfoRow(
                  'رقم السند:',
                  '#${distribution.id.substring(0, 8)}',
                ),

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
                        _buildInfoRow(
                          'العميل:',
                          customer!.name,
                          isBold: true,
                        ),
                        if (customer!.phone.isNotEmpty)
                          _buildInfoRow('الهاتف:', customer!.phone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- المندوب ---
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'المندوب',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'احمد علي عبدالله الذاهبي',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '772030608',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- جدول المنتجات ---
                Row(
                  children: const [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'المنتج',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'الكمية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'المجموع',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
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
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                isFree
                                    ? '(مجاني)'
                                    : '@ ${currencyFormat.format(item.price)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.quantity.toStringAsFixed(1),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                currencyFormat.format(item.subtotal),
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
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
                _buildTotalRow(
                  'الإجمالي:',
                  distribution.totalAmount,
                  currencyFormat,
                  isBold: true,
                  fontSize: 18,
                ),
                _buildTotalRow(
                  'المدفوع:',
                  distribution.paidAmount,
                  currencyFormat,
                ),
                _buildTotalRow(
                  'المتبقي:',
                  remaining,
                  currencyFormat,
                ),

                // --- الرصيد السابق و الإجمالي الكلي بعد إضافته ---
                if (customer != null && customer!.balance != 0.0) ...[
                  const SizedBox(height: 8),
                  _buildTotalRow(
                    'الرصيد السابق:',
                    customer!.balance,
                    currencyFormat,
                  ),
                  _buildTotalRow(
                    'الإجمالي الكلي:',
                    remaining + customer!.balance,
                    currencyFormat,
                    isBold: true,
                    fontSize: 18,
                  ),
                ],

                const SizedBox(height: 10),

                // --- التذييل ---
                const Text(
                  'شكراً لتعاملكم معنا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            );

            // إذا كان هناك ارتفاع محدود (مثل الـ Dialog) نستخدم Scroll لمنع overflow
            if (constraints.maxHeight.isFinite) {
              return SingleChildScrollView(
                child: content,
              );
            }

            // إذا كان الارتفاع غير محدود (مثل وضع الطباعة) نرجع المحتوى كما هو
            return content;
          },
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
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double value,
    intl.NumberFormat format, {
    bool isBold = false,
    double fontSize = 16,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: Colors.black,
            ),
          ),
          Text(
            format.format(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
