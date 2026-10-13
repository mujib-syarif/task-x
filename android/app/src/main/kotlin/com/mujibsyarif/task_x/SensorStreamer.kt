package com.mujibsyarif.task_x

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Menyalurkan pembacaan sensor ke Flutter hanya selama ada pendengar (halaman Sensor Lab terbuka).
 * Listener dilepas saat Flutter membatalkan langganan atau activity dihancurkan.
 * Hanya sensor yang tidak butuh izin khusus yang diizinkan.
 */
class SensorStreamer(private val ctx: Context) : EventChannel.StreamHandler, SensorEventListener {

    companion object {
        /** Tipe sensor tanpa izin runtime: accel, magnet, gyro, light, pressure, proximity, gravity, dst. */
        val ALLOWED_TYPES = setOf(1, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13, 15, 20)
        private const val MIN_INTERVAL_MS = 150L
    }

    private val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val main = Handler(Looper.getMainLooper())
    private val lastSent = HashMap<Int, Long>()
    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        stop()
        sink = events
        val requested = (arguments as? List<*>)?.mapNotNull { (it as? Number)?.toInt() } ?: emptyList()
        for (type in requested) {
            if (type !in ALLOWED_TYPES) continue
            val sensor: Sensor = sm.getDefaultSensor(type) ?: continue
            try {
                sm.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL, main)
            } catch (e: Exception) {
                // Sensor tidak dapat didaftarkan; Dart akan menampilkan "tidak ada data".
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        stop()
    }

    fun stop() {
        sm.unregisterListener(this)
        lastSent.clear()
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        val out = sink ?: return
        val type = event.sensor.type
        val now = System.currentTimeMillis()
        val last = lastSent[type] ?: 0L
        if (now - last < MIN_INTERVAL_MS) return
        lastSent[type] = now
        val values = ArrayList<Double>(event.values.size)
        for (v in event.values) values.add(v.toDouble())
        val m = HashMap<String, Any?>()
        m["type"] = type
        m["values"] = values
        m["accuracy"] = event.accuracy
        out.success(m)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
