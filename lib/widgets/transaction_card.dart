import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = categoryOf(transaction.category);
    final amountColor = transaction.isExpense
        ? AppColors.expense
        : AppColors.income;
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
            borderRadius: BorderRadius.circular(14),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              // 左側分類色 accent bar
              Container(
                width: 4,
                height: 56,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: cat.color,
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 22),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(transaction.category,
                            style: TextStyle(
                                fontSize: 12,
                                color: cat.color,
                                fontWeight: FontWeight.w500)),
                        if (transaction.address.isNotEmpty) ...[
                          Text('  ·  ',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor)),
                          Icon(Icons.location_on,
                              size: 11, color: theme.hintColor),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              transaction.address,
                              style: TextStyle(
                                  fontSize: 11, color: theme.hintColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
                child: Column(
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
                      style: TextStyle(
                          fontSize: 11, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
