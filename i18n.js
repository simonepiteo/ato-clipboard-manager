import i18n from 'i18next';
import {initReactI18next} from 'react-i18next';
import * as EN from './lang/en.json';
import * as IT from './lang/it.json';

// the translations
// (tip move them in a JSON file and import them,
// or even better, manage them separated from your code: https://react.i18next.com/guides/multiple-translation-files)
const resources = {
  en: {
    translation: EN,
  },
  it: {
    translation: IT,
  },
};

export const supportedLngs = Object.keys(resources);

i18n.use(initReactI18next).init({
  resources,
  lng: 'en',
  fallbackLng: 'en',
  supportedLngs,
  interpolation: {
    escapeValue: false,
  },
});

export default i18n;
