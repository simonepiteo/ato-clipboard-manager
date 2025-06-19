import React from 'react';
import {StyleSheet, Text, TextInput, View} from 'react-native-macos';
import Svg, {Path} from 'react-native-svg';
import {SearchProps} from './Search.model';

const Search: React.FC<SearchProps> = ({value, onChange, onReset}) => {
  return (
    <View style={style.searchContainer}>
      <TextInput
        style={style.search}
        placeholder="Search..."
        placeholderTextColor="rgba(204,204,204,.3)"
        value={value}
        onChange={onChange}
      />
      <View style={style.resetContainer} onTouchEnd={onReset}>
        <Text style={style.resetButton}>
          <Svg
            width={12}
            height={12}
            viewBox="0 0 21 12"
            fill="none"
            stroke="#fff"
            strokeWidth={3}
            strokeLinecap="round"
            strokeLinejoin="round">
            <Path stroke="none" d="M0 0h24v24H0z" fill="none" />
            <Path d="M18 6l-12 12" />
            <Path d="M6 6l12 12" />
          </Svg>
        </Text>
      </View>
    </View>
  );
};

const style = StyleSheet.create({
  searchContainer: {
    borderBottomWidth: 1,
    borderColor: 'rgba(204,204,204,.3)',
    borderStyle: 'solid',
    backgroundColor: 'rgba(0, 0, 0, 0.1)',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingStart: 10,
    paddingEnd: 10,
    paddingTop: 3,
    paddingBottom: 2,
  },
  search: {
    padding: 5,
    paddingEnd: 28,
    borderRadius: 10,
    color: '#fff',
    outlineWidth: 0,
    borderWidth: 0,
    width: '100%',
  },
  resetContainer: {
    width: 20,
    height: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 12.5,
    position: 'absolute',
    right: 13,
    top: 6,
    cursor: 'pointer',
  },
  resetButton: {
    fontSize: 10,
  },
});
export default Search;
