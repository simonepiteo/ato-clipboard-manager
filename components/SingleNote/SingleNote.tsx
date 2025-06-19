import Clipboard from '@react-native-clipboard/clipboard';
import React from 'react';
import {StyleSheet, Text, View} from 'react-native-macos';
import {useInteractiveElements} from '../../hook/useInteractiveElements';

type SingleNoteProps = {
  description: string;
  id?: number;
};

const SingleNote: React.FC<SingleNoteProps> = ({description, id}) => {
  const {
    isHovered,
    isFocused,
    handleMouseEnter,
    handleMouseLeave,
    handleTouchStart,
    handleTouchEnd,
  } = useInteractiveElements();

  const handleSaveToClipboard = () => {
    handleTouchStart();
    if (description) {
      Clipboard.setString(description);
    }
  };

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
      <Text>{description.trim()}</Text>
      {id && id <= 9 && <Text style={style.shortcut}>⌘{id}</Text>}
    </View>
  );
};

const style = StyleSheet.create({
  singleNote: {
    width: 98,
    height: 98,
    alignItems: 'flex-start',
    justifyContent: 'flex-start',
    borderRadius: 5,
    borderWidth: 1,
    borderColor: 'rgba(204,204,204,.3)',
    backgroundColor: 'rgba(0, 0, 0, 0.1)',
    borderStyle: 'solid',
    padding: 7,
    cursor: 'pointer',
  },
  singleNoteHovered: {
    borderColor: '#007AFF',
  },
  singleNoteFocused: {
    backgroundColor: '#007AFF',
  },
  shortcut: {
    position: 'absolute',
    bottom: 5,
    right: 5,
    fontSize: 10,
    color: '#888',
  },
});

export default SingleNote;
