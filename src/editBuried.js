/**
 * Created by cleverdou on 17/9/19.
 */
'use strict';
import React from 'react';
import {sendBuriedData} from './nativeModule';
import {getCurrentPageId} from './pageBuried';
import {getStrTime} from './utils';
import {getViewPathByComponent} from './stack';
import Clipboard from '@react-native-clipboard/clipboard';
import hoistNonReactStatics from 'hoist-non-react-statics';

const textfield_event = 'textfield_event';

function getCommenEvent(viewPath, pageId, vId) {
  if (!pageId) {
    return;
  }
  const now = Date.now();
  const pages = pageId.split('-');
  if (pages.length > 0) {
    viewPath = pages[pages.length - 1] + '-' + viewPath;
  }
  return {
    page_id: pageId,
    start_time: getStrTime(now),
    view_path: viewPath,
    action_type: textfield_event,
    log_time: getStrTime(now),
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
    const clipboardText = await Clipboard.getString();
    if (text === clipboardText) {
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
    const _pageId = getCurrentPageId();
    let {path: viewPath, description, vId} = getViewPathByComponent(
        this._reactInternals||this._reactInternalFiber, getCurrentPageId());
    if (opType === 'inputEnd' || opType === 'inputStart') {
      const text = editData;
      const data = getCommenEvent(viewPath, _pageId, vId);
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
      const data = getCommenEvent(viewPath, _pageId, vId);
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



export function createTextInput(OTextInput){


  TextInput = OTextInput;

  return hoistNonReactStatics(React.forwardRef((props, ref) => {

    return <HookTextInput {...props} forwardedRef={ref} />;
  }),OTextInput);
}

