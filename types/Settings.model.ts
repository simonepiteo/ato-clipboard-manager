export type Settings = {
  language: string;
  displayMode: displayModeType;
  maxHistoryItems: number;
  automaticPaste: boolean;
  automaticPasteShortcut: boolean;
  popoverShortcut: string;
};

export type displayModeType = 'grid' | 'list';
