import React from 'react';
import {StyleSheet, Text, View} from 'react-native-macos';
import {useInteractiveElements} from '../../hook/useInteractiveElements';
import {MenuItemProps} from './MenuItem.model';

const MenuItem: React.FC<MenuItemProps> = ({
  description,
  onClick,
  separator,
}) => {
  const {
    isHovered,
    isFocused,
    handleMouseEnter,
    handleMouseLeave,
    handleTouchStart,
    handleTouchEnd,
  } = useInteractiveElements();

  return (
    <>
      {separator && <View style={style.menuItemSeparator} />}
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
        <Text style={style.menuItemText} onPress={onClick}>
          {description}
        </Text>
      </View>
    </>
  );
};

const style = StyleSheet.create({
  menuItem: {
    marginStart: 5,
    marginEnd: 5,
    marginBottom: 1,
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
  menuItemText: {
    fontSize: 13,
  },
  menuItemSeparator: {
    borderTopWidth: 1,
    borderColor: 'rgba(204,204,204,.3)',
    borderStyle: 'solid',
    marginStart: 10,
    marginEnd: 10,
    marginBottom: 4,
    marginTop: 4,
  },
});
export default MenuItem;
