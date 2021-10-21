'use strict';

const path = require('path');
const common = require('./hookCommon');

let reactnativeIndex;
if (__dirname.search('node_modules') === -1) {
  reactnativeIndex = path.resolve(
      __dirname,
      '../node_modules/react-native/index.js',
  );
} else {
  reactnativeIndex = path.resolve(
      __dirname,
      '../../react-native/index.js',
  );
}

function transformerReactNative(content) {
  content = content.replace(
      `require('./Libraries/Components/TextInput/TextInput')`,
      `require('react-native-analytics').createTextInput('./Libraries/Components/TextInput/TextInput',require('./Libraries/Components/TextInput/TextInput'))`,
  );
  content = content.replace(
      `require('./Libraries/Components/Pressable/Pressable').default`,
      `require('react-native-analytics').createHookTouchable('./Libraries/Components/Pressable/Pressable',require('./Libraries/Components/Pressable/Pressable').default)`,
  );
  [
    './Libraries/Text/Text',
    './Libraries/Components/Touchable/TouchableHighlight',
    './Libraries/Components/Touchable/TouchableNativeFeedback',
    './Libraries/Components/Touchable/TouchableOpacity',
    './Libraries/Components/Touchable/TouchableWithoutFeedback',
    './Libraries/Components/Button',
  ].forEach((value)=>{
    content = content.replace(
        `require('${value}')`,
        `require('react-native-analytics').createHookTouchable('${value}',require('${value}'))`,
    );
  })
  return content;
}

common.modifyFile(reactnativeIndex, transformerReactNative);
