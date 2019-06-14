

package com.jovial.misc.bluetooth.im;

import android.inputmethodservice.InputMethodService
import android.view.KeyEvent

/**
 * A simple input method, so that I can type French characters on my tablet using
 * that Bluetooth keyboard I bought.  My escape sequences are close to what
 * Linux does.  They're just hard-coded; I didn't make a fancy UI to configure
 * the key sequences.
 */

class JovialAccentedKeyboard : InputMethodService() {

    override fun onCreate() {
        super.onCreate()
        println("@@ JovialAccentedKeyboard.onCreate()")
    }

    override fun onBindInput() {
        println("@@ JAK onBindInput()")
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        println("@@ JAK keyDown $keyCode $event")
        if (keyCode == KeyEvent.KEYCODE_E) {
            currentInputConnection.commitText("é", 1)

            println("  @@ consumed G down")
            return  true
        } else {
            return super.onKeyDown(keyCode, event)
        }
    }
}