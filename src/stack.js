/* eslint-disable */
/**
 * Created by cleverdou on 17/9/12.
 */
'use strict';


import { Image } from "react-native";
import {isWarning} from './config'

var hasSymbol = "function" === typeof Symbol && Symbol.for,
  REACT_ELEMENT_TYPE = hasSymbol ? Symbol.for("react.element") : 60103,
  REACT_PORTAL_TYPE = hasSymbol ? Symbol.for("react.portal") : 60106,
  REACT_FRAGMENT_TYPE = hasSymbol ? Symbol.for("react.fragment") : 60107,
  REACT_STRICT_MODE_TYPE = hasSymbol ? Symbol.for("react.strict_mode") : 60108,
  REACT_PROFILER_TYPE = hasSymbol ? Symbol.for("react.profiler") : 60114,
  REACT_PROVIDER_TYPE = hasSymbol ? Symbol.for("react.provider") : 60109,
  REACT_CONTEXT_TYPE = hasSymbol ? Symbol.for("react.context") : 60110,
  REACT_CONCURRENT_MODE_TYPE = hasSymbol
    ? Symbol.for("react.concurrent_mode")
    : 60111,
  REACT_FORWARD_REF_TYPE = hasSymbol ? Symbol.for("react.forward_ref") : 60112,
  REACT_SUSPENSE_TYPE = hasSymbol ? Symbol.for("react.suspense") : 60113,
  REACT_MEMO_TYPE = hasSymbol ? Symbol.for("react.memo") : 60115,
  REACT_LAZY_TYPE = hasSymbol ? Symbol.for("react.lazy") : 60116,
  MAYBE_ITERATOR_SYMBOL = "function" === typeof Symbol && Symbol.iterator;

export function getComponentName(type) {
  if (null == type) return null;
  if ("function" === typeof type) return type.displayName || type.name || null;
  if ("string" === typeof type) return type;
  switch (type) {
    case REACT_CONCURRENT_MODE_TYPE:
      return "ConcurrentMode";
    case REACT_FRAGMENT_TYPE:
      return "Fragment";
    case REACT_PORTAL_TYPE:
      return "Portal";
    case REACT_PROFILER_TYPE:
      return "Profiler";
    case REACT_STRICT_MODE_TYPE:
      return "StrictMode";
    case REACT_SUSPENSE_TYPE:
      return "Suspense";
  }
  if ("object" === typeof type)
    switch (type.$$typeof) {
      case REACT_CONTEXT_TYPE:
        // return "Context.Consumer";
        return null;
      case REACT_PROVIDER_TYPE:
        // return "Context.Provider";
        return null;
      case REACT_FORWARD_REF_TYPE:
        var innerType = type.render;
        innerType = innerType.displayName || innerType.name || "";
        return (
          type.displayName ||
          ("" !== innerType ? "ForwardRef(" + innerType + ")" : "ForwardRef")
        );
      case REACT_MEMO_TYPE:
        return getComponentName(type.type);
      case REACT_LAZY_TYPE:
        if ((type = 1 === type._status ? type._result : null))
          return getComponentName(type);
    }
  return null;
}


function getText(children) {
  if (Array.isArray(children)) {
    let text = "";
    for (let i = 0; i < children.length; i++) {
      const child = children[i];
      text += getText(child);
    }
    return text;
  }
  if (typeof children === 'object' && children) {
    const props = children.props || children.pendingProps ||children.memoizedProps;
    if (props && props.children) {
      return getText(props.children);
    }
    if (props) {
      const name = getComponentName(children.type)
      if (props.source && name === 'Image') {
        const source = Image.resolveAssetSource(props.source);
        return `image(${source.uri})&&`
      }
      if (name && name.includes('TextInput')) {
        return `textInput(placeholder:${props.placeholder || ""};defaultValue:${props.defaultValue || ""})`
      }
    }
  }
  if (typeof children === 'string') {
    return children + "&&";
  }
  return "";
}

function isSvg(funcString) {
  return /default.createElement\((.+\.Pattern|.+\.Mask|.+\.RadialGradient|.+\.LinearGradient|.+\.ClipPath|.+\.Image|.+\.Defs|.+\.Symbol|.+\.Use|.+\.G|.+\.TextPath|.+\.Path|.+\.Rect|.+\.Circle|.+\.Ellipse|.+\.Line|.+\.Polygon|.+\.Polyline|.+\.TSpan|.+\.Text)/.test(funcString);
}


function createViewPathByFiber(component, currentComponent) {
  let fibernode = component;
  let text;
  const fibers = [];
  text = getText(component);
  let vId;
  let i = 0;
  while (fibernode) {
    const props = fibernode.props || fibernode.pendingProps ||fibernode.memoizedProps || {};
    if (!vId && props.vId) {
      vId = props.vId;
    }
    if (!vId) {
      i++;
    }
    if (typeof fibernode.key === 'string' && fibernode.key.includes('root-sibling')) {
      break;
    }
    fibers.unshift(fibernode.index ? fibernode.tag + "[" + fibernode.index + "]" : fibernode.tag);
    if (typeof fibernode.key === 'string' && fibernode.key.includes('scene_id')) {
      break;
    }
    if (fibernode.type === currentComponent) {
      break;
    }
    fibernode = fibernode.return;
  }
  if(isWarning()) {
    if (i > 0) {
      console.warn(
          `vId "${vId}" is not in the current operation component, please confirm it is correct`)
    }
  }
  return {
    path: fibers.join("-"),
    description: text,
    vId
  };
}


function getSimpleComponentName(componentName) {
  if (!componentName) {
    componentName = '';
  }
  componentName = componentName.startsWith('topsecret-') ? componentName.slice(10) : componentName;
  switch (componentName) {
    case 'TouchableOpacity':
      componentName = 'TO';
      break;
    case 'RCTView':
      componentName = 'RV';
      break;
    case 'TouchableHighlight':
      componentName = 'TH';
      break;
    case 'View':
      componentName = 'V';
      break;
  }
  return componentName;
}

// function createViewPath(component) {
//     let hierarchy = [];
//     traverseParentTreeUp(hierarchy, component);
//     // hierarchy = hierarchy.map(function (component) {
//     //
//     // });
//     return hierarchy.length > 0 && hierarchy.join('-');
// }


// export function getInspectorDataByComponent(component) {
//
//
//     let componentHierarchy = getOwnerHierarchy(component), instance = lastNotNativeInstance(componentHierarchy),
//         hierarchy = createHierarchy(componentHierarchy), props = getHostProps(instance),
//         hostNode = instance.getHostNode();
//     let viewPath = createViewPath(component);
//     return {
//         hierarchy: hierarchy,
//         props: props,
//         selection: componentHierarchy.indexOf(instance),
//         componentHierarchy: componentHierarchy,
//         instance,
//         hostNode
//     };
// };


export function getViewPathByComponent(component, currentComponent) {
  return createViewPathByFiber(component, currentComponent);
}

