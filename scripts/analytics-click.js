'use strict';

const path = require('path');
const common = require('./hookCommon');

let GestureButtons;
let GenericTouchable;
let reactnativeIndex;
if (__dirname.search('node_modules') === -1) {
  GestureButtons = path.resolve(
      __dirname,
      '../node_modules/react-native-gesture-handler/GestureButtons.js',
  );
  GenericTouchable = path.resolve(
      __dirname,
      '../node_modules/react-native-gesture-handler/touchables/GenericTouchable.js',
  );
  reactnativeIndex = path.resolve(
      __dirname,
      '../node_modules/react-native/index.js',
  );
} else {
  GestureButtons = path.resolve(
      __dirname,
      '../../react-native-gesture-handler/GestureButtons.js',
  );
  GenericTouchable = path.resolve(
      __dirname,
      '../../react-native-gesture-handler/touchables/GenericTouchable.js',
  );
  reactnativeIndex = path.resolve(
      __dirname,
      '../../react-native/index.js',
  );
}

function insertStr(source, start, newStr) {
  return source.slice(0, start) + newStr + source.slice(start);
}

function transformer(content) {
  content = insertStr(
      content,
      content.indexOf('import'),
      'import {clickEvent} from \'react-native-analytics\';\n',
  );
  const pressIndex = content.search(/this.props.onPress\(\w*\);/);
  if (pressIndex === -1) {
    throw 'pressIndex is -1';
  }
  content = content.replace(
      /(this.props.onPress\(\w*\);)/,
      `$1\n${common.anonymousJsFunctionCall('clickEvent(this);\n')}`,
  );
  return content;
}

function transformerReactNative(content) {
  content = content.replace(
      `require('./Libraries/Components/TextInput/TextInput')`,
      `require('react-native-analytics').createTextInput(require('./Libraries/Components/TextInput/TextInput'))`,
  );
  content = content.replace(
      `require('./Libraries/Components/Pressable/Pressable')`,
      `require('react-native-analytics').createHookTouchable(require('./Libraries/Components/Pressable/Pressable').default)`,
  );
  [
    './Libraries/Components/Touchable/TouchableHighlight',
    './Libraries/Components/Touchable/TouchableNativeFeedback',
    './Libraries/Components/Touchable/TouchableOpacity',
    './Libraries/Components/Touchable/TouchableWithoutFeedback',
    './Libraries/Components/Button',
  ].forEach((value)=>{
    content = content.replace(
        `require('${value}')`,
        `require('react-native-analytics').createHookTouchable(require('${value}'))`,
    );
  })
  return content;
}

let hasGesture;
try {
  const gesture = require('react-native-gesture-handler');
  hasGesture = true;
}catch (e) {

}
if (hasGesture){
  common.modifyFile(GestureButtons, transformer);
  common.modifyFile(GenericTouchable, transformer);
}
common.modifyFile(reactnativeIndex, transformerReactNative);
