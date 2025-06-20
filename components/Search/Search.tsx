import React, {useRef} from 'react';
import {useTranslation} from 'react-i18next';
import {StyleSheet, Text, TextInput, View} from 'react-native-macos';
import {SearchClearIcon} from '../Icons/SearchClearIcon';
import {SearchProps} from './Search.model';

const Search: React.FC<SearchProps> = ({value, onChange, onReset}) => {
  const {t} = useTranslation();

  const searchInputRef = useRef<TextInput>(null);

  const handleReset = () => {
    onReset?.();
    setTimeout(() => {
      searchInputRef.current?.blur();
    }, 150);
  };

  return (
    <View style={style.searchContainer}>
      <TextInput
        style={style.search}
        placeholder={t('components.search.placeholder')}
        placeholderTextColor="rgba(204,204,204,.3)"
        value={value}
        onChange={onChange}
        autoFocus={false}
        ref={searchInputRef}
      />
      {value && (
        <View style={style.resetContainer} onTouchEnd={handleReset}>
          <Text style={style.resetButton}>
            <SearchClearIcon />
          </Text>
        </View>
      )}
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
