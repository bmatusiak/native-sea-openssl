package com.example.examplernapp;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.example.androidopenssl.SimpleOpenSSL;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(24, 48, 24, 24);

        TextView title = new TextView(this);
        title.setText("native-sea-openssl Example");
        title.setTextSize(20);
        root.addView(title);

        final TextView output = new TextView(this);
        output.setText("Press the button to run native SHA-256 test");
        root.addView(output);

        Button btn = new Button(this);
        btn.setText("Call OpenSSL sha256");
        btn.setOnClickListener(new ClickHandler(output));
        root.addView(btn);
        setContentView(root);

    }

    private static class ClickHandler implements View.OnClickListener {
        private final TextView output;

        ClickHandler(TextView output) {
            this.output = output;
        }

        @Override
        public void onClick(View v) {
            try {
                String test = "test";
                String nativeRes = SimpleOpenSSL.sha256Hex(test);
                String expected = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08";
                boolean ok = nativeRes != null && nativeRes.toLowerCase().equals(expected);
                output.setText("Input: \"" + test + "\"\nNative: " + nativeRes + "\nMatch: " + ok);
            } catch (Throwable t) {
                output.setText("Native call failed: " + t.getMessage());
            }
        }
    }

}
