import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onTap,
  });

  String get _categoryIcon {
    final match = kCategories.firstWhere(
      (c) => c['label'] == transaction.category,
      orElse: () => {'icon': '📋'},
    );
    return match['icon'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final amountColor =
        transaction.isExpense ? Colors.red.shade600 : Colors.green.shade600;
    final amountPrefix = transaction.isExpense ? '-' : '+';

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '刪除',
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(_categoryIcon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(transaction.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(transaction.category,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant)),
                          if (transaction.address.isNotEmpty) ...[
                            const Text('  ·  ',
                                style: TextStyle(fontSize: 12,
                                    color: Colors.grey)),
                            const Icon(Icons.location_on,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                transaction.address,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountPrefix\$${NumberFormat('#,##0').format(transaction.amount)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: amountColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MM/dd HH:mm').format(transaction.date),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
