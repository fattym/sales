import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'add_order_page.dart';

class SchoolSellPage extends StatefulWidget {
  const SchoolSellPage({super.key, required this.school});

  final Map<String, dynamic> school;

  @override
  State<SchoolSellPage> createState() => _SchoolSellPageState();
}

class _SchoolSellPageState extends State<SchoolSellPage> {
  final _packageController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  final _receiptController = TextEditingController();
  bool _saving = false;
  bool _checkoutConfirmed = false;
  String? _paymentMethod;

  @override
  void dispose() {
    _packageController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  String _checkoutTitle() {
    switch (_paymentMethod) {
      case 'cash':
        return 'Cash Checkout';
      case 'mpesa':
        return 'M-Pesa Checkout';
      case 'bank':
        return 'Bank Checkout';
      default:
        return 'Checkout';
    }
  }

  String _checkoutSubtitle() {
    switch (_paymentMethod) {
      case 'cash':
        return 'Collect the cash, confirm the amount, and record the receipt note.';
      case 'mpesa':
        return 'Share the payment prompt and capture the transaction reference.';
      case 'bank':
        return 'Share the bank details and record the deposit reference.';
      default:
        return 'Choose a payment method to continue.';
    }
  }

  String _paymentInstructions() {
    switch (_paymentMethod) {
      case 'cash':
        return 'Cash payment selected. Confirm the collected amount at the school and mark the sale as paid.';
      case 'mpesa':
        return 'M-Pesa selected. Send the number or till details and wait for the payment confirmation.';
      case 'bank':
        return 'Bank transfer selected. Share the account details and confirm once the slip is received.';
      default:
        return 'Select a payment method to see the checkout procedure.';
    }
  }

  Future<void> _proceedToOrderBuilder() async {
    if (_paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a payment method to continue.')),
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the checkout amount.')),
      );
      return;
    }

    final checkoutAmount = double.tryParse(_amountController.text.trim());
    if (checkoutAmount == null || checkoutAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid numeric amount.')),
      );
      return;
    }

    if (_paymentMethod != 'cash' && _receiptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the payment reference or receipt.')),
      );
      return;
    }

    setState(() => _saving = true);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddOrderPage(
              initialSchoolId: widget.school['id']?.toString(),
              initialSchoolName: widget.school['name']?.toString(),
              initialPaymentMethod: _paymentMethod,
              initialPaymentReference: _receiptController.text.trim(),
              initialCheckoutAmount: checkoutAmount,
              initialNotes: _notesController.text.trim(),
              initialPackageName: _packageController.text.trim().isEmpty
                  ? null
                  : _packageController.text.trim(),
            ),
      ),
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
      _checkoutConfirmed = result != null;
    });

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.school['name']} order created successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolName = widget.school['name']?.toString() ?? 'School';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell to School'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeaderCard(
            title: schoolName,
            subtitle: 'Track proposals, package interest, and sales notes.',
            icon: Icons.point_of_sale,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _packageController,
            decoration: const InputDecoration(
              labelText: 'Package or Offer',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Sales Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Checkout Procedure',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(
              labelText: 'Method of Payment',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
              DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
            ],
            onChanged: (value) {
              setState(() {
                _paymentMethod = value;
                _checkoutConfirmed = false;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: 'KES ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _receiptController,
            decoration: InputDecoration(
              labelText:
                  _paymentMethod == 'cash'
                      ? 'Cash Receipt / Note'
                      : _paymentMethod == 'bank'
                      ? 'Bank Slip / Reference'
                      : 'M-Pesa Reference',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _checkoutTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(_checkoutSubtitle()),
                const SizedBox(height: 10),
                Text(
                  _paymentInstructions(),
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed:
                _saving
                    ? null
                    : () async => _proceedToOrderBuilder(),
            icon:
                _saving
                    ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.shopping_cart_checkout),
            label: const Text('Proceed to Checkout'),
          ),
          if (_checkoutConfirmed) ...[
            const SizedBox(height: 12),
            Text(
              'Checkout method: ${_paymentMethod?.toUpperCase() ?? "N/A"}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.green.withOpacity(0.15),
            child: Icon(icon, color: Colors.green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
