import AsyncStorage from '@react-native-async-storage/async-storage';
import {defaultLanguage} from '../i18n';
import {Entity} from '../types/Shared.model';
import {Settings} from '../types/Settings.model';

export const displayMode: Entity[] = [
  {id: 'grid', label: 'components.settings.displayMode.grid'},
  {id: 'list', label: 'components.settings.displayMode.list'},
];

const SETTINGS_KEY = 'clipboardManagerSettings';

const defaultSettings: Settings = {
  language: defaultLanguage,
  displayMode: 'grid',
  maxHistoryItems: 20,
  automaticPaste: false,
  automaticPasteShortcut: true,
  popoverShortcut: '⌘ ⇧ V',
};

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
    return updated;
  },

  async reset() {
    await AsyncStorage.removeItem(SETTINGS_KEY);
    return defaultSettings;
  },
};
