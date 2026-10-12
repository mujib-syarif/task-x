package com.mujibsyarif.task_x

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** Jembatan Flutter <-> Android. Seluruh logika data ada di kelas Provider terpisah. */
class MainActivity : FlutterActivity() {

    private val channelName = "taskx/native"
    private val executor = Executors.newFixedThreadPool(2)

    private val device by lazy { DeviceProvider(this) }
    private val apps by lazy { AppsProvider(this) }
    private val scanner by lazy { StorageScanner(this) }

    private val reqPickTree = 4101
    private val reqCreateDoc = 4102
    private var pendingResult: MethodChannel.Result? = null
    private var pendingContent: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun async(result: MethodChannel.Result, block: () -> Any?) {
        executor.execute {
            try {
                val value = block()
                runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                runOnUiThread { result.error("native_error", e.message, null) }
            }
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "deviceInfo" -> result.success(device.deviceInfo())
                "uptimeMs" -> result.success(device.uptimeMs())
                "memory" -> result.success(device.memory())
                "storage" -> result.success(device.storage())
                "battery" -> result.success(device.battery())
                "network" -> result.success(device.network())
                "cpu" -> result.success(device.cpu())
                "sensors" -> result.success(device.sensors())
                "ownProcess" -> async(result) { device.ownProcess() }
                "clearOwnCache" -> async(result) { device.clearOwnCache() }

                "appCount" -> async(result) { apps.count() }
                "installedApps" -> async(result) { apps.installedApps() }
                "appIcon" -> {
                    val pkg = call.argument<String>("package") ?: ""
                    val size = call.argument<Int>("size") ?: 96
                    async(result) { apps.appIcon(pkg, size) }
                }
                "launchApp" -> result.success(apps.launch(call.argument<String>("package") ?: ""))
                "openAppInfo" -> result.success(apps.openAppInfo(call.argument<String>("package") ?: ""))
                "openOwnAppInfo" -> result.success(apps.openAppInfo(packageName))
                "uninstallApp" -> result.success(apps.uninstall(call.argument<String>("package") ?: ""))
                "hasUsageAccess" -> result.success(apps.hasUsageAccess())
                "openUsageSettings" -> result.success(apps.openUsageSettings())
                "recentlyUsed" -> {
                    val windowMs = call.argument<Number>("windowMs")?.toLong() ?: 86400000L
                    async(result) { apps.recentlyUsed(windowMs) }
                }

                "pickDirectory" -> startPicker(result)
                "scanDirectory" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    val topN = call.argument<Int>("topN") ?: 50
                    val maxFiles = call.argument<Int>("maxFiles") ?: 200000
                    async(result) { scanner.scan(uri, topN, maxFiles) }
                }
                "openDocument" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    val mime = call.argument<String>("mime") ?: "*/*"
                    result.success(openDocument(uri, mime))
                }
                "saveTextFile" -> {
                    startSaveText(
                        result,
                        call.argument<String>("name") ?: "taskx_report.txt",
                        call.argument<String>("content") ?: "",
                    )
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("native_error", e.message, null)
        }
    }

    private fun startPicker(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Operasi lain sedang berjalan", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        startActivityForResult(intent, reqPickTree)
    }

    private fun startSaveText(result: MethodChannel.Result, name: String, content: String) {
        if (pendingResult != null) {
            result.error("busy", "Operasi lain sedang berjalan", null)
            return
        }
        pendingResult = result
        pendingContent = content
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        intent.type = "text/plain"
        intent.putExtra(Intent.EXTRA_TITLE, name)
        startActivityForResult(intent, reqCreateDoc)
    }

    private fun openDocument(uri: String, mime: String): Boolean = try {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.setDataAndType(Uri.parse(uri), mime)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != reqPickTree && requestCode != reqCreateDoc) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingResult
        val content = pendingContent
        pendingResult = null
        pendingContent = null
        if (result == null) return

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        if (requestCode == reqPickTree) {
            try {
                contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (e: Exception) {
                // Izin persisten tidak wajib; folder tetap dapat dipindai pada sesi ini.
            }
            result.success(uri.toString())
        } else {
            executor.execute {
                try {
                    contentResolver.openOutputStream(uri)?.use { it.write((content ?: "").toByteArray()) }
                    runOnUiThread { result.success(uri.toString()) }
                } catch (e: Exception) {
                    runOnUiThread { result.error("write_failed", e.message, null) }
                }
            }
        }
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }
}
