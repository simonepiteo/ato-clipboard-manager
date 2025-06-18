import React, {useEffect, useState} from 'react';
import {View} from 'react-native';
import {ScrollView, StyleSheet} from 'react-native-macos';
import MenuItem from './components/MenuItem/MenuItem';
import Search from './components/Search/Search';
import SingleNote from './components/SingleNote/SingleNote';
import {NativeEventEmitter, NativeModules} from 'react-native';

function App(): React.JSX.Element {
  const {ClipboardWatcher, WindowManager} = NativeModules;
  const clipboardEvents = new NativeEventEmitter(ClipboardWatcher);

  const [clipboardHistory, setClipboardHistory] = useState<string[]>([]);

  const openNewWindow = () => {
    WindowManager.openWindow('Settings', 'Clipboard Manager - Settings');
  };

  useEffect(() => {
    ClipboardWatcher.startWatching();
    const sub = clipboardEvents.addListener('ClipboardChanged', event => {
      /* console.log('Clipboard changed:', event.content); */
      setClipboardHistory((prev: string[]) => {
        const idx = prev.indexOf(event.content);
        if (idx === 0) {
          return prev;
        }
        if (idx > 0) {
          return [
            event.content,
            ...prev.slice(0, idx),
            ...prev.slice(idx + 1),
          ].slice(0, 20);
        } else {
          return [event.content, ...prev].slice(0, 20);
        }
      });
    });
    return () => {
      ClipboardWatcher.stopWatching();
      sub.remove();
    };
  }, []);

  return (
    <View style={styles.container}>
      <Search />
      <ScrollView
        style={styles.notesSection}
        contentContainerStyle={styles.notesContent}
        horizontal={false}
        showsVerticalScrollIndicator={true}>
        <View style={styles.notesGrid}>
          {clipboardHistory.map((item, idx) => (
            <SingleNote key={idx} description={item} />
          ))}
          {/* {Array.from({length: 11}).map((_, idx) => (
            <SingleNote key={idx} />
          ))} */}
        </View>
      </ScrollView>
      <View style={styles.menuSection}>
        <MenuItem
          description="Clear history"
          onClick={() => setClipboardHistory([])}
        />
        <MenuItem description="Settings..." onClick={openNewWindow} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'transparent',
  },
  notesSection: {
    height: 315,
    backgroundColor: 'rgba(0, 0, 0, 0.1)',
    borderBottomWidth: 1,
    borderColor: 'rgba(204,204,204,.3)',
    borderStyle: 'solid',
    padding: 0,
  },
  notesContent: {
    padding: 10,
  },
  notesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  menuSection: {
    marginTop: 5,
  },
});

export default App;
