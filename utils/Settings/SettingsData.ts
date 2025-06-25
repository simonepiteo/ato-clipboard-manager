import {Settings} from '../../types/Settings.model';
import {Entity} from '../../types/Shared.model';
import {defaultLanguage} from '../../i18n';

export const displayModeData = {
  grid: 98,
  list: 310,
};

export const displayMode: Entity[] = [
  {id: 'grid', label: 'components.settings.displayMode.grid'},
  {id: 'list', label: 'components.settings.displayMode.list'},
];

export const SETTINGS_KEY = 'clipboardManagerSettings';

export const defaultSettings: Settings = {
  language: defaultLanguage,
  displayMode: 'grid',
  maxHistoryItems: 20,
  automaticPaste: false,
  automaticPasteShortcut: true,
  popoverShortcut: '⌘ ⇧ V',
};
