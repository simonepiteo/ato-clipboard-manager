import {useEffect, useState, useCallback} from 'react';
import {SettingsManager} from '../utils/Settings/SettingsManager';
import {Settings} from '../types/Settings.model';
import {useTranslation} from 'react-i18next';
import {defaultLanguage} from '../i18n';
import {settingsEvents} from '../utils/EventEmitter';

export function useSettings() {
  const [settings, setSettings] = useState<Settings | null>(null);
  const {i18n} = useTranslation();

  useEffect(() => {
    SettingsManager.get().then(setSettings);

    const handler = (updated: Settings) => setSettings(updated);
    settingsEvents.on('settingsChanged', handler);

    return () => {
      settingsEvents.off('settingsChanged', handler);
    };
  }, []);

  const updateSettings = useCallback(async (newSettings: Partial<Settings>) => {
    const updated = await SettingsManager.set(newSettings);
    setSettings(updated);
  }, []);

  const resetSettings = useCallback(async () => {
    i18n.changeLanguage(defaultLanguage);
    const reset = await SettingsManager.reset();
    setSettings(reset);
  }, [i18n]);

  return {settings, updateSettings, resetSettings};
}
