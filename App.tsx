import React, {useEffect, useRef, useState} from 'react';
import {View} from 'react-native';
import {ScrollView, StyleSheet} from 'react-native-macos';
import MenuItem from './components/MenuItem/MenuItem';
import Search from './components/Search/Search';
import SingleNote from './components/SingleNote/SingleNote';
import {NativeEventEmitter, NativeModules} from 'react-native';
import Clipboard from '@react-native-clipboard/clipboard';

function App(): React.JSX.Element {
  const {ClipboardWatcher, WindowManager, KeyboardShortcutManager} =
    NativeModules;

  const clipboardEvents = new NativeEventEmitter(ClipboardWatcher);
  const shortcutEvents = new NativeEventEmitter(KeyboardShortcutManager);

  const defaultClipboardHistory: string[] = [
    'Welcome to Clipboard Manager!',
    'This is a sample note.',
    'You can add more notes here.',
    'Remember to save your important notes.',
    'Clipboard Manager helps you keep track of your clipboard history.',
    'You can clear your history anytime.',
    'Feel free to customize your notes.',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
    'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip',
  ];

  const [clipboardHistory, setClipboardHistory] = useState<string[]>(
    defaultClipboardHistory,
  );
  const clipboardHistoryRef = useRef(clipboardHistory);

  useEffect(() => {
    clipboardHistoryRef.current = clipboardHistory;
  }, [clipboardHistory]);

  const openNewWindow = () => {
    WindowManager.openWindow('Settings', 'Clipboard Manager - Settings');
  };

  useEffect(() => {
    const sub = shortcutEvents.addListener('CommandNumberPressed', event => {
      const history = clipboardHistoryRef.current;
      if (history.length >= event.number) {
        Clipboard.setString(history[event.number - 1]);
        WindowManager.closePopover();
      }
    });
    return () => sub.remove();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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
    // eslint-disable-next-line react-hooks/exhaustive-deps
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
            <SingleNote key={`note-${idx}`} description={item} id={idx + 1} />
          ))}
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
