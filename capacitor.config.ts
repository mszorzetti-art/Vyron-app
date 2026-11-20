import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.marcuszorzetti.vyron',
  appName: 'Vyron',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
  },
  android: {
    backgroundColor: '#101216',
    allowMixedContent: false,
    webContentsDebuggingEnabled: false,
  },
};

export default config;
