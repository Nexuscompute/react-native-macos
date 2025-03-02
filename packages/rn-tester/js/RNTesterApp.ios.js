/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @format
 * @flow
 */

'use strict';

import {AppRegistry, NativeModules, Platform, View} from 'react-native'; // TODO(OSS Candidate ISS#2710739): everything but AppRegistry
import React from 'react';

import SnapshotViewIOS from './examples/Snapshot/SnapshotViewIOS.ios';
import RNTesterExampleContainer from './components/RNTesterExampleContainer';
import RNTesterList from './utils/RNTesterList';
import RNTesterApp from './RNTesterAppShared';
import type {RNTesterExample} from './types/RNTesterTypes';

const {TestModule} = NativeModules; // TODO(OSS Candidate ISS#2710739)
const requestAnimationFrame = require('fbjs/lib/requestAnimationFrame'); // TODO(OSS Candidate ISS#2710739)

AppRegistry.registerComponent('SetPropertiesExampleApp', () =>
  require('./examples/SetPropertiesExample/SetPropertiesExampleApp'),
);
AppRegistry.registerComponent('RootViewSizeFlexibilityExampleApp', () =>
  require('./examples/RootViewSizeFlexibilityExample/RootViewSizeFlexibilityExampleApp'),
);
AppRegistry.registerComponent('RNTesterApp', () => RNTesterApp);

// Register suitable examples for snapshot tests
RNTesterList.ComponentExamples.concat(RNTesterList.APIExamples).forEach(
  (Example: RNTesterExample) => {
    const ExampleModule = Example.module;
    if (ExampleModule.displayName) {
      class Snapshotter extends React.Component<{...}> {
        render() {
          return (
            <SnapshotViewIOS>
              <RNTesterExampleContainer module={ExampleModule} />
            </SnapshotViewIOS>
          );
        }
      }

      AppRegistry.registerComponent(
        ExampleModule.displayName,
        () => Snapshotter,
      );
    }

    // [TODO(OSS Candidate ISS#2710739)
    class LoadPageTest extends React.Component<{}> {
      componentDidMount() {
        requestAnimationFrame(() => {
          TestModule.markTestCompleted();
        });
      }

      render() {
        return <RNTesterExampleContainer module={ExampleModule} />;
      }
    }

    AppRegistry.registerComponent(
      'LoadPageTest_' + Example.key,
      () => LoadPageTest,
    );
    // ]TODO(OSS Candidate ISS#2710739)
  },
);

// [TODO(OSS Candidate ISS#2710739)
class EnumerateExamplePages extends React.Component<{}> {
  render() {
    RNTesterList.ComponentExamples.concat(RNTesterList.APIExamples).forEach(
      (Example: RNTesterExample) => {
        let skipTest = false;
        if ('skipTest' in Example) {
          const platforms = Example.skipTest;
          skipTest =
            platforms !== undefined &&
            (Platform.OS in platforms || 'default' in platforms);
        }
        if (!skipTest) {
          console.trace(Example.key);
        }
      },
    );
    TestModule.markTestCompleted();
    return <View />;
  }
}

AppRegistry.registerComponent(
  'EnumerateExamplePages',
  () => EnumerateExamplePages,
);
// ]TODO(OSS Candidate ISS#2710739)

module.exports = RNTesterApp;
