/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict-local
 * @format
 */

'use strict';

import Pressability, {
  type PressabilityConfig,
} from '../../Pressability/Pressability';
import {PressabilityDebugView} from '../../Pressability/PressabilityDebug';
import typeof TouchableWithoutFeedback from './TouchableWithoutFeedback';
import Animated from 'react-native/Libraries/Animated/Animated';
import Easing from 'react-native/Libraries/Animated/Easing';
import type {ViewStyleProp} from 'react-native/Libraries/StyleSheet/StyleSheet';
import flattenStyle from 'react-native/Libraries/StyleSheet/flattenStyle';
import Platform from '../../Utilities/Platform';
import * as React from 'react';

type TVProps = $ReadOnly<{|
  hasTVPreferredFocus?: ?boolean,
  nextFocusDown?: ?number,
  nextFocusForward?: ?number,
  nextFocusLeft?: ?number,
  nextFocusRight?: ?number,
  nextFocusUp?: ?number,
|}>;

type Props = $ReadOnly<{|
  ...React.ElementConfig<TouchableWithoutFeedback>,
  ...TVProps,

  activeOpacity?: ?number,
  style?: ?ViewStyleProp,

  hostRef: React.Ref<typeof Animated.View>,
  /*
   * Array of keys to receive key down events for
   * For arrow keys, add "ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown",
   */
  validKeysDown?: ?Array<string>,

  /*
   * Array of keys to receive key up events for
   * For arrow keys, add "ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown",
   */
  validKeysUp?: ?Array<string>,
|}>;

type State = $ReadOnly<{|
  anim: Animated.Value,
  pressability: Pressability,
|}>;

/**
 * A wrapper for making views respond properly to touches.
 * On press down, the opacity of the wrapped view is decreased, dimming it.
 *
 * Opacity is controlled by wrapping the children in an Animated.View, which is
 * added to the view hierarchy.  Be aware that this can affect layout.
 *
 * Example:
 *
 * ```
 * renderButton: function() {
 *   return (
 *     <TouchableOpacity onPress={this._onPressButton}>
 *       <Image
 *         style={styles.button}
 *         source={require('./myButton.png')}
 *       />
 *     </TouchableOpacity>
 *   );
 * },
 * ```
 * ### Example
 *
 * ```ReactNativeWebPlayer
 * import React, { Component } from 'react'
 * import {
 *   AppRegistry,
 *   StyleSheet,
 *   TouchableOpacity,
 *   Text,
 *   View,
 * } from 'react-native'
 *
 * class App extends Component {
 *   state = { count: 0 }
 *
 *   onPress = () => {
 *     this.setState(state => ({
 *       count: state.count + 1
 *     }));
 *   };
 *
 *  render() {
 *    return (
 *      <View style={styles.container}>
 *        <TouchableOpacity
 *          style={styles.button}
 *          onPress={this.onPress}>
 *          <Text> Touch Here </Text>
 *        </TouchableOpacity>
 *        <View style={[styles.countContainer]}>
 *          <Text style={[styles.countText]}>
 *             { this.state.count !== 0 ? this.state.count: null}
 *           </Text>
 *         </View>
 *       </View>
 *     )
 *   }
 * }
 *
 * const styles = StyleSheet.create({
 *   container: {
 *     flex: 1,
 *     justifyContent: 'center',
 *     paddingHorizontal: 10
 *   },
 *   button: {
 *     alignItems: 'center',
 *     backgroundColor: '#DDDDDD',
 *     padding: 10
 *   },
 *   countContainer: {
 *     alignItems: 'center',
 *     padding: 10
 *   },
 *   countText: {
 *     color: '#FF00FF'
 *   }
 * })
 *
 * AppRegistry.registerComponent('App', () => App)
 * ```
 *
 */
class TouchableOpacity extends React.Component<Props, State> {
  state: State = {
    anim: new Animated.Value(this._getChildStyleOpacityWithDefault()),
    pressability: new Pressability(this._createPressabilityConfig()),
  };

  _createPressabilityConfig(): PressabilityConfig {
    return {
      cancelable: !this.props.rejectResponderTermination,
      disabled: this.props.disabled,
      hitSlop: this.props.hitSlop,
      delayLongPress: this.props.delayLongPress,
      delayPressIn: this.props.delayPressIn,
      delayPressOut: this.props.delayPressOut,
      minPressDuration: 0,
      pressRectOffset: this.props.pressRetentionOffset,
      onBlur: event => {
        if (Platform.isTV) {
          this._opacityInactive(250);
        }
        if (this.props.onBlur != null) {
          this.props.onBlur(event);
        }
      },
      onFocus: event => {
        if (Platform.isTV) {
          this._opacityActive(150);
        }
        if (this.props.onFocus != null) {
          this.props.onFocus(event);
        }
      },
      onKeyDown: event => {
        if (this.props.onKeyDown != null) {
          this.props.onKeyDown(event);
        }
      },
      onKeyUp: event => {
        if (this.props.onKeyUp != null) {
          this.props.onKeyUp(event);
        }
      },
      validKeysDown: this.props.validKeysDown,
      validKeysUp: this.props.validKeysUp,
      onLongPress: this.props.onLongPress,
      onPress: this.props.onPress,
      onPressIn: event => {
        this._opacityActive(
          event.dispatchConfig.registrationName === 'onResponderGrant'
            ? 0
            : 150,
        );
        if (this.props.onPressIn != null) {
          this.props.onPressIn(event);
        }
      },
      onPressOut: event => {
        this._opacityInactive(250);
        if (this.props.onPressOut != null) {
          this.props.onPressOut(event);
        }
      },
    };
  }

