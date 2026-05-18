package com.example.expense_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ExpenseWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.expense_widget)

            val balance = widgetData.getString("balance", "NT$ 0") ?: "NT$ 0"
            val income = widgetData.getString("income", "0") ?: "0"
            val expense = widgetData.getString("expense", "0") ?: "0"
            val label = widgetData.getString("label", "本月結餘") ?: "本月結餘"

            views.setTextViewText(R.id.widget_balance, balance)
            views.setTextViewText(R.id.widget_income, income)
            views.setTextViewText(R.id.widget_expense, expense)
            views.setTextViewText(R.id.widget_label, label)

            // 點整個 widget = 開 App
            val openAppIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("expensetracker://home"),
            )
            views.setOnClickPendingIntent(R.id.widget_balance, openAppIntent)

            // 點「新增」按鈕 → 開 AddTransactionScreen
            val addIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("expensetracker://add"),
            )
            views.setOnClickPendingIntent(R.id.widget_btn_add, addIntent)

            // 點「掃發票」→ 開掃描頁
            val scanIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("expensetracker://scan"),
            )
            views.setOnClickPendingIntent(R.id.widget_btn_scan, scanIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
