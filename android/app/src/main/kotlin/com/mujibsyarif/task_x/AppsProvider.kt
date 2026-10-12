package com.mujibsyarif.task_x

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import java.io.ByteArrayOutputStream
import java.io.File

/** Daftar aplikasi, ikon, aksi resmi (buka, info aplikasi, uninstall), dan statistik penggunaan opsional. */
class AppsProvider(private val ctx: Context) {

    fun count(): Int = ctx.packageManager.getInstalledPackages(0).size

    @Suppress("DEPRECATION")
    fun installedApps(): List<Map<String, Any?>> {
        val pm = ctx.packageManager
        val out = ArrayList<Map<String, Any?>>()
        for (pi in pm.getInstalledPackages(0)) {
            val ai = pi.applicationInfo ?: continue
            var size = File(ai.sourceDir ?: "").length()
            ai.splitSourceDirs?.forEach { size += File(it).length() }
            val m = HashMap<String, Any?>()
            m["package"] = pi.packageName
            m["label"] = pm.getApplicationLabel(ai).toString()
            m["versionName"] = pi.versionName
            m["versionCode"] = if (Build.VERSION.SDK_INT >= 28) pi.longVersionCode else pi.versionCode.toLong()
            m["isSystem"] = (ai.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
            m["isUpdatedSystem"] = (ai.flags and android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
            m["enabled"] = ai.enabled
            m["apkSize"] = size
            m["firstInstall"] = pi.firstInstallTime
            m["lastUpdate"] = pi.lastUpdateTime
            m["targetSdk"] = ai.targetSdkVersion
            m["minSdk"] = if (Build.VERSION.SDK_INT >= 24) ai.minSdkVersion else null
            m["category"] = if (Build.VERSION.SDK_INT >= 26) ai.category else -1
            m["canLaunch"] = pm.getLaunchIntentForPackage(pi.packageName) != null
            out.add(m)
        }
        return out
    }

    fun appIcon(pkg: String, px: Int): ByteArray? {
        val drawable = try {
            ctx.packageManager.getApplicationIcon(pkg)
        } catch (e: Exception) {
            return null
        }
        val bmp = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, px, px)
        drawable.draw(canvas)
        val out = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        bmp.recycle()
        return out.toByteArray()
    }

    fun launch(pkg: String): Boolean = try {
        val intent = ctx.packageManager.getLaunchIntentForPackage(pkg)
        if (intent == null) {
            false
        } else {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            ctx.startActivity(intent)
            true
        }
    } catch (e: Exception) {
        false
    }

    fun openAppInfo(pkg: String): Boolean = try {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$pkg"))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ctx.startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }

    /** Memakai alur uninstall resmi Android (pengguna tetap harus mengonfirmasi). */
    fun uninstall(pkg: String): Boolean = try {
        val intent = Intent(Intent.ACTION_DELETE, Uri.parse("package:$pkg"))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ctx.startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }

    @Suppress("DEPRECATION")
    fun hasUsageAccess(): Boolean {
        val ops = ctx.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= 29) {
            ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), ctx.packageName)
        } else {
            ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), ctx.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openUsageSettings(): Boolean = try {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ctx.startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }

    fun recentlyUsed(windowMs: Long): List<Map<String, Any?>> {
        if (!hasUsageAccess()) return emptyList()
        val usm = ctx.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val begin = end - windowMs
        val stats = usm.queryAndAggregateUsageStats(begin, end)
        val out = ArrayList<Map<String, Any?>>()
        for (s in stats.values) {
            if (s.lastTimeUsed <= begin && s.totalTimeInForeground <= 0L) continue
            val m = HashMap<String, Any?>()
            m["package"] = s.packageName
            m["lastUsed"] = s.lastTimeUsed
            m["foregroundMs"] = s.totalTimeInForeground
            out.add(m)
        }
        return out
    }
}
