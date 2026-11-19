// ⚠️ La ligne « package » ci-dessous n'est qu'un EXEMPLE. Remplace-la par la
// 1re ligne du MainActivity.kt d'origine de ton projet (celui que ce fichier
// remplace). Si elle est différente, Android garde l'ancien fichier et les
// jauges restent vides. Voir README, étape 3.
package com.example.game_launcher

import android.app.ActivityManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * Pont Android : liste/lancement des jeux, batterie, RAM, « Ne pas déranger ».
 * Le nom du canal doit rester identique à celui de lib/core/native_bridge.dart.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "gamelauncher/native"
        private const val ICON_SIZE_PX = 192
    }

    // Les tâches lourdes (icônes, nettoyage) tournent hors du thread principal.
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> onCall(call, result) }
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getGames" -> {
                val includeAll = call.argument<Boolean>("includeAll") ?: false
                background(result) { listGames(includeAll) }
            }
            "launchGame" -> result.success(launchGame(call.argument<String>("package")))
            "getBattery" -> result.success(batteryInfo())
            "getMemory" -> result.success(memoryInfo())
            "cleanRam" -> {
                val keep = call.argument<String>("keep")
                background(result) { cleanRam(keep) }
            }
            "dndStatus" -> result.success(dndStatus())
            "openDndSettings" -> {
                openDndSettings()
                result.success(null)
            }
            "setDnd" -> result.success(setDnd(call.argument<Boolean>("enabled") ?: false))
            else -> result.notImplemented()
        }
    }

    /** Exécute [work] sur un thread de fond, puis répond sur le thread principal. */
    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        executor.execute {
            try {
                val value = work()
                mainHandler.post { result.success(value) }
            } catch (e: Throwable) {
                // Throwable (et pas Exception) : une erreur mémoire sur les icônes
                // doit repartir vers Dart sans arrêter l'appli.
                mainHandler.post { result.error("native_error", e.message, null) }
            }
        }
    }

    // ------------------------------------------------------------------ Jeux

    private fun isGame(info: ApplicationInfo): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            info.category == ApplicationInfo.CATEGORY_GAME
        ) return true
        @Suppress("DEPRECATION")
        return (info.flags and ApplicationInfo.FLAG_IS_GAME) != 0
    }

    private fun launcherIntent(): Intent =
        Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)

    @Suppress("DEPRECATION")
    private fun listGames(includeAll: Boolean): List<Map<String, Any?>> {
        val pm = packageManager
        val seen = HashSet<String>()
        val out = ArrayList<Map<String, Any?>>()

        for (ri in pm.queryIntentActivities(launcherIntent(), 0)) {
            val pkg = ri.activityInfo.packageName
            if (pkg == packageName || !seen.add(pkg)) continue
            val game = isGame(ri.activityInfo.applicationInfo)
            if (!includeAll && !game) continue
            out.add(
                mapOf(
                    "name" to ri.loadLabel(pm).toString(),
                    "package" to pkg,
                    "icon" to iconPng(ri.loadIcon(pm)),
                    "isGame" to game
                )
            )
        }
        // Les jeux d'abord, puis l'ordre alphabétique.
        out.sortWith(
            compareByDescending<Map<String, Any?>> { it["isGame"] as Boolean }
                .thenBy { (it["name"] as String).lowercase() }
        )
        return out
    }

    private fun iconPng(drawable: Drawable): ByteArray? {
        return try {
            val bmp = Bitmap.createBitmap(ICON_SIZE_PX, ICON_SIZE_PX, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, ICON_SIZE_PX, ICON_SIZE_PX)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
            bmp.recycle()
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    private fun launchGame(pkg: String?): Boolean {
        if (pkg.isNullOrEmpty()) return false
        val intent = packageManager.getLaunchIntentForPackage(pkg) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    // ------------------------------------------------- Batterie / température

    private fun batteryInfo(): Map<String, Any> {
        val i = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = i?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = i?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val percent = if (level >= 0 && scale > 0) level * 100 / scale else -1
        // Android donne la température en dixièmes de °C (352 = 35,2 °C).
        val tenths = i?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        val status = i?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL

        var thermal = -1
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            thermal = pm.currentThermalStatus
        }
        return mapOf(
            "level" to percent,
            "tempC" to tenths / 10.0,
            "charging" to charging,
            "thermal" to thermal
        )
    }

    // --------------------------------------------------------------------- RAM

    private fun memInfo(am: ActivityManager): ActivityManager.MemoryInfo {
        val info = ActivityManager.MemoryInfo()
        am.getMemoryInfo(info)
        return info
    }

    private fun memoryInfo(): Map<String, Any> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val m = memInfo(am)
        return mapOf("availMb" to m.availMem / 1048576L, "totalMb" to m.totalMem / 1048576L)
    }

    /**
     * Ferme les processus d'ARRIÈRE-PLAN des applis installées. Android refuse
     * de fermer l'appli au premier plan et les applis système ; certaines
     * applis seront relancées par le système, donc le gain est souvent partiel.
     * [keep] = le jeu qu'on va lancer : on ne le ferme pas.
     */
    @Suppress("DEPRECATION")
    private fun cleanRam(keep: String?): Map<String, Any> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val pm = packageManager
        val before = memInfo(am).availMem / 1048576L

        val protectedPkgs = HashSet<String>()
        protectedPkgs.add(packageName)
        if (!keep.isNullOrEmpty()) protectedPkgs.add(keep)
        val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        for (ri in pm.queryIntentActivities(home, 0)) protectedPkgs.add(ri.activityInfo.packageName)

        for (ri in pm.queryIntentActivities(launcherIntent(), 0)) {
            val pkg = ri.activityInfo.packageName
            if (pkg in protectedPkgs) continue
            val flags = ri.activityInfo.applicationInfo.flags
            val pureSystem = (flags and ApplicationInfo.FLAG_SYSTEM) != 0 &&
                (flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0
            if (pureSystem) continue
            am.killBackgroundProcesses(pkg)
        }

        // Laisse au système le temps de récupérer la mémoire avant de re-mesurer.
        Thread.sleep(900)
        val m = memInfo(am)
        return mapOf(
            "availBeforeMb" to before,
            "availAfterMb" to m.availMem / 1048576L,
            "totalMb" to m.totalMem / 1048576L
        )
    }

    // ------------------------------------------------------- Ne pas déranger

    private fun notificationManager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun dndStatus(): Map<String, Any> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return mapOf("granted" to false, "active" to false)
        }
        val nm = notificationManager()
        val filter = nm.currentInterruptionFilter
        val active = filter == NotificationManager.INTERRUPTION_FILTER_PRIORITY ||
            filter == NotificationManager.INTERRUPTION_FILTER_ALARMS ||
            filter == NotificationManager.INTERRUPTION_FILTER_NONE
        return mapOf("granted" to nm.isNotificationPolicyAccessGranted, "active" to active)
    }

    private fun openDndSettings() {
        try {
            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            // Écran introuvable sur certains appareils : on ignore.
        }
    }

    /**
     * PRIORITY = le « Ne pas déranger » habituel (appels de favoris et alarmes
     * restent autorisés selon les réglages du téléphone). ALL = tout rétabli.
     */
    private fun setDnd(enabled: Boolean): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val nm = notificationManager()
        if (!nm.isNotificationPolicyAccessGranted) return false
        nm.setInterruptionFilter(
            if (enabled) NotificationManager.INTERRUPTION_FILTER_PRIORITY
            else NotificationManager.INTERRUPTION_FILTER_ALL
        )
        return true
    }
}
