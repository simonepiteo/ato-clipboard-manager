import React from 'react';
import {NativeModules, ScrollView, useColorScheme, View} from 'react-native';
import {TextInput} from 'react-native-macos';

const {WindowManager} = NativeModules;

function App(): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';

  const openNewWindow = () => {
    WindowManager.openWindow('Settings', null);
  };

  return (
    <View>
      <ScrollView>
        <TextInput />
      </ScrollView>
    </View>
  );
}

export default App;
