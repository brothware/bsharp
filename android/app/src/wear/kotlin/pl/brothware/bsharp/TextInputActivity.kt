package pl.brothware.bsharp

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText

/// A screen whose only job is to hold a real EditText.
///
/// The watch keyboard fills the screen and keeps its own copy of the text up
/// there, refreshed through the extract UI that Android drives from an
/// EditText. Flutter draws its fields itself and has none, so that copy stops
/// after the first letter and the wearer types blind. One native field for the
/// duration of the typing costs nothing and the keyboard behaves.
class TextInputActivity : Activity() {
    companion object {
        const val EXTRA_LABEL = "label"
        const val EXTRA_TEXT = "text"
    }

    private lateinit var field: EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        field = EditText(this).apply {
            setBackgroundColor(Color.BLACK)
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            hint = intent.getStringExtra(EXTRA_LABEL)
            setText(intent.getStringExtra(EXTRA_TEXT).orEmpty())
            setSelection(text.length)
            inputType = InputType.TYPE_CLASS_TEXT
            imeOptions = EditorInfo.IME_ACTION_DONE
            isSingleLine = true
            setOnEditorActionListener { _, actionId, _ ->
                if (actionId == EditorInfo.IME_ACTION_DONE) finishWithText()
                true
            }
        }

        setContentView(field)
        field.requestFocus()
    }

    /// The keyboard is asked for here rather than in onCreate: until the
    /// window holds input focus there is nothing for the input method to
    /// attach to, so the request made while starting up is dropped and the
    /// wearer has to tap the field again to raise it.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) return

        field.requestFocus()
        val manager = getSystemService(Context.INPUT_METHOD_SERVICE)
            as InputMethodManager
        manager.showSoftInput(field, InputMethodManager.SHOW_IMPLICIT)
    }

    /// Backing out keeps what was typed: on a watch the keyboard covers the
    /// screen, so its back gesture is the only way off it.
    override fun onBackPressed() = finishWithText()

    private fun finishWithText() {
        setResult(
            RESULT_OK,
            Intent().putExtra(EXTRA_TEXT, field.text.toString()),
        )
        finish()
    }
}
