import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

void main() => runApp(const SalesApp());

// Simple AR/EN strings
const t = {
  'en': {
    'title': 'Sales Manager', 'products': 'Products', 'customers': 'Customers',
    'orders': 'Orders', 'report': 'Monthly Report', 'add': 'Add', 'search': 'Search...',
    'name': 'Name', 'price': 'Price', 'stock': 'Stock', 'phone': 'Phone',
    'qty': 'Quantity', 'save': 'Save', 'noData': 'Nothing here yet - tap + to add',
    'ordersThisMonth': 'Orders this month', 'revenueThisMonth': 'Revenue this month',
  },
  'ar': {
    'title': 'إدارة المبيعات', 'products': 'المنتجات', 'customers': 'العملاء',
    'orders': 'الطلبات', 'report': 'تقرير الشهر', 'add': 'إضافة', 'search': 'بحث...',
    'name': 'الاسم', 'price': 'السعر', 'stock': 'المخزون', 'phone': 'الهاتف',
    'qty': 'الكمية', 'save': 'حفظ', 'noData': 'لا توجد بيانات - اضغط + للإضافة',
    'ordersThisMonth': 'طلبات هذا الشهر', 'revenueThisMonth': 'إيرادات هذا الشهر',
  },
};

class SalesApp extends StatefulWidget {
  const SalesApp({super.key});
  @override
  State<SalesApp> createState() => _SalesAppState();
}

class _SalesAppState extends State<SalesApp> {
  String lang = 'ar';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(lang),
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: HomePage(
        lang: lang,
        onToggleLang: () => setState(() => lang = lang == 'ar' ? 'en' : 'ar'),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String lang;
  final VoidCallback onToggleLang;
  const HomePage({super.key, required this.lang, required this.onToggleLang});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  String get l => widget.lang;

  @override
  Widget build(BuildContext context) {
    final pages = [OrdersPage(l: l), ProductsPage(l: l), CustomersPage(l: l), ReportPage(l: l)];
    return Scaffold(
      appBar: AppBar(
        title: Text(t[l]!['title']!),
        actions: [
          TextButton(
            onPressed: widget.onToggleLang,
            child: Text(l == 'ar' ? 'EN' : 'عربي', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.receipt_long), label: t[l]!['orders']!),
          NavigationDestination(icon: const Icon(Icons.inventory_2), label: t[l]!['products']!),
          NavigationDestination(icon: const Icon(Icons.people), label: t[l]!['customers']!),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: t[l]!['report']!),
        ],
      ),
    );
  }
}

class OrdersPage extends StatefulWidget {
  final String l;
  const OrdersPage({super.key, required this.l});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    orders = await DBHelper.getOrders();
    products = await DBHelper.getProducts();
    customers = await DBHelper.getCustomers();
    setState(() {});
  }

  Future<void> _addOrder() async {
    if (products.isEmpty || customers.isEmpty) return;
    int? productId = products.first['id'];
    int? customerId = customers.first['id'];
    final qtyCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(t[widget.l]!['add']! + ' - ' + t[widget.l]!['orders']!),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              value: customerId,
              items: customers
                  .map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name'])))
                  .toList(),
              onChanged: (v) => setD(() => customerId = v),
            ),
            DropdownButtonFormField<int>(
              value: productId,
              items: products
                  .map((p) => DropdownMenuItem(value: p['id'], child: Text(p['name'])))
                  .toList(),
              onChanged: (v) => setD(() => productId = v),
            ),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t[widget.l]!['qty']!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t[widget.l]!['save']!)),
          ],
        ),
      ),
    );
    if (ok == true) {
      final p = products.firstWhere((e) => e['id'] == productId);
     final qty = int.tryParse(qtyCtrl.text);

if (qty == null || qty <= 0) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Please enter a valid quantity')),
  );
  return;
}

final result = await DBHelper.addOrder(
  customerId!,
  productId!,
  qty,
  (p['price'] as num).toDouble(),
);

if (result == -1) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Not enough stock available')),
  );
  return;
}

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Order added successfully')),
);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: _addOrder, child: const Icon(Icons.add)),
      body: orders.isEmpty
          ? Center(child: Text(t[widget.l]!['noData']!))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (ctx, i) {
                final o = orders[i];
                final d = DateTime.tryParse(o['date'] ?? '');
                return ListTile(
                  leading: const Icon(Icons.receipt),
                  title: Text('${o['product']} → ${o['customer']}'),
                  subtitle: Text(d == null ? '' : DateFormat('yyyy-MM-dd HH:mm').format(d)),
                  trailing: Text('${o['total'].toStringAsFixed(2)}  ×${o['quantity']}'),
                );
              },
            ),
    );
  }
}

class ProductsPage extends StatefulWidget {
  final String l;
  const ProductsPage({super.key, required this.l});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Map<String, dynamic>> items = [];
  String q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    items = await DBHelper.getProducts(q);
    setState(() {});
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t[widget.l]!['add']! + ' - ' + t[widget.l]!['products']!),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: t[widget.l]!['name']!)),
          TextField(controller: price, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t[widget.l]!['price']!)),
          TextField(controller: stock, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t[widget.l]!['stock']!)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t[widget.l]!['save']!)),
        ],
      ),
    );
    if (ok == true && name.text.isNotEmpty) {
      await DBHelper.addProduct(name.text, double.tryParse(price.text) ?? 0, int.tryParse(stock.text) ?? 0);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: t[widget.l]!['search'], border: const OutlineInputBorder()),
            onChanged: (v) {
              q = v;
              _load();
            },
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(t[widget.l]!['noData']!))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final p = items[i];
                    return ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: Text(p['name']),
                      subtitle: Text('${t[widget.l]!['stock']!}: ${p['stock']}'),
                      trailing: Text(p['price'].toStringAsFixed(2)),
                      onLongPress: () async {
                        await DBHelper.deleteProduct(p['id']);
                        _load();
                      },
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class CustomersPage extends StatefulWidget {
  final String l;
  const CustomersPage({super.key, required this.l});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Map<String, dynamic>> items = [];
  String q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    items = await DBHelper.getCustomers(q);
    setState(() {});
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t[widget.l]!['add']! + ' - ' + t[widget.l]!['customers']!),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: t[widget.l]!['name']!)),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: t[widget.l]!['phone']!)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t[widget.l]!['save']!)),
        ],
      ),
    );
    if (ok == true && name.text.isNotEmpty) {
      await DBHelper.addCustomer(name.text, phone.text);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: t[widget.l]!['search'], border: const OutlineInputBorder()),
            onChanged: (v) {
              q = v;
              _load();
            },
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(t[widget.l]!['noData']!))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final c = items[i];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(c['name']),
                      subtitle: Text(c['phone'] ?? ''),
                      onLongPress: () async {
                        await DBHelper.deleteCustomer(c['id']);
                        _load();
                      },
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class ReportPage extends StatefulWidget {
  final String l;
  const ReportPage({super.key, required this.l});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  Map<String, dynamic> report = {'orders': 0, 'revenue': 0.0};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    report = await DBHelper.monthlyReport();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_cart, size: 40),
            title: Text('${report['orders']}'),
            subtitle: Text(t[widget.l]!['ordersThisMonth']!),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.attach_money, size: 40),
            title: Text('${report['revenue'].toStringAsFixed(2)}'),
            subtitle: Text(t[widget.l]!['revenueThisMonth']!),
          ),
        ),
      ]),
    );
  }
}
