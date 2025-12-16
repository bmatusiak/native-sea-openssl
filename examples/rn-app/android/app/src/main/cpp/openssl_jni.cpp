#include <jni.h>
#include <string>
#include <openssl/sha.h>

extern "C" JNIEXPORT jstring JNICALL
Java_com_rnapp_OpenSSLModule_sha256Native(JNIEnv *env, jobject /* this */, jstring input)
{
    const char *in_c = env->GetStringUTFChars(input, nullptr);
    std::string data(in_c);
    env->ReleaseStringUTFChars(input, in_c);

    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, data.c_str(), data.size());
    SHA256_Final(hash, &sha256);

    static const char hexmap[] = "0123456789abcdef";
    std::string hexstr;
    hexstr.reserve(SHA256_DIGEST_LENGTH * 2);
    for (int i = 0; i < SHA256_DIGEST_LENGTH; ++i) {
        unsigned char b = hash[i];
        hexstr.push_back(hexmap[b >> 4]);
        hexstr.push_back(hexmap[b & 0xF]);
    }

    return env->NewStringUTF(hexstr.c_str());
}
#include <jni.h>
#include <string>
#include <openssl/sha.h>

static std::string hexlify(const unsigned char* digest, size_t len) {
  static const char* hex = "0123456789abcdef";
  std::string out;
  out.reserve(len * 2);
  for (size_t i = 0; i < len; ++i) {
    unsigned char c = digest[i];
    out.push_back(hex[(c >> 4) & 0xF]);
    out.push_back(hex[c & 0xF]);
  }
  return out;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_rnapp_OpenSSLModule_sha256Native(JNIEnv* env, jclass /*cls*/, jstring input) {
    const char* in_c = env->GetStringUTFChars(input, nullptr);
    if (!in_c) return env->NewStringUTF("");

    unsigned char digest[SHA256_DIGEST_LENGTH];
    SHA256_CTX ctx;
    SHA256_Init(&ctx);
    SHA256_Update(&ctx, in_c, strlen(in_c));
    SHA256_Final(digest, &ctx);

    env->ReleaseStringUTFChars(input, in_c);

    std::string hex = hexlify(digest, SHA256_DIGEST_LENGTH);
    return env->NewStringUTF(hex.c_str());
}
