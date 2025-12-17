#include <jni.h>
#include <string>
#include <cstring>
#include <openssl/evp.h>

static std::string to_hex(const unsigned char* data, size_t len) {
    static const char hex[] = "0123456789abcdef";
    std::string out;
    out.reserve(len * 2);
    for (size_t i = 0; i < len; ++i) {
        unsigned char c = data[i];
        out.push_back(hex[(c >> 4) & 0xF]);
        out.push_back(hex[c & 0xF]);
    }
    return out;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_rnapp_NativeOpenSSL_sha256(JNIEnv* env, jclass /*cls*/, jstring input) {
    const char* in_c = env->GetStringUTFChars(input, nullptr);
    if (!in_c) return env->NewStringUTF("");

    unsigned char digest[EVP_MAX_MD_SIZE];
    unsigned int digest_len = 0;
    EVP_MD_CTX* ctx = EVP_MD_CTX_new();
    if (!ctx) {
        env->ReleaseStringUTFChars(input, in_c);
        return env->NewStringUTF("");
    }
    if (EVP_DigestInit_ex(ctx, EVP_sha256(), nullptr) != 1) {
        EVP_MD_CTX_free(ctx);
        env->ReleaseStringUTFChars(input, in_c);
        return env->NewStringUTF("");
    }
    if (EVP_DigestUpdate(ctx, in_c, strlen(in_c)) != 1) {
        EVP_MD_CTX_free(ctx);
        env->ReleaseStringUTFChars(input, in_c);
        return env->NewStringUTF("");
    }
    if (EVP_DigestFinal_ex(ctx, digest, &digest_len) != 1) {
        EVP_MD_CTX_free(ctx);
        env->ReleaseStringUTFChars(input, in_c);
        return env->NewStringUTF("");
    }
    EVP_MD_CTX_free(ctx);

    env->ReleaseStringUTFChars(input, in_c);

    std::string hex = to_hex(digest, digest_len);
    return env->NewStringUTF(hex.c_str());
}
