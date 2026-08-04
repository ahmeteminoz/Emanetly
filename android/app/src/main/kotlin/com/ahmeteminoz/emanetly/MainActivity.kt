package com.ahmeteminoz.emanetly

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // onNewIntent override'ı olmadan Android, uygulama zaten açıkken
    // gelen FCM intent'ini FirebaseMessaging plugin'ine iletmiyor.
    // Bu sayede onMessageOpenedApp stream'i her bildirim tap'inde tetiklenir.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