  /**
   * Animate the touchable to a new opacity.
   */
  _setOpacityTo(toValue: number, duration: number): void {
    Animated.timing(this.state.anim, {
      toValue,
      duration,
      easing: Easing.inOut(Easing.quad),
      useNativeDriver: true,
    }).start();
  }

  _opacityActive(duration: number): void {
    this._setOpacityTo(this.props.activeOpacity ?? 0.2, duration);
  }

  _opacityInactive(duration: number): void {
    this._setOpacityTo(this._getChildStyleOpacityWithDefault(), duration);
  }

  _getChildStyleOpacityWithDefault(): number {
    const opacity = flattenStyle(this.props.style)?.opacity;
    return typeof opacity === 'number' ? opacity : 1;
  }

  render(): React.Node {
    // BACKWARD-COMPATIBILITY: Focus and blur events were never supported before
    // adopting `Pressability`, so preserve that behavior.
    const {
      onBlur,
      onFocus,
      onMouseEnter, // [TODO(macOS/win GH#774)
      onMouseLeave, // ]TODO(macOS/win GH#774)
      ...eventHandlersWithoutBlurAndFocus
    } = this.state.pressability.getEventHandlers();

    return (
      <Animated.View
        accessible={this.props.accessible !== false}
        accessibilityLabel={this.props.accessibilityLabel}
        accessibilityHint={this.props.accessibilityHint}
        accessibilityRole={this.props.accessibilityRole}
        accessibilityState={this.props.accessibilityState}
        accessibilityActions={this.props.accessibilityActions}
        onAccessibilityAction={this.props.onAccessibilityAction}
        accessibilityValue={this.props.accessibilityValue}
        importantForAccessibility={this.props.importantForAccessibility}
        accessibilityLiveRegion={this.props.accessibilityLiveRegion}
        accessibilityViewIsModal={this.props.accessibilityViewIsModal}
        accessibilityElementsHidden={this.props.accessibilityElementsHidden}
        acceptsFirstMouse={
          this.props.acceptsFirstMouse !== false && !this.props.disabled
        } // TODO(macOS GH#774)
        enableFocusRing={
          (this.props.enableFocusRing === undefined ||
            this.props.enableFocusRing === true) &&
          !this.props.disabled
        } // TODO(macOS GH#774)
        style={[this.props.style, {opacity: this.state.anim}]}
        nativeID={this.props.nativeID}
        testID={this.props.testID}
        onLayout={this.props.onLayout}
        nextFocusDown={this.props.nextFocusDown}
        nextFocusForward={this.props.nextFocusForward}
        nextFocusLeft={this.props.nextFocusLeft}
        nextFocusRight={this.props.nextFocusRight}
        nextFocusUp={this.props.nextFocusUp}
        hasTVPreferredFocus={this.props.hasTVPreferredFocus}
        hitSlop={this.props.hitSlop}
        // [macOS #656 We need to reconcile between focusable and acceptsKeyboardFocus
        // (e.g. if one is explicitly disabled, we shouldn't implicitly enable the
        // other on the underlying view). Prefer passing acceptsKeyboardFocus if
        // passed explicitly to preserve original behavior, and trigger view warnings.
        {...(this.props.acceptsKeyboardFocus !== undefined
          ? {
              acceptsKeyboardFocus:
                this.props.acceptsKeyboardFocus === true &&
                !this.props.disabled,
            }
          : {
              focusable: this.props.focusable !== false && !this.props.disabled,
            })}
        // macOS]
        tooltip={this.props.tooltip} // TODO(macOS/win GH#774)
        onMouseEnter={this.props.onMouseEnter} // [TODO(macOS GH#774)
        onMouseLeave={this.props.onMouseLeave}
        onDragEnter={this.props.onDragEnter}
        onDragLeave={this.props.onDragLeave}
        onDrop={this.props.onDrop}
        onFocus={this.props.onFocus}
        onBlur={this.props.onBlur}
        onKeyDown={this.props.onKeyDown}
        onKeyUp={this.props.onKeyUp}
        validKeysDown={this.props.validKeysDown}
        validKeysUp={this.props.validKeysUp}
        draggedTypes={this.props.draggedTypes} // ]TODO(macOS GH#774)
        ref={this.props.hostRef}
        {...eventHandlersWithoutBlurAndFocus}>
        {this.props.children}
        {__DEV__ ? (
          <PressabilityDebugView color="cyan" hitSlop={this.props.hitSlop} />
        ) : null}
      </Animated.View>
    );
  }

  componentDidUpdate(prevProps: Props, prevState: State) {
    this.state.pressability.configure(this._createPressabilityConfig());
    if (this.props.disabled !== prevProps.disabled) {
      this._opacityInactive(250);
    }
  }

  componentWillUnmount(): void {
    this.state.pressability.reset();
  }
}

module.exports = (React.forwardRef((props, hostRef) => (
  <TouchableOpacity {...props} hostRef={hostRef} />
)): React.AbstractComponent<$ReadOnly<$Diff<Props, {|hostRef: mixed|}>>>);
