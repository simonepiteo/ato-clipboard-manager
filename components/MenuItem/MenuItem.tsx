import React from 'react';
import {NativeModules, StyleSheet, View, Text} from 'react-native-macos';
import {useInteractiveElements} from '../../hook/useInteractiveElements';

const MenuItem = () => {
  const {WindowManager} = NativeModules;

  const openNewWindow = () => {
    WindowManager.openWindow('Settings', null);
  };

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
        style.menuItem,
        isHovered && style.menuItemHovered,
        isFocused && style.menuItemFocused,
      ]}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}>
      <Text onPress={openNewWindow}>Settings</Text>
    </View>
  );
};

const style = StyleSheet.create({
  menuItem: {
    marginStart: 5,
    marginEnd: 5,
    marginTop: 5,
    marginBottom: 5,
    paddingTop: 3,
    paddingBottom: 3,
    paddingStart: 10,
    paddingEnd: 10,
    borderRadius: 5,
    cursor: 'pointer',
  },
  menuItemHovered: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  menuItemFocused: {
    backgroundColor: '#007AFF',
  },
});
export default MenuItem;
