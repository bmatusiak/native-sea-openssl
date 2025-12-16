import React, { useState } from 'react';
import { SafeAreaView, Text, Button, View, StyleSheet } from 'react-native';

// Import the JS wrapper (this package ships the AAR or points to Maven)
let openssl;
try {
  openssl = require('native-sea-openssl-package');
} catch (e) {
  openssl = null;
}

export default function App() {
  const [msg, setMsg] = useState('Press the button to call native OpenSSL (if available)');

  function callNative() {
    const testString = 'test';
    const expected = '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';
    if (openssl && typeof openssl.callOpenSSL === 'function') {
      setMsg('Calling native OpenSSL...');
      try {
        Promise.resolve(openssl.callOpenSSL(testString)).then((res) => {
          const ok = String(res).toLowerCase() === expected;
          setMsg(`Input: "${testString}"\nExpected: ${expected}\nNative: ${res}\nMatch: ${ok}`);
        }).catch((err) => {
          setMsg(`Native call failed: ${err && err.message ? err.message : err}`);
        });
      } catch (e) {
        setMsg(`Native call failed: ${e.message}`);
      }
    } else {
      setMsg('Native wrapper not implemented or not available in this environment.');
    }
  }

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>native-sea-openssl Example</Text>
      <View style={styles.content}>
        <Text>{msg}</Text>
        <Button title="Call OpenSSL" onPress={callNative} />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  title: { fontSize: 18, fontWeight: '600', marginBottom: 12 },
  content: { width: '80%', alignItems: 'center' },
});
