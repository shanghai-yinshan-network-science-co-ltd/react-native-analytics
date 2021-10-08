
# react-native-analytics

## Getting started

`$ npm install react-native-analytics --save`

### Mostly automatic installation

`$ react-native link react-native-analytics`

### Manual installation


## Usage

package.json

```javascript
"postinstall":"node node_modules/react-native-analytics/scripts/analytics-click.js"
```

babel.config.js
```javascript
  plugins: [
    [
      'module-resolver',
      {
        alias: {
          'react-native-gesture-handler-proxy': 'react-native-gesture-handler',
          'react-native-gesture-handler': 'react-native-analytics/gesture'
        },
      },
    ],
  ]
```
