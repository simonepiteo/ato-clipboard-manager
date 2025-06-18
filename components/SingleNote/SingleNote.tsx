import React from 'react';
import {StyleSheet, Text, View} from 'react-native-macos';
import {useInteractiveElements} from '../../hook/useInteractiveElements';

const SingleNote = () => {
  const {
    isHovered,
    isFocused,
    handleMouseEnter,
    handleMouseLeave,
    handleTouchStart,
    handleTouchEnd,
  } = useInteractiveElements();

  return (
    <View
      style={[
        style.singleNote,
        isHovered && style.singleNoteHovered,
        isFocused && style.singleNoteFocused,
      ]}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}>
      <Text>Lorem ipsum dolor sit amet...</Text>
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
});

export default SingleNote;
