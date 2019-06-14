package com.jovial.misc.bluetooth.im

import android.content.Context
import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.view.inputmethod.InputMethodInfo
import android.content.Context.INPUT_METHOD_SERVICE
import android.support.v4.content.ContextCompat.getSystemService
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.Toast


class SettingsActivity : AppCompatActivity() {


    private val ui by lazy {
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_settings)
        val dismissButton : Button = findViewById(R.id.dismiss_button)
        dismissButton.setOnClickListener( { finish() })
    }

    override fun onResume() {
        super.onResume()
        println("@@ SettingsActivity onResume")

        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val enabled = imm.getEnabledInputMethodList()

        for (service in enabled) {
            println("  @@ ${service.serviceName} : $service")
        }

        Toast.makeText(this, "Jovial Accented Keyboard installed", Toast.LENGTH_LONG).show()

    }
}
