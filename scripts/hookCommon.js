'use strict';

const fs = require('fs');

/**
 * 返回functionBody执行的函数
 */
module.exports.anonymousJsFunctionCall = function(functionBody, theNameOfThis) {
  if (!theNameOfThis) {
    theNameOfThis = 'this';
  }

  functionBody = functionBody.replace(/this/g, '_$$$$this');
  return (
    '(function(_$$this){\n' +
    '    try{\n        ' +
    functionBody +
    '    \n    } catch (error) { throw new Error(\'analytics RN SDK 代码调用异常: \' + error);}\n' +
    '})(' +
    theNameOfThis +
    ');'
  );
};

/**
 * 修正处理文件
 * transfomer: (originalStr) => newStr
 */
module.exports.modifyFile = function(filePath, transfomer) {
  const content = fs.readFileSync(filePath, 'utf8');
  if (content.includes('/*ANALYTICS MODIFIED ')) {
    console.log(`filePath: ${filePath} has modified`);
    return;
  }
  fs.renameSync(filePath, `${filePath}_bak`);
  let modifiedContent;
  try {
    modifiedContent = transfomer(content);
    modifiedContent =
      modifiedContent + '\n/*ANALYTICS MODIFIED ' + new Date() + ' */';
    fs.writeFileSync(filePath, modifiedContent, 'utf8');
  } catch (e) {
    fs.renameSync(`${filePath}_bak`, filePath);
    throw e;
  }
};

/**
 * 将ANALYTICS处理后的文件恢复
 */
module.exports.resetFile = function(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  if (!content.includes('/*ANALYTICS MODIFIED ')) {
    console.log(`filePath: ${filePath} does not modified by gio, and return`);
    return;
  }
  const backFilePath = `${filePath}_bak`;
  if (!fs.existsSync(backFilePath)) {
    throw `File: ${backFilePath} not found, some thing oop.\n Please rm -rf node_modules and npm install again`;
  }
  fs.renameSync(backFilePath, filePath);
};
