package com.example.androidopenssl;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class SimpleOpenSSLModule extends ReactContextBaseJavaModule {

    static {
        System.loadLibrary("ssl_jni");
    }

    public SimpleOpenSSLModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "SimpleOpenSSL";
    }

    private static native String sha256Hex(String input);

    @ReactMethod
    public void sha256(String input, Promise promise) {
        try {
            String out = sha256Hex(input == null ? "" : input);
            promise.resolve(out);
        } catch (Exception e) {
            promise.reject("ERR_OPENSSL", e);
        }
    }
}
