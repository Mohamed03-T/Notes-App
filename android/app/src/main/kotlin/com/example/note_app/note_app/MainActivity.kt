package com.example.note_app.note_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "noty/storage"
	private var pendingResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"requestTreeAccess" -> {
					// Start ACTION_OPEN_DOCUMENT_TREE
					if (pendingResult != null) {
						result.error("ALREADY_PENDING", "Another request is pending", null)
						return@setMethodCallHandler
					}
					pendingResult = result
					val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
						putExtra("android.content.extra.SHOW_ADVANCED", true)
						putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false)
					}
					startActivityForResult(intent, 42424)
				}
				"writeFileToTree" -> {
					val treeUri = call.argument<String>("treeUri")
					val fileName = call.argument<String>("fileName")
					val bytes = call.argument<ByteArray>("bytes")
					if (treeUri == null || fileName == null || bytes == null) {
						result.error("ARGUMENT_ERROR", "treeUri/fileName/bytes required", null)
						return@setMethodCallHandler
					}
					try {
						val tree = DocumentFile.fromTreeUri(this, Uri.parse(treeUri))
						if (tree == null) {
							result.error("TREE_ERROR", "Cannot access tree", null)
							return@setMethodCallHandler
						}
						// Try to create file (delete existing if present)
						val existing = tree.findFile(fileName)
						existing?.delete()
						val file = tree.createFile("application/json", fileName)
						if (file == null) {
							result.error("CREATE_FAILED", "Failed to create file in tree", null)
							return@setMethodCallHandler
						}
						contentResolver.openOutputStream(file.uri).use { out ->
							out?.write(bytes)
							out?.flush()
						}
						result.success(true)
					} catch (e: Exception) {
						result.error("WRITE_ERROR", e.localizedMessage, null)
					}
				}
				"pruneTreeBackups" -> {
					val treeUri = call.argument<String>("treeUri")
					val prefix = call.argument<String>("prefix") ?: "noty_backup_"
					val keep = call.argument<Int>("keep") ?: 3
					if (treeUri == null) {
						result.error("ARGUMENT_ERROR", "treeUri required", null)
						return@setMethodCallHandler
					}
					try {
						val tree = DocumentFile.fromTreeUri(this, Uri.parse(treeUri))
						if (tree == null) {
							result.error("TREE_ERROR", "Cannot access tree", null)
							return@setMethodCallHandler
						}
						val files = tree.listFiles().filter { it.name?.startsWith(prefix) == true }
						val sorted = files.sortedByDescending { it.lastModified() }
						val toDelete = sorted.drop(keep)
						for (f in toDelete) {
							try { f.delete() } catch (_: Exception) { }
						}
						result.success(true)
					} catch (e: Exception) {
						result.error("PRUNE_ERROR", e.localizedMessage, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)
		if (requestCode == 42424) {
			val result = pendingResult
			pendingResult = null
			if (resultCode == Activity.RESULT_OK && data != null) {
				val uri = data.data
				if (uri != null) {
					try {
							// Persist permission using the flags provided by the returned intent (more reliable)
							try {
								val takeFlags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
								contentResolver.takePersistableUriPermission(uri, takeFlags)
								Log.d("MainActivity", "takePersistableUriPermission called with flags=$takeFlags for uri=$uri")
							} catch (e: Exception) {
								Log.d("MainActivity", "takePersistableUriPermission failed: ${e.localizedMessage}")
							}
					} catch (e: Exception) {
						// ignore
					}
					result?.success(uri.toString())
					return
				}
			}
			result?.success(null)
		}
	}
}
