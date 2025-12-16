const { NativeModules } = require('react-native');

module.exports = {
    callOpenSSL: function (input) {
        if (NativeModules.SimpleOpenSSL && NativeModules.SimpleOpenSSL.sha256) {
            return NativeModules.SimpleOpenSSL.sha256(input || '');
        }
        return Promise.reject(new Error('SimpleOpenSSL native module not available'));
    }
};
