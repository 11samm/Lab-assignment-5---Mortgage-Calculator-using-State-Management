// Samuel Garcia | CECS 453 | Lab assignment 5 - Mortgage Calculator
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mortgage_provider.dart';

import 'mortgage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = await MortgageProvider.load();
  runApp(MortgageApp(provider: provider));
}

class MortgageApp extends StatelessWidget {
  const MortgageApp({super.key, required this.provider});

  final MortgageProvider provider;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      title: 'Mortgage Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const SummaryScreen(),
    ),
  );
}

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _accepted = false;

  Future<void> _modify() async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const ModifyScreen()));
    if (!mounted || saved != true) return;
    setState(() => _accepted = false);
  }

  Future<void> _confirmTerms(bool? value) async {
    if (value != true) {
      setState(() => _accepted = false);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: const Text(
          'This calculator estimates principal and interest payments for a '
          'fixed-rate mortgage. It excludes taxes, insurance, and lender fees. '
          'Actual payments may differ. Confirm that you understand these terms.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Agree'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _accepted = confirmed == true);
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mortgage Calculator')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Your mortgage',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _row(
                'Amount',
                Mortgage.money(
                  context.watch<MortgageProvider>().mortgage.amount,
                ),
              ),
              _row(
                'Years',
                '${context.watch<MortgageProvider>().mortgage.years}',
              ),
              _row(
                'Interest Rate',
                '${(context.watch<MortgageProvider>().mortgage.rate * 100).toStringAsFixed(2)}%',
              ),
              const Divider(thickness: 2),
              _row(
                'Monthly Payment',
                Mortgage.money(
                  context.watch<MortgageProvider>().mortgage.monthlyPayment,
                ),
              ),
              _row(
                'Total Payment',
                Mortgage.money(
                  context.watch<MortgageProvider>().mortgage.totalPayment,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Terms and Conditions'),
                value: _accepted,
                onChanged: _confirmTerms,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _modify,
                child: const Text('Modify Data'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ModifyScreen extends StatefulWidget {
  const ModifyScreen({super.key});

  @override
  State<ModifyScreen> createState() => _ModifyScreenState();
}

class _ModifyScreenState extends State<ModifyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final ScrollController _rateScroll;
  late int _years;
  late int _rateIndex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final mortgage = context.read<MortgageProvider>().mortgage;
    _amountController = TextEditingController(
      text: mortgage.amount.toStringAsFixed(2),
    );
    _years = mortgage.years;
    _rateIndex = ((mortgage.rate * 100 - 2) / 0.25).round();
    _rateScroll = ScrollController(initialScrollOffset: _rateIndex * 56.0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateScroll.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<MortgageProvider>().save(
        Mortgage(
          amount: double.parse(_amountController.text.trim()),
          years: _years,
          rate: (2 + _rateIndex * 0.25) / 100,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Modify Mortgage')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: PopScope(
            canPop: !_saving,
            child: AbsorbPointer(
              absorbing: _saving,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Years',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    RadioGroup<int>(
                      groupValue: _years,
                      onChanged: (value) => setState(() => _years = value!),
                      child: Wrap(
                        children: [
                          for (final years in [10, 15, 30])
                            SizedBox(
                              width: 100,
                              child: RadioListTile<int>(
                                contentPadding: EdgeInsets.zero,
                                title: Text('$years'),
                                value: years,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (text) {
                        final amount = double.tryParse(text?.trim() ?? '');
                        if (amount == null || !amount.isFinite || amount < 0) {
                          return 'Enter a valid amount of zero or more.';
                        }
                        if (amount > 1000000000000) {
                          return 'Amount must be at most 1 trillion.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Interest Rate',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Select a rate from 2% to 15% (0.25% increments).',
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 240,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RadioGroup<int>(
                          groupValue: _rateIndex,
                          onChanged: (value) =>
                              setState(() => _rateIndex = value!),
                          child: Scrollbar(
                            controller: _rateScroll,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _rateScroll,
                              itemExtent: 56,
                              itemCount: 53,
                              itemBuilder: (context, index) => RadioListTile<int>(
                                title: Text(
                                  '${(2 + index * 0.25).toStringAsFixed(2)}%',
                                ),
                                value: index,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _done,
                      child: Text(_saving ? 'Saving...' : 'Done'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
