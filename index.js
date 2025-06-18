/**
 * @format
 */

import {AppRegistry} from 'react-native';
import App from './App';
import {name as appName} from './app.json';
import Settings from './components/Settings/Settings';

AppRegistry.registerComponent(appName, () => App);
AppRegistry.registerComponent('Settings', () => Settings);
