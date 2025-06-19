import React, {useEffect, useRef, useState} from 'react';
import {NativeEventEmitter, NativeModules, View} from 'react-native';
import {ScrollView, StyleSheet} from 'react-native-macos';
import MenuItem from './components/MenuItem/MenuItem';
import Search from './components/Search/Search';
import SingleNote from './components/SingleNote/SingleNote';
import useSearch from './hooks/useSearch';
import {CopiedItem} from './types/CopiedItem.model';
import {CopyItem} from './utils/CopyItem';

function App(): React.JSX.Element {
  const {ClipboardWatcher, WindowManager, KeyboardShortcutManager} =
    NativeModules;

  const clipboardEvents = new NativeEventEmitter(ClipboardWatcher);
  const shortcutEvents = new NativeEventEmitter(KeyboardShortcutManager);

  const searchHandler = useSearch();
  const [clipboardHistory, setClipboardHistory] = useState<CopiedItem[]>([]);
  const filteredHistory =
    !searchHandler.typedValue || searchHandler.typedValue === ''
      ? clipboardHistory
      : clipboardHistory.filter(
          (item: CopiedItem) =>
            item.type === 'text' &&
            item.content
              .toLowerCase()
              .includes(searchHandler.typedValue.toLowerCase()),
        );
  const clipboardHistoryRef = useRef(filteredHistory);

  useEffect(() => {
    clipboardHistoryRef.current = filteredHistory;
  }, [filteredHistory]);

  const openSettingsWindow = () => {
    WindowManager.openWindow('Settings', 'Clipboard Manager - Settings');
  };

  useEffect(() => {
    const sub = shortcutEvents.addListener('CommandNumberPressed', event => {
      const history = clipboardHistoryRef.current;
      if (history.length >= event.number) {
        const currentItem = history[event.number - 1];
        CopyItem(currentItem);
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
      /* console.log(event); */

      const maxLength = 20;

      setClipboardHistory((prev: CopiedItem[]) => {
        if (
          prev.length > 0 &&
          prev[0].type === event.type &&
          prev[0].content === event.content
        ) {
          return prev;
        }
        const filtered = prev.filter(
          item => !(item.type === event.type && item.content === event.content),
        );
        return [event, ...filtered].slice(0, maxLength);
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
      <Search
        onChange={searchHandler.onChangeHandler}
        value={searchHandler.typedValue}
        onReset={searchHandler.handleClear}
      />
      <ScrollView
        style={styles.notesSection}
        contentContainerStyle={styles.notesContent}
        horizontal={false}
        showsVerticalScrollIndicator={true}>
        <View style={styles.notesGrid}>
          {filteredHistory.map((item, idx) => (
            <SingleNote key={`note-${idx}`} item={item} id={idx + 1} />
          ))}
        </View>
      </ScrollView>
      <View style={styles.menuSection}>
        <MenuItem
          description="Clear history"
          onClick={() => setClipboardHistory([])}
        />
        <MenuItem description="Settings..." onClick={openSettingsWindow} />
        <MenuItem
          description="Quit"
          separator
          onClick={() => WindowManager.quitApp()}
        />
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
