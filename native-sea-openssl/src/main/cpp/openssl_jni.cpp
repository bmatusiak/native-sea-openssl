#include <jni.h>
#include <string>
#include <openssl/sha.h>
#include <android/log.h>

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_androidopenssl_SimpleOpenSSL_sha256Hex(JNIEnv* env, jclass /*cls*/, jstring input) {
    if (input == nullptr) {
        return env->NewStringUTF("");
    }

    const char* str = env->GetStringUTFChars(input, nullptr);
    if (!str) return env->NewStringUTF("");

    size_t len = (size_t) env->GetStringUTFLength(input);
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256((const unsigned char*)str, len, hash);

    env->ReleaseStringUTFChars(input, str);

    char hex[SHA256_DIGEST_LENGTH * 2 + 1];
    for (int i = 0; i < SHA256_DIGEST_LENGTH; ++i) {
        sprintf(hex + i*2, "%02x", hash[i]);
    }
    hex[SHA256_DIGEST_LENGTH * 2] = '\0';

    __android_log_print(ANDROID_LOG_INFO, "ssl_jni", "sha256Hex computed: %s", hex);
    return env->NewStringUTF(hex);
}
