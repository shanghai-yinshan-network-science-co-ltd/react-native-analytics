/**
 * Created by cleverdou on 17/9/19.
 */
'use strict';
import React from 'react';
import {sendBuriedData} from './nativeModule';
import {getCurrentPageId} from './pageBuried';
import {getFormatTimeZ, getStrTime} from './utils';
import {getViewPathByComponent} from './stack';
import Clipboard from '@react-native-clipboard/clipboard';
import hoistNonReactStatics from 'hoist-non-react-statics';
import { AppState } from "react-native"


const textfield_event = 'textfield_event';


let currentClipboardText = ""

function initClipboard() {
  Clipboard.getString().then((text) => {
    currentClipboardText = text
  })
  Clipboard.addListener(() => {
    Clipboard.getString().then((text) => {
      currentClipboardText = text
    })
  })
  AppState.addEventListener("change", (state) => {
    if (state === "active") {
      Clipboard.getString().then((text) => {
        currentClipboardText = text
      })
    }
  });
}

function getCommenEvent(viewPath, pageId, vId) {
  if (!pageId) {
    return;
  }
  const now = Date.now();
  viewPath = pageId + '-' + viewPath;
  return {
    page_id: pageId,
    start_time: getStrTime(now),
    start_time_z: getFormatTimeZ(now),
    view_path: viewPath,
    action_type: textfield_event,
    log_time: getStrTime(now),
    log_time_z: getFormatTimeZ(now),
    widget_id: vId,
  };
}

let TextInput;

class HookTextInput extends React.Component {

  _$onChangeText = '';
  _prevChangeText = '';

  _onChangeText = (text) => {
    this._prevChangeText = this._$onChangeText;
    this._$onChangeText = text;
    this.props.onChangeText && this.props.onChangeText(text);
  };

  _onTextInput = async (e) => {
    const {text} = e.nativeEvent;
    this.props.onTextInput && this.props.onTextInput(e);
    if (text === currentClipboardText) {
      this._sendEditBuriedData({
        newTextLength: this._$onChangeText.length,
        oldTextLength: this._prevChangeText.length,
      }, 'paste');
    }
  };

  _onBlur = (...args) => {
    // console.log('blur', event.nativeEvent);
    if (this._isInput) {
      this._isInput = false;
      let text = this.props.value || this._$onChangeText ||
          this.props.defaultValue || '';
      this._sendEditBuriedData(text, 'inputEnd');
    }
    this.props.onBlur && this.props.onBlur(...args);
  };
  _onEndEditing = (...args) => {
    // console.log('blur', event.nativeEvent);
    if (this._isInput) {
      this._isInput = false;
      let text = this.props.value || this._$onChangeText ||
          this.props.defaultValue || '';
      this._sendEditBuriedData(text, 'inputEnd');
    }
    this.props.onEndEditing && this.props.onEndEditing(...args);
  };

  _onFocus = (...args) => {
    // console.log('focus', event.nativeEvent);
    this._isInput = true;
    let text = this.props.value || this._$onChangeText ||
        this.props.defaultValue || '';
    this._sessionId = Date.now();
    this._sendEditBuriedData(text, 'inputStart');
    this.props.onFocus && this.props.onFocus(...args);
  };

  _sendEditBuriedData = (editData, opType) => {
    this._pageId = this._pageId || getCurrentPageId();
    let {path: viewPath, description, vId} = getViewPathByComponent(
        this._reactInternals || this._reactInternalFiber, this._pageId);
    if (opType === 'inputEnd' || opType === 'inputStart') {
      const text = editData;
      const data = getCommenEvent(viewPath, this._pageId, vId);
      if (data) {
        data.page_info = {
          textLength: text ? text.length : 0,
          opType,
          sessionId: this._sessionId,
          description,
        };
        sendBuriedData(data);
      }
    } else if (opType === 'paste') {
      const data = getCommenEvent(viewPath, this._pageId, vId);
      if (data) {
        data.page_info = {
          newTextLength: editData.newTextLength,
          oldTextLength: editData.oldTextLength,
          opType,
          sessionId: this._sessionId,
          description,
        };
        sendBuriedData(data);
      }
    }
  };

  componentWillUnmount() {
    if (this._isInput) {
      let text = this.props.value || this._$onChangeText ||
          this.props.defaultValue || '';
      this._sendEditBuriedData(text, 'inputEnd');
      this._isInput = false;
    }
  }

  render() {
    const {forwardedRef, ...rest} = this.props;

    return (
        <TextInput
            ref={forwardedRef}
            {...rest}
            onChangeText={this._onChangeText}
            onTextInput={this._onTextInput}
            onFocus={this._onFocus}
            onBlur={this._onBlur}
            onEndEditing={this._onEndEditing}
        />
    );
  }
}

const paths = new Map();

export const createTextInput = function(path, OTextInput) {

  if (paths.has(path)) {
    return paths.get(path);
  }

  TextInput = OTextInput;

  const hookComponent = hoistNonReactStatics(React.forwardRef((props, ref) => {

    return <HookTextInput {...props} forwardedRef={ref} />;
  }), OTextInput);

  paths.set(path, hookComponent);

  return hookComponent;
};

initClipboard()

