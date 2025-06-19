import {CopiedItem} from '../types/CopiedItem.model';
import {NativeModules} from 'react-native-macos';

export const copyItem = (item: CopiedItem) => {
  const {ClipboardHandler} = NativeModules;

  if (item.type === 'text') {
    ClipboardHandler.setString(item.content);
  } else if (item.type === 'image') {
    ClipboardHandler.setImage(item.content);
  }
};
