package com.example.scanproai.scanpro_ai

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.channel.shared.data"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSharedData") {
                handleIntent(intent, result)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun getInitialRoute(): String {
        return "/"
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // Update the intent so it can be handled
    }

    private fun handleIntent(intent: Intent, result: MethodChannel.Result) {
        val action = intent.action
        val type = intent.type

        if ((Intent.ACTION_SEND == action || Intent.ACTION_VIEW == action) && type != null) {
            val extension = when (type) {
                "application/pdf" -> ".pdf"
                "application/msword" -> ".doc"
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document" -> ".docx"
                else -> null
            }

            if (extension != null) {
                val uri = intent.data ?: intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                if (uri != null) {
                    val filePath = copyUriToCache(uri, extension)
                    if (filePath != null) {
                        result.success(filePath)
                        return
                    }
                }
            }
        }
        result.success("")
    }

    private fun copyUriToCache(uri: Uri, extension: String): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val file = java.io.File(cacheDir, "shared_document_${System.currentTimeMillis()}$extension")
            val outputStream = java.io.FileOutputStream(file)
            inputStream.copyTo(outputStream)
            inputStream.close()
            outputStream.close()
            file.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
