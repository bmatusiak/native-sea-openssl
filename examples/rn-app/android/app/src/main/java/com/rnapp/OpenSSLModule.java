package com.rnapp;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

public class OpenSSLModule extends ReactContextBaseJavaModule {

    static {
        try {
            System.loadLibrary("rnopenssl");
        } catch (UnsatisfiedLinkError e) {
            // library may be in AAR prefab; fallback is OK
        }
    }

    public OpenSSLModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "OpenSSL";
    }

    private native String sha256Native(String input);

    @ReactMethod
    public void sha256(String input, Promise p) {
        try {
            String out = sha256Native(input);
            p.resolve(out);
        } catch (Throwable t) {
            p.reject("ERR", t);
        }
    }
}
package com.rnapp;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class OpenSSLModule extends ReactContextBaseJavaModule {

    static {
        try {
            System.loadLibrary("rnopenssl");
        } catch (UnsatisfiedLinkError e) {
            // ignore during dev
        }
    }

    public OpenSSLModule(ReactApplicationContext ctx) {
        super(ctx);
    }

    @Override
    public String getName() {
        return "OpenSSLModule";
    }

    private static native String sha256Native(String input);

    @ReactMethod
    public void sha256(String input, Promise promise) {
        try {
            String out = sha256Native(input == null ? "" : input);
            promise.resolve(out);
        } catch (Exception e) {
            promise.reject("ERR", e.getMessage());
        }
    }
}
