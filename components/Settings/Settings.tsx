import {Picker} from '@react-native-picker/picker';
import React from 'react';
import {useTranslation} from 'react-i18next';
import {StyleSheet, Switch, Text, TextInput, View} from 'react-native-macos';
import {supportedLngs} from '../../i18n';
import {Entity} from '../../types/Shared.model';
import {displayMode} from '../../utils/Settings';
import packageJson from '../../package.json';
import Button from '../Button/Button';
import {useSettings} from '../../hooks/useSetting';
import {displayModeType} from '../../types/Settings.model';

const Settings = () => {
  const {t, i18n} = useTranslation();
  const {settings, updateSettings, resetSettings} = useSettings();

  const handleLanguageChange = (lng: string) => {
    i18n.changeLanguage(lng);
    updateSettings({language: lng});
  };

  return (
    <View style={style.settingsWindow}>
      {settings && (
        <View style={style.settingsContainer}>
          <View style={style.settingsSection}>
            <Text>{t('components.settings.language.label')}</Text>
            <View style={style.settingPickerContainer}>
              <Picker
                selectedValue={i18n.language}
                onValueChange={handleLanguageChange}
                style={style.settingsPicker}>
                {supportedLngs.map(lng => (
                  <Picker.Item
                    key={`language-selector-${lng}`}
                    label={t(`extendedLanguageName.${lng}`)}
                    value={lng}
                  />
                ))}
              </Picker>
            </View>
          </View>
          <View style={style.settingsSection}>
            <Text>{t('components.settings.displayMode.label')}</Text>
            <View style={style.settingPickerContainer}>
              <Picker
                selectedValue={settings.displayMode}
                onValueChange={(mode: displayModeType) =>
                  updateSettings({displayMode: mode})
                }
                style={style.settingsPicker}>
                {displayMode.map((mode: Entity) => (
                  <Picker.Item
                    key={`display-mode-${mode.id}`}
                    label={t(mode.label)}
                    value={mode.id}
                  />
                ))}
              </Picker>
            </View>
          </View>
          <View style={style.settingsSection}>
            <Text>{t('components.settings.maxHistoryItems.label')}</Text>
            <TextInput
              style={style.settingsTextInput}
              defaultValue={settings?.maxHistoryItems.toString()}
            />
          </View>
          <View style={style.settingsSection}>
            <Text>{t('components.settings.automaticPaste.label')}</Text>
            <Switch
              onValueChange={() =>
                updateSettings({automaticPaste: !settings.automaticPaste})
              }
              value={settings?.automaticPaste}
            />
          </View>
          <View style={style.settingsSection}>
            <Text>{t('components.settings.automaticPasteShortcut.label')}</Text>
            <Switch
              onValueChange={() =>
                updateSettings({
                  automaticPasteShortcut: !settings.automaticPasteShortcut,
                })
              }
              value={settings?.automaticPasteShortcut}
            />
          </View>
          <View style={style.settingsSection}>
            <Text>{t('components.settings.popoverShortcut.label')}</Text>
            <TextInput style={style.settingsTextInput} value="⌘ ⇧ V" />
          </View>
          <View style={style.settingsSection}>
            <Button customStyle={style.settingsUpdateButton}>
              <Text>{t('components.settings.checkUpdates.label')}</Text>
            </Button>
          </View>
        </View>
      )}
      <View style={style.settingMenu}>
        <Button onClick={resetSettings}>
          <Text>{t('components.settings.menu.reset')}</Text>
        </Button>
        <Button>
          <Text>Github</Text>
        </Button>
        <Button>
          <Text>License</Text>
        </Button>
        <Button>
          <Text>{t('version', {version: packageJson.version})}</Text>
        </Button>
      </View>
    </View>
  );
};

const style = StyleSheet.create({
  settingsWindow: {},
  settingsContainer: {
    marginBottom: 10,
    padding: 20,
    paddingTop: 10,
    paddingBottom: 10,
    borderBottomWidth: 1,
    borderColor: 'rgba(204,204,204,.3)',
    borderStyle: 'solid',
    borderRadius: 5,
    backgroundColor: 'rgba(0, 0, 0, 0.1)',
  },
  settingsSection: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    width: '100%',
    marginTop: 5,
    marginBottom: 5,
  },
  settingPickerContainer: {
    height: 25,
    justifyContent: 'center',
  },
  settingsPicker: {
    width: 120,
  },
  settingsTextInput: {
    padding: 5,
    height: 30,
    width: 60,
    borderWidth: 1,
    borderColor: 'rgba(204,204,204,.3)',
    borderStyle: 'solid',
    borderRadius: 5,
  },
  settingsUpdateButton: {
    padding: 'auto',
    fontSize: 12,
    width: '100%',
    height: 30,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(204,204,204,.3)',
    borderStyle: 'solid',
    borderRadius: 5,
    backgroundColor: 'rgba(0, 0, 0, 0.1)',
  },
  settingMenu: {
    flexDirection: 'row',
    justifyContent: 'center',
  },
  settingMenuItem: {},
});

export default Settings;
