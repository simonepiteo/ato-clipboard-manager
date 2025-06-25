import AsyncStorage from '@react-native-async-storage/async-storage';
import {Settings} from '../../types/Settings.model';
import {defaultSettings, SETTINGS_KEY} from './SettingsData';
import {settingsEvents} from '../EventEmitter';

export const SettingsManager = {
  async get(): Promise<Settings> {
    const json = await AsyncStorage.getItem(SETTINGS_KEY);
    if (json) {
      return {...defaultSettings, ...JSON.parse(json)};
    }
    return defaultSettings;
  },

  async set(newSettings: Partial<Settings>) {
    const current = await SettingsManager.get();
    const updated = {...current, ...newSettings};
    await AsyncStorage.setItem(SETTINGS_KEY, JSON.stringify(updated));
    settingsEvents.emit('settingsChanged', updated);
    return updated;
  },

  async reset() {
    await AsyncStorage.removeItem(SETTINGS_KEY);
    settingsEvents.emit('settingsChanged', defaultSettings);
    return defaultSettings;
  },
};
