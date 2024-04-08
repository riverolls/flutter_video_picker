package com.riverolls.picker

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors


/** 视频获取插件 */
class VideoPickerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {

    /** 函数通道 */
    private lateinit var channel: MethodChannel

    /** 用于读取视频等 */
    private var activity: Activity? = null

    /** 视频返回回调 */
    private var videoResult: Result? = null

    /** 线程是用于处理视频 */
    private val executor by lazy { Executors.newSingleThreadExecutor() }

    /** 选择图库 */
    private fun chooseVideoFromGallery(result: Result) {
        finishWithCancel()
        videoResult = result

        val activity = this.activity
        if (activity == null) {
            finishWithCancel()
            return
        }

        val request = PickVisualMediaRequest.Builder()
            .setMediaType(ActivityResultContracts.PickVisualMedia.VideoOnly)
            .build()
        val it: Intent = ActivityResultContracts.PickVisualMedia().createIntent(activity, request)
        activity.startActivityForResult(it, REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY)
    }

    /** 处理图片结果 */
    private fun handleChooseVideoResult(resultCode: Int, data: Intent?) {
        if (resultCode == Activity.RESULT_OK && data != null) {
            var uri = data.data
            // 处理在 Android 13 之前的设备返回可能为空的情况
            if (uri == null) {
                val clipData = data.clipData
                if (clipData != null && clipData.itemCount == 1) {
                    uri = clipData.getItemAt(0).uri
                }
            }
            // 不存在有效视频
            if (uri == null) {
                finishWithCancel()
                return
            }
            val path = getPathFromUri(activity!!, uri)
            handleVideoResult(path)
            return
        }

        // User cancelled choosing a picture.
        finishWithCancel()
    }

    /** 清理文件夹 */
    private fun cleanFolder(context: Context) {
        try {
            val targetDirectory = File(context.cacheDir, "video_picker")
            if (!targetDirectory.exists()) return
            val files = targetDirectory.listFiles() ?: return
            for (file in files) {
                try {
                    file.delete()
                } catch (ex: IOException) {
                    // ignore
                }
            }
        } catch (ex: IOException) {
            ex.printStackTrace()
        }
    }

    private fun handleVideoResult(path: String?) {
        videoResult?.success(path)
        videoResult = null
    }

    private fun finishWithCancel() {
        videoResult?.success(null)
        videoResult = null
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.rr.video.picker")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "chooseVideoFromGallery" -> chooseVideoFromGallery(result)
            "clean" -> executor.execute {
                cleanFolder(activity!!)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

    }

    ////////////////////////////////////////////////////////////////////////////////////////////////

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val call = when (requestCode) {
            REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY -> Runnable {
                handleChooseVideoResult(resultCode, data)
            }

            else -> return false
        }

        executor.execute(call)
        return true
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////

    /** 复制文件到临时目录 */
    private fun getPathFromUri(context: Context, uri: Uri): String? {
        try {
            context.contentResolver.openInputStream(uri).use { inputStream ->
                val targetDirectory = File(context.cacheDir, "video_picker")
                if (!targetDirectory.exists()) targetDirectory.mkdir()
                var extension = getVideoExtension(context, uri)
                if (extension == null) extension = ".mp4"
                val uuid = UUID.randomUUID().toString()
                val file = File(targetDirectory, "picker_$uuid$extension")
                FileOutputStream(file).use { inputStream?.copyTo(it) }
                file.deleteOnExit() // 在应用关闭时删除文件，可能不稳定
                return file.absolutePath
            }
        } catch (e: IOException) {
            // If closing the output stream fails, we cannot be sure that the
            // target file was written in full. Flushing the stream merely moves
            // the bytes into the OS, not necessarily to the file.
            return null
        } catch (e: SecurityException) {
            // Calling `ContentResolver#openInputStream()` has been reported to throw a
            // `SecurityException` on some devices in certain circumstances. Instead of crashing, we
            // return `null`.
            //
            // See https://github.com/flutter/flutter/issues/100025 for more details.
            return null
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////

    companion object {
        private const val REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY = 0xFD1

        /** 获取视频扩展名 */
        private fun getVideoExtension(context: Context, video: Uri): String? {
            val extension: String? = try {
                if (video.scheme == ContentResolver.SCHEME_CONTENT) {
                    val mime = MimeTypeMap.getSingleton()
                    mime.getExtensionFromMimeType(context.contentResolver.getType(video))
                } else {
                    MimeTypeMap.getFileExtensionFromUrl(Uri.fromFile(File(video.path!!)).toString())
                }
            } catch (e: Exception) {
                return null
            }
            return if (extension.isNullOrEmpty()) null else ".$extension"
        }
    }
}
