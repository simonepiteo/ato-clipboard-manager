import React from 'react';
import {useTranslation} from 'react-i18next';
import {Text, View} from 'react-native';

const Settings = () => {
  const {t} = useTranslation();

  return (
    <View style={{flex: 1, justifyContent: 'center', alignItems: 'center'}}>
      <View style={{marginBottom: 20}}>
        <Text>language</Text>
        <Text>{t('Welcome')}</Text>
      </View>
      <View style={{marginBottom: 20}}>
        <Text>display grid/list</Text>
      </View>
      <View style={{marginBottom: 20}}>
        <Text>max items number</Text>
      </View>
      <View style={{marginBottom: 20}}>
        <Text>paste automatically</Text>
      </View>
      <View style={{marginBottom: 20}}>
        <Text>paste automatically after shortcut</Text>
      </View>
      <View style={{marginBottom: 20}}>
        <Text>popover shortcut</Text>
      </View>
      <View style={{marginBottom: 20}}>
        <Text>check updates</Text>
      </View>
    </View>
  );
};

export default Settings;
