import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class FilterSheet extends StatefulWidget {
  final TransactionFilter initial;
  const FilterSheet({super.key, required this.initial});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<String> _categories;
  DateTimeRange? _dateRange;
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categories = {...widget.initial.categories};
    _dateRange = widget.initial.dateRange;
    if (widget.initial.minAmount != null) {
      _minCtrl.text = widget.initial.minAmount!.toStringAsFixed(0);
    }
    if (widget.initial.maxAmount != null) {
      _maxCtrl.text = widget.initial.maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  void _apply() {
    final min = double.tryParse(_minCtrl.text.trim());
    final max = double.tryParse(_maxCtrl.text.trim());
    Navigator.pop(
      context,
      TransactionFilter(
        categories: _categories,
        dateRange: _dateRange,
        minAmount: min,
        maxAmount: max,
      ),
    );
  }

  void _reset() {
    Navigator.pop(context, const TransactionFilter());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.filterTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: _reset, child: Text(l.filterReset)),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.category, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategories.map((c) {
                final selected = _categories.contains(c.label);
                return FilterChip(
                  label: Text(c.label),
                  avatar: Icon(c.icon, size: 16,
                      color: selected ? Colors.white : c.color),
                  selected: selected,
                  selectedColor: c.color,
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.w500),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _categories.add(c.label);
                    } else {
                      _categories.remove(c.label);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(l.filterDateRange,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDateRange,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.date_range),
                  isDense: true,
                ),
                child: Text(_dateRange == null
                    ? l.filterUnlimited
                    : '${_dateRange!.start.toString().substring(0, 10)} ~ ${_dateRange!.end.toString().substring(0, 10)}'),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.filterAmountRange,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        hintText: l.filterMin,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        prefixText: '\$ '),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('~'),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        hintText: l.filterMax,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        prefixText: '\$ '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.check),
                label: Text(l.filterApply),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
