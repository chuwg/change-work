package com.change.app.change

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class ShiftWidgetMedium : AppWidgetProvider() {

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
        private val weekdayIds = arrayOf(
            R.id.tv_weekday0, R.id.tv_weekday1, R.id.tv_weekday2,
            R.id.tv_weekday3, R.id.tv_weekday4, R.id.tv_weekday5, R.id.tv_weekday6
        )
        private val dateIds = arrayOf(
            R.id.tv_date0, R.id.tv_date1, R.id.tv_date2,
            R.id.tv_date3, R.id.tv_date4, R.id.tv_date5, R.id.tv_date6
        )
        private val typeIds = arrayOf(
            R.id.tv_type0, R.id.tv_type1, R.id.tv_type2,
            R.id.tv_type3, R.id.tv_type4, R.id.tv_type5, R.id.tv_type6
        )

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.shift_widget_medium)

            val label = WidgetUtils.getTodayLabel(context)
            val timeStr = WidgetUtils.getTimeString(context)
            val daysUntilOff = WidgetUtils.getDaysUntilOff(context)
            val shiftType = WidgetUtils.getTodayType(context)

            // Top section
            views.setTextViewText(R.id.tv_today_label, "오늘 $label")

            if (timeStr.isNotEmpty()) {
                views.setTextViewText(R.id.tv_today_time, timeStr)
            } else {
                views.setTextViewText(R.id.tv_today_time, "")
            }

            when {
                shiftType == "off" -> {
                    views.setTextViewText(R.id.tv_dday, "오늘 휴무")
                }
                daysUntilOff > 0 -> {
                    views.setTextViewText(R.id.tv_dday, "다음 휴무 D-$daysUntilOff")
                }
                else -> {
                    views.setTextViewText(R.id.tv_dday, "")
                }
            }

            // Week strip
            val weekShifts = WidgetUtils.getWeekShifts(context)
            for (i in 0 until 7) {
                if (i < weekShifts.size) {
                    val shift = weekShifts[i]
                    val color = WidgetUtils.getShiftColor(shift.type)
                    val weekday = WidgetUtils.getWeekdayLabel(shift.date)
                    val day = WidgetUtils.getDayOfMonth(shift.date)
                    val shortLabel = WidgetUtils.getShortLabel(shift.type)

                    views.setTextViewText(weekdayIds[i], weekday)
                    views.setTextViewText(dateIds[i], day)
                    views.setTextViewText(typeIds[i], shortLabel)
                    views.setTextColor(typeIds[i], color)
                } else {
                    views.setTextViewText(weekdayIds[i], "-")
                    views.setTextViewText(dateIds[i], "-")
                    views.setTextViewText(typeIds[i], "-")
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
