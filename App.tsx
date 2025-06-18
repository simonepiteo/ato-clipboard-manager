import React from 'react';
import {View} from 'react-native';
import {ScrollView, StyleSheet} from 'react-native-macos';
import MenuItem from './components/MenuItem/MenuItem';
import Search from './components/Search/Search';
import SingleNote from './components/SingleNote/SingleNote';

function App(): React.JSX.Element {
  return (
    <View style={styles.container}>
      <Search />
      <ScrollView
        style={styles.notesSection}
        contentContainerStyle={styles.notesContent}
        horizontal={false}
        showsVerticalScrollIndicator={true}>
        <View style={styles.notesGrid}>
          {Array.from({length: 11}).map((_, idx) => (
            <SingleNote key={idx} />
          ))}
        </View>
      </ScrollView>
      <MenuItem />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'transparent',
  },
  notesSection: {
    height: 315,
    backgroundColor: 'rgba(0, 0, 0, 0.1)',
    borderBottomWidth: 1,
    borderColor: 'rgba(204,204,204,.3)',
    borderStyle: 'solid',
    padding: 0,
  },
  notesContent: {
    padding: 10,
  },
  notesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
});

export default App;
