import React, { useEffect, useState } from 'react';
import { NativeModules, SafeAreaView, Text, Button, StyleSheet } from 'react-native';

const { OpenSSL } = NativeModules;

export default function App() {
  const [hash, setHash] = useState('');

  async function compute() {
    try {
      const out = await OpenSSL.sha256('test');
      setHash(out);
    } catch (e) {
      setHash('error: ' + String(e));
    }
  }

  useEffect(() => {
    compute();
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>OpenSSL SHA-256 of "test"</Text>
      <Text selectable style={styles.hash}>{hash || 'computing...'}</Text>
      <Button title="Recompute" onPress={compute} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24 },
  title: { fontSize: 18, fontWeight: '600', marginBottom: 12 },
  hash: { fontSize: 14, marginBottom: 20 },
});
