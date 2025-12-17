import React, { useEffect, useState } from 'react';
import { SafeAreaView, Text, Button, NativeModules, StyleSheet } from 'react-native';

const { NativeOpenSSL } = NativeModules;

export default function App() {
    const [hash, setHash] = useState('');
    const [loading, setLoading] = useState(false);

    const compute = async () => {
        setLoading(true);
        try {
            const res = await NativeOpenSSL.sha256('test');
            setHash(res || '');
        } catch (e) {
            setHash('error');
        }
        setLoading(false);
    };

    useEffect(() => {
        compute();
    }, []);

    return (
        <SafeAreaView style={styles.container}>
            <Text style={styles.title}>Native OpenSSL SHA256</Text>
            <Text style={styles.label}>Input:</Text>
            <Text style={styles.input}>'test'</Text>
            <Text style={styles.label}>SHA256 (hex):</Text>
            <Text selectable style={styles.hash}>{loading ? 'computing...' : hash}</Text>
            <Button title="Recompute" onPress={compute} disabled={loading} />
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, padding: 24, justifyContent: 'flex-start' },
    title: { fontSize: 20, fontWeight: '600', marginBottom: 12 },
    label: { marginTop: 8, fontWeight: '500' },
    input: { marginBottom: 8, color: '#333' },
    hash: { marginBottom: 12, color: '#111' },
});
