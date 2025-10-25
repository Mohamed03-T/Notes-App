package com.example.note_app.note_app

import android.app.Application
import android.util.Log
import androidx.work.Configuration
import androidx.work.WorkManager

class AppApplication : Application(), Configuration.Provider {
    override fun onCreate() {
        super.onCreate()
        try {
            Log.d("AppApplication", "Initializing WorkManager from Application")
            // Initialize WorkManager with default configuration
            WorkManager.initialize(this, workManagerConfiguration)
        } catch (e: Exception) {
            Log.w("AppApplication", "WorkManager init failed: ${e.localizedMessage}")
        }
    }

    override fun getWorkManagerConfiguration(): Configuration {
        return Configuration.Builder()
            .setMinimumLoggingLevel(Log.DEBUG)
            .build()
    }
}
