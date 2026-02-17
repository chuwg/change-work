package com.change.app.change

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.*

object WidgetUtils {

    private const val PREFS_NAME = "FlutterSharedPreferences"

    // Keys match Flutter's home_widget cache keys with "flutter." prefix
    private const val KEY_TODAY_TYPE = "flutter.widget_today_shift_type"
    private const val KEY_TODAY_LABEL = "flutter.widget_today_shift_label"
    private const val KEY_TODAY_START = "flutter.widget_today_shift_start"
    private const val KEY_TODAY_END = "flutter.widget_today_shift_end"
    private const val KEY_DAYS_UNTIL_OFF = "flutter.widget_days_until_off"
    private const val KEY_WEEK_SHIFTS = "flutter.widget_week_shifts"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun getTodayType(context: Context): String {
        return getPrefs(context).getString(KEY_TODAY_TYPE, "none") ?: "none"
    }

    fun getTodayLabel(context: Context): String {
        return getPrefs(context).getString(KEY_TODAY_LABEL, "미등록") ?: "미등록"
    }

    fun getTodayStart(context: Context): String {
        return getPrefs(context).getString(KEY_TODAY_START, "") ?: ""
    }

    fun getTodayEnd(context: Context): String {
        return getPrefs(context).getString(KEY_TODAY_END, "") ?: ""
    }

    fun getTimeString(context: Context): String {
        val start = getTodayStart(context)
        val end = getTodayEnd(context)
        return if (start.isNotEmpty() && end.isNotEmpty()) "$start - $end" else ""
    }

    fun getDaysUntilOff(context: Context): Int {
        return getPrefs(context).getLong(KEY_DAYS_UNTIL_OFF, -1L).toInt()
    }

    fun getWeekShifts(context: Context): List<DayShiftData> {
        val json = getPrefs(context).getString(KEY_WEEK_SHIFTS, null)
        if (json != null) {
            try {
                val array = JSONArray(json)
                val result = mutableListOf<DayShiftData>()
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    result.add(
                        DayShiftData(
                            date = obj.getString("date"),
                            type = obj.getString("type"),
                            label = obj.getString("label")
                        )
                    )
                }
                return result
            } catch (_: Exception) {}
        }
        return emptyList()
    }

    fun getShiftColor(type: String): Int {
        return when (type) {
            "day" -> Color.parseColor("#FFB840")
            "evening" -> Color.parseColor("#FF6B35")
            "night" -> Color.parseColor("#7364F0")
            "off" -> Color.parseColor("#5DB882")
            else -> Color.parseColor("#666666")
        }
    }

    fun getShortLabel(type: String): String {
        return when (type) {
            "day" -> "주"
            "evening" -> "오"
            "night" -> "야"
            "off" -> "휴"
            else -> "-"
        }
    }

    fun getWeekdayLabel(dateStr: String): String {
        val weekdays = arrayOf("일", "월", "화", "수", "목", "금", "토")
        return try {
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val date = sdf.parse(dateStr)
            val cal = Calendar.getInstance()
            cal.time = date!!
            weekdays[cal.get(Calendar.DAY_OF_WEEK) - 1]
        } catch (_: Exception) {
            "-"
        }
    }

    fun getDayOfMonth(dateStr: String): String {
        return try {
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val date = sdf.parse(dateStr)
            val cal = Calendar.getInstance()
            cal.time = date!!
            cal.get(Calendar.DAY_OF_MONTH).toString()
        } catch (_: Exception) {
            "-"
        }
    }

    data class DayShiftData(
        val date: String,
        val type: String,
        val label: String
    )
}
