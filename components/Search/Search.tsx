import React from 'react';
import {StyleSheet, TextInput} from 'react-native-macos';

const Search = () => {
  return (
    <TextInput
      style={style.search}
      placeholder="Search..."
      placeholderTextColor="rgba(204,204,204,.3)"
    />
  );
};

const style = StyleSheet.create({
  search: {
    padding: 5,
    paddingStart: 10,
    paddingEnd: 10,
    borderBottomWidth: 1,
    borderColor: 'rgba(204,204,204,.3)',
    borderStyle: 'solid',
    borderRadius: 10,
    marginTop: 5,
    color: '#fff',
    outlineWidth: 0,
    borderWidth: 0,
  },
});
export default Search;
