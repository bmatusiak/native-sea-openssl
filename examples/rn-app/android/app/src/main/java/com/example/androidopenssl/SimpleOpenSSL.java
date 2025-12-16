package com.example.androidopenssl;

public class SimpleOpenSSL {
    public static native String sha256Hex(String input);

    static {
        try {
            System.loadLibrary("ssl_jni");
        } catch (UnsatisfiedLinkError e) {
            // library may already be loaded from AAR; ignore if not available here
        }
    }
}
