package com.facebook.react.bridge;

public class ReactContextBaseJavaModule implements NativeModule {
    protected ReactApplicationContext reactContext;
    public ReactContextBaseJavaModule(ReactApplicationContext ctx) { this.reactContext = ctx; }
    public String getName() { return "ReactContextBaseJavaModule"; }
}
