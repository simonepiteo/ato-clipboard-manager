import {useState} from 'react';
import {
  NativeSyntheticEvent,
  TextInputChangeEventData,
} from 'react-native-macos';

const useSearch = () => {
  const [typedValue, setTypedValue] = useState<string>('');
  const [searchValue, setSearchValue] = useState<string>();

  const handleSearch = () => {
    setSearchValue(typedValue);
  };

  const handleClear = () => {
    setTypedValue('');
    setSearchValue('');
  };

  const onChangeHandler = (
    event: NativeSyntheticEvent<TextInputChangeEventData>,
  ) => setTypedValue(event.nativeEvent.text);

  return {
    typedValue,
    searchValue,
    handleSearch,
    handleClear,
    onChangeHandler,
  };
};

export default useSearch;
