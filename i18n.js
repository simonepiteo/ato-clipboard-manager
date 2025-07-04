import i18n from 'i18next';
import {initReactI18next} from 'react-i18next';
import * as EN from './lang/en.json';
import * as IT from './lang/it.json';
import * as shared from './lang/shared.json';

const languages = {en: EN, it: IT};

const resources = Object.fromEntries(
  Object.entries(languages).map(([lng, data]) => [
    lng,
    {
      translation: {
        ...data,
        ...shared,
      },
    },
  ]),
);

export const supportedLngs = Object.keys(resources);
export const defaultLanguage = supportedLngs[0];

i18n.use(initReactI18next).init({
  resources,
  lng: defaultLanguage,
  fallbackLng: defaultLanguage,
  supportedLngs,
  interpolation: {
    escapeValue: false,
  },
});

export default i18n;
