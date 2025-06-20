import {useEffect, useState, useCallback} from 'react';
import {SettingsManager} from '../utils/Settings';
import {Settings} from '../types/Settings.model';
import {useTranslation} from 'react-i18next';
import {defaultLanguage} from '../i18n';

export function useSettings() {
  const [settings, setSettings] = useState<Settings | null>(null);
  const {i18n} = useTranslation();

  useEffect(() => {
    SettingsManager.get().then(setSettings);
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
