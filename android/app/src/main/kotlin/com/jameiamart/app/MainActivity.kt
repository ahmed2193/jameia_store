package com.jameiamart.app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // The first Flutter frame repeats the launch screen exactly (same
            // green, same cart, same place — features/splash), so drop the
            // system splash at once. The default exit fades the icon out over
            // the green and then fades the app in, which dimmed the logo.
            splashScreen.setOnExitAnimationListener { view -> view.remove() }
        }
    }
}
