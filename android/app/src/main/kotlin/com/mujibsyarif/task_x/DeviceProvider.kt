package com.mujibsyarif.task_x

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInfo
import android.hardware.Sensor
import android.hardware.SensorManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.os.BatteryManager
import android.os.Build
import android.os.Debug
import android.os.Environment
import android.os.Process
import android.os.StatFs
import android.os.SystemClock
import java.io.File

/**
 * Membaca informasi perangkat memakai API resmi Android saja.
 * Nilai yang tidak dapat dibaca dikembalikan sebagai null (bukan angka karangan).
 */
class DeviceProvider(private val ctx: Context) {

    fun deviceInfo(): Map<String, Any?> {
        val dm = ctx.resources.displayMetrics
        val pkg: PackageInfo? = try {
            ctx.packageManager.getPackageInfo(ctx.packageName, 0)
        } catch (e: Exception) {
            null
        }
        val info = HashMap<String, Any?>()
        info["model"] = Build.MODEL
        info["manufacturer"] = Build.MANUFACTURER
        info["brand"] = Build.BRAND
        info["device"] = Build.DEVICE
        info["hardware"] = Build.HARDWARE
        info["board"] = Build.BOARD
        info["androidVersion"] = Build.VERSION.RELEASE
        info["sdkInt"] = Build.VERSION.SDK_INT
        info["securityPatch"] = if (Build.VERSION.SDK_INT >= 23) Build.VERSION.SECURITY_PATCH else null
        info["soc"] = if (Build.VERSION.SDK_INT >= 31) Build.SOC_MODEL else null
        info["abis"] = Build.SUPPORTED_ABIS.toList()
        info["cpuCores"] = Runtime.getRuntime().availableProcessors()
        info["screenWidthPx"] = dm.widthPixels
        info["screenHeightPx"] = dm.heightPixels
        info["densityDpi"] = dm.densityDpi
        info["density"] = dm.density.toDouble()
        info["appVersion"] = pkg?.versionName
        info["appBuild"] = if (pkg != null) versionCodeOf(pkg) else 0L
        return info
    }

    @Suppress("DEPRECATION")
    private fun versionCodeOf(pi: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) pi.longVersionCode else pi.versionCode.toLong()

    fun uptimeMs(): Long = SystemClock.elapsedRealtime()

    fun memory(): Map<String, Any?> {
        val am = ctx.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mi = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mi)
        val m = HashMap<String, Any?>()
        m["total"] = mi.totalMem
        m["avail"] = mi.availMem
        m["threshold"] = mi.threshold
        m["low"] = mi.lowMemory
        return m
    }

    fun ownProcess(): Map<String, Any?> {
        val mi = Debug.MemoryInfo()
        Debug.getMemoryInfo(mi)
        val m = HashMap<String, Any?>()
        m["pid"] = Process.myPid()
        m["pssKb"] = mi.totalPss
        m["cacheBytes"] = dirSize(ctx.cacheDir)
        m["filesBytes"] = dirSize(ctx.filesDir)
        return m
    }

    fun clearOwnCache(): Long {
        val before = dirSize(ctx.cacheDir)
        ctx.cacheDir.listFiles()?.forEach { it.deleteRecursively() }
        val after = dirSize(ctx.cacheDir)
        return if (before > after) before - after else 0L
    }

    private fun dirSize(dir: File?): Long {
        if (dir == null || !dir.exists()) return 0L
        var total = 0L
        dir.walkTopDown().forEach { if (it.isFile) total += it.length() }
        return total
    }

    fun storage(): Map<String, Any?> {
        val st = StatFs(Environment.getDataDirectory().path)
        val m = HashMap<String, Any?>()
        m["total"] = st.blockCountLong * st.blockSizeLong
        m["avail"] = st.availableBlocksLong * st.blockSizeLong
        return m
    }

    fun battery(): Map<String, Any?> {
        val i: Intent? = ctx.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = i?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = i?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val temp = i?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE) ?: Int.MIN_VALUE
        val volt = i?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
        val bm = ctx.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val current = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)

        val m = HashMap<String, Any?>()
        m["percent"] = if (level >= 0 && scale > 0) level * 100 / scale else null
        m["status"] = i?.getIntExtra(BatteryManager.EXTRA_STATUS, 1) ?: 1
        m["plugged"] = i?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0
        m["health"] = i?.getIntExtra(BatteryManager.EXTRA_HEALTH, 1) ?: 1
        m["temperatureC"] = if (temp != Int.MIN_VALUE) temp / 10.0 else null
        m["voltageMv"] = if (volt > 0) volt else null
        m["technology"] = i?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY)
        m["currentNowUa"] = if (current != Int.MIN_VALUE) current else null
        return m
    }

    fun network(): Map<String, Any?> {
        val cm = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val net = cm.activeNetwork
        val caps = if (net != null) cm.getNetworkCapabilities(net) else null
        var type = "none"
        var vpn = false
        var validated = false
        var metered = false
        var down: Int? = null
        var up: Int? = null
        if (caps != null) {
            type = when {
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH) -> "bluetooth"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
                else -> "other"
            }
            vpn = caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
            validated = caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            metered = !caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
            down = caps.linkDownstreamBandwidthKbps
            up = caps.linkUpstreamBandwidthKbps
        }
        val m = HashMap<String, Any?>()
        m["type"] = type
        m["vpn"] = vpn
        m["validated"] = validated
        m["metered"] = metered
        m["downKbps"] = down
        m["upKbps"] = up
        m["rxBytes"] = nonNegative(TrafficStats.getTotalRxBytes())
        m["txBytes"] = nonNegative(TrafficStats.getTotalTxBytes())
        m["mobileRxBytes"] = nonNegative(TrafficStats.getMobileRxBytes())
        m["mobileTxBytes"] = nonNegative(TrafficStats.getMobileTxBytes())
        return m
    }

    private fun nonNegative(v: Long): Long? = if (v >= 0) v else null

    fun cpu(): Map<String, Any?> {
        val cores = Runtime.getRuntime().availableProcessors()
        val cur = ArrayList<Long?>()
        val max = ArrayList<Long?>()
        for (n in 0 until cores) {
            cur.add(readLong("/sys/devices/system/cpu/cpu$n/cpufreq/scaling_cur_freq"))
            max.add(readLong("/sys/devices/system/cpu/cpu$n/cpufreq/cpuinfo_max_freq"))
        }
        val m = HashMap<String, Any?>()
        m["cores"] = cores
        m["curKhz"] = cur
        m["maxKhz"] = max
        m["stat"] = readProcStat()
        return m
    }

    private fun readLong(path: String): Long? = try {
        File(path).readText().trim().toLong()
    } catch (e: Exception) {
        null
    }

    /** /proc/stat dibatasi SELinux di Android modern; null berarti tidak dapat dibaca. */
    private fun readProcStat(): List<Long>? = try {
        val line = File("/proc/stat").bufferedReader().use { r -> r.readLine() }
        if (line != null && line.startsWith("cpu ")) {
            val nums = line.trim().split(Regex("\\s+")).drop(1).mapNotNull { it.toLongOrNull() }
            if (nums.size >= 5) nums else null
        } else {
            null
        }
    } catch (e: Exception) {
        null
    }

    fun sensors(): List<Map<String, Any?>> {
        val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        return sm.getSensorList(Sensor.TYPE_ALL).map { s ->
            val m = HashMap<String, Any?>()
            m["name"] = s.name
            m["vendor"] = s.vendor
            m["type"] = s.stringType
            m["power"] = s.power.toDouble()
            m
        }
    }
}
