'use strict';

const path = require('path');
const common = require('./hookCommon');

let GestureButtons;
let GenericTouchable;
if (__dirname.search('node_modules') === -1) {
  GestureButtons = path.resolve(
    __dirname,
    '../node_modules/react-native-gesture-handler/GestureButtons.js',
  );
  GenericTouchable = path.resolve(
    __dirname,
    '../node_modules/react-native-gesture-handler/touchables/GenericTouchable.js',
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
}

function insertStr(source, start, newStr) {
  return source.slice(0, start) + newStr + source.slice(start);
}

function transformer(content) {
  content = insertStr(
    content,
    content.indexOf('import'),
    "import {clickEvent} from 'react-native-analytics';\n",
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

common.modifyFile(GestureButtons, transformer);
common.modifyFile(GenericTouchable, transformer);
