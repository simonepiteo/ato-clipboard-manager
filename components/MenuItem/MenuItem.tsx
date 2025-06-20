import React from 'react';
import {StyleSheet, Text, View} from 'react-native-macos';
import {MenuItemProps} from './MenuItem.model';
import {useInteractiveElements} from '../../hooks/useInteractiveElements';

const MenuItem: React.FC<MenuItemProps> = ({
  description,
  onClick,
  separator,
  shortcut,
}) => {
  const {
    isHovered,
    isFocused,
    handleMouseEnter,
    handleMouseLeave,
    handleTouchStart,
    handleTouchEnd,
  } = useInteractiveElements();

  const handleClick = () => {
    handleTouchEnd();
    onClick?.();
  };

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
        onTouchEnd={handleClick}>
        <Text style={style.menuItemText}>{description}</Text>
        {shortcut && (
          <Text style={style.menuItemShortcut} selectable={false}>
            {shortcut}
          </Text>
        )}
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
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
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
  menuItemShortcut: {
    fontSize: 12,
    opacity: 0.4,
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
