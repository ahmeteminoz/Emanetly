package com.ahmeteminoz.emanetly

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Firebase Messaging'in arka planda gelen notification intent'lerini
    // uygulama zaten açıkken de alabilmesi için onNewIntent override edildi.
    // Bu olmadan tıklanan 2. push bildirimi onMessageOpenedApp'e iletilmiyordu.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
