import {
  NativeSyntheticEvent,
  TextInputChangeEventData,
} from 'react-native-macos';

export type SearchProps = {
  onChange: (event: NativeSyntheticEvent<TextInputChangeEventData>) => void;
  value: string;
  onReset?: () => void;
};
