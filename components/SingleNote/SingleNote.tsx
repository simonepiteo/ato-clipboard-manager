import React from 'react';
import {Image, NativeModules, StyleSheet, Text, View} from 'react-native-macos';
import {SingleNoteProps} from './SingleNote.model';
import {copyItem} from '../../utils/CopyItem';
import {useInteractiveElements} from '../../hooks/useInteractiveElements';
import {useSettings} from '../../hooks/useSetting';
import {displayModeData} from '../../utils/SettingsData';
import {defaultSettings} from '../../utils/Settings';

const SingleNote: React.FC<SingleNoteProps> = ({item, id}) => {
  const {
    isHovered,
    isFocused,
    handleMouseEnter,
    handleMouseLeave,
    handleTouchStart,
    handleTouchEnd,
  } = useInteractiveElements();

  const {settings} = useSettings();
  const {WindowManager} = NativeModules;

  const handleSaveToClipboard = () => {
    handleTouchStart();
    copyItem(item);
    if (settings?.automaticPaste) {
      WindowManager.closePopover(true);
    }
  };

  const style = StyleSheet.create({
    singleNote: {
      width:
        displayModeData[settings?.displayMode ?? defaultSettings.displayMode],
      height: 98,
      alignItems: 'flex-start',
      justifyContent: 'flex-start',
      borderRadius: 5,
      borderWidth: 1,
      borderColor: 'rgba(204,204,204,.3)',
      backgroundColor: 'rgba(0, 0, 0, 0.1)',
      borderStyle: 'solid',
      padding: 4,
      cursor: 'pointer',
    },
    singleNoteHovered: {
      borderColor: '#007AFF',
    },
    singleNoteFocused: {
      backgroundColor: '#007AFF',
    },
    shortcutBadge: {
      position: 'absolute',
      bottom: 5,
      right: 5,
      borderRadius: 3,
      backgroundColor: 'rgba(0, 0, 0, 0.4)',
      padding: 2,
      paddingEnd: 4,
      paddingStart: 4,
    },
    shortcutText: {
      fontSize: 11,
      color: 'rgba(255,255,255,.7)',
    },
    textItem: {margin: 3},
    imageContainer: {
      flex: 1,
      alignSelf: 'stretch',
      justifyContent: 'center',
      alignItems: 'center',
    },
    imageItem: {
      width: '100%',
      height: '100%',
      borderRadius: 3,
      resizeMode: 'contain',
    },
  });

  return (
    <View
      style={[
        style.singleNote,
        isHovered && style.singleNoteHovered,
        isFocused && style.singleNoteFocused,
      ]}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onTouchStart={handleSaveToClipboard}
      onTouchEnd={handleTouchEnd}>
      {item.type === 'text' ? (
        <Text style={style.textItem}>{item.content.trim()}</Text>
      ) : item.type === 'image' ? (
        <View style={style.imageContainer}>
          <Image
            source={{uri: `data:image/png;base64,${item.content}`}}
            style={style.imageItem}
          />
        </View>
      ) : null}
      {id && id <= 9 && (
        <View style={style.shortcutBadge}>
          <Text style={style.shortcutText}>⌘{id}</Text>
        </View>
      )}
    </View>
  );
};

export default SingleNote;
