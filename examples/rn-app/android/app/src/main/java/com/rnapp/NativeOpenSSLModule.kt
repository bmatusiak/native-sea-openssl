package com.rnapp

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

object NativeOpenSSL {
    init {
        System.loadLibrary("native-lib")
    }

    external fun sha256(input: String?): String?
}

class NativeOpenSSLModule(private val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String = "NativeOpenSSL"

    @ReactMethod
    fun sha256(input: String, promise: Promise) {
        try {
            val res = NativeOpenSSL.sha256(input)
            promise.resolve(res)
        } catch (e: Exception) {
            promise.reject("ERR", e)
        }
    }
}

class NativeOpenSSLPackage : com.facebook.react.ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<com.facebook.react.bridge.NativeModule> {
        return listOf(NativeOpenSSLModule(reactContext))
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<com.facebook.react.uimanager.ViewManager<*, *>> {
        return emptyList()
    }
}
