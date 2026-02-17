package com.change.app.change

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class ShiftWidgetSmall : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.shift_widget_small)

            val label = WidgetUtils.getTodayLabel(context)
            val timeStr = WidgetUtils.getTimeString(context)
            val daysUntilOff = WidgetUtils.getDaysUntilOff(context)
            val shiftType = WidgetUtils.getTodayType(context)
            val color = WidgetUtils.getShiftColor(shiftType)

            views.setTextViewText(R.id.tv_shift_label, label)
            views.setTextColor(R.id.tv_shift_label, color)

            if (timeStr.isNotEmpty()) {
                views.setTextViewText(R.id.tv_shift_time, timeStr)
            } else {
                views.setTextViewText(R.id.tv_shift_time, "")
            }

            when {
                shiftType == "off" -> {
                    views.setTextViewText(R.id.tv_days_until_off, "오늘 휴무")
                }
                daysUntilOff > 0 -> {
                    views.setTextViewText(R.id.tv_days_until_off, "휴무까지 D-$daysUntilOff")
                }
                else -> {
                    views.setTextViewText(R.id.tv_days_until_off, "")
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
