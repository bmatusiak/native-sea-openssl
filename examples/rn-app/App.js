import React, { useState } from 'react';
import { SafeAreaView, Text, Button, View, StyleSheet } from 'react-native';

// Import the JS wrapper (this package ships the AAR or points to Maven)
let openssl;
try {
  openssl = require('react-native-native-sea-openssl');
} catch (e) {
  openssl = null;
}

export default function App() {
  const [msg, setMsg] = useState('Press the button to call native OpenSSL (if available)');

  function callNative() {
    if (openssl && typeof openssl.callOpenSSL === 'function') {
      try {
        const res = openssl.callOpenSSL();
        setMsg(`Native result: ${res}`);
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
