import {useState} from 'react';

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

  const onChangeHandler = (text: string) => setTypedValue(text);

  return {
    typedValue,
    searchValue,
    handleSearch,
    handleClear,
    onChangeHandler,
  };
};

export default useSearch;
