import 'package:flutter/material.dart';

/// نموذج مقاس طابعة حرارية
class PrinterSize {
  final String name;
  final double widthMm;
  final double printableWidthMm;
  final String description;

  const PrinterSize({
    required this.name,
    required this.widthMm,
    required this.printableWidthMm,
    required this.description,
  });
}

const List<PrinterSize> kPrinterSizes = [
  PrinterSize(
    name: '58mm',
    widthMm: 58,
    printableWidthMm: 48,
    description: 'مناسب للفواتير الصغيرة (متاجر/مطاعم)',
  ),
  PrinterSize(
    name: '80mm',
    widthMm: 80,
    printableWidthMm: 72,
    description: 'مناسب للسوبرماركت والمطاعم الكبيرة',
  ),
  // يمكن إضافة مقاسات أخرى هنا
];

/// زر طباعة عام قابل لإعادة الاستخدام
enum PrintOutput { printer, pdf }

class PrintButton extends StatefulWidget {
  final Future<void> Function(PrinterSize size, PrintOutput output, bool preview) onPrint;
  final String? label;
  final IconData? icon;
  final PrinterSize? defaultSize;
  final List<PrinterSize>? sizes;
  final bool showLabel;

  const PrintButton({
    super.key,
    required this.onPrint,
    this.label,
    this.icon,
    this.defaultSize,
    this.sizes,
    this.showLabel = true,
  });

  @override
  State<PrintButton> createState() => _PrintButtonState();
}

class _PrintButtonState extends State<PrintButton> {
  PrinterSize? _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.defaultSize ?? kPrinterSizes.first;
  }

  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (context) {
        PrinterSize selected = _selectedSize ?? kPrinterSizes.first;
        final sizes = widget.sizes ?? kPrinterSizes;
        PrintOutput output = PrintOutput.printer;
        bool preview = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('اختيار مقاس الطابعة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final size in sizes)
                  RadioListTile<PrinterSize>(
                    value: size,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v!),
                    title: Text('${size.name} (عرض فعلي ~${size.printableWidthMm}mm) - ${size.description}'),
                  ),
                const Divider(),
                RadioListTile<PrintOutput>(
                  value: PrintOutput.printer,
                  groupValue: output,
                  onChanged: (v) => setState(() => output = v!),
                  title: const Text('طباعة إلى طابعة حرارية'),
                ),
                RadioListTile<PrintOutput>(
                  value: PrintOutput.pdf,
                  groupValue: output,
                  onChanged: (v) => setState(() => output = v!),
                  title: const Text('حفظ / عرض PDF'),
                ),
                if (output == PrintOutput.pdf)
                  CheckboxListTile(
                    value: preview,
                    onChanged: (v) => setState(() => preview = v ?? false),
                    title: const Text('عرض ملف PDF بعد الإنشاء'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('طباعة'),
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _selectedSize = selected);
                  await widget.onPrint(selected, output, preview);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(widget.icon ?? Icons.print),
      label: widget.showLabel ? Text(widget.label ?? 'طباعة الفاتورة') : const SizedBox.shrink(),
      onPressed: _showPrintDialog,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
