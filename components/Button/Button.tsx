import React from 'react';
import {StyleSheet, View} from 'react-native-macos';
import {ButtonProps} from './Button.model';
import {useInteractiveElements} from '../../hooks/useInteractiveElements';

const Button: React.FC<ButtonProps> = ({children, onClick, customStyle}) => {
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

  const style = StyleSheet.create({
    button: {
      padding: 7,
      marginStart: 5,
      marginEnd: 5,
      borderWidth: 1,
      borderColor: 'rgba(204,204,204,.3)',
      borderStyle: 'solid',
      borderRadius: 5,
      backgroundColor: 'rgba(0, 0, 0, 0.1)',
      cursor: 'pointer',
      ...customStyle,
    },
    buttonHover: {borderColor: '#007AFF'},
    buttonFocus: {backgroundColor: '#007AFF'},
  });

  return (
    <View
      style={[
        style.button,
        isHovered && style.buttonHover,
        isFocused && style.buttonFocus,
      ]}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleClick}>
      {children}
    </View>
  );
};

export default Button;
