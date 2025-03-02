# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

require "json"

package = JSON.parse(File.read(File.join(__dir__, "..", "..", "..", "package.json")))
version = package['version']

source = { :git => 'https://github.com/facebook/react-native.git' }
if version == '1000.0.0'
  # This is an unpublished version, use the latest commit hash of the react-native repo, which we’re presumably in.
  source[:commit] = `git rev-parse HEAD`.strip
else
  source[:tag] = "v#{version}"
end

folly_compiler_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32'
folly_version = '2020.01.13.00'
boost_compiler_flags = '-Wno-documentation'

Pod::Spec.new do |s|
  s.name                   = "React-graphics"
  s.version                = version
  s.summary                = "Fabric for React Native."
  s.homepage               = "https://reactnative.dev/"
  s.license                = package["license"]
  s.author                 = "Facebook, Inc. and its affiliates"
  s.platforms              = { :ios => "9.0" }
  s.source                 = source
  s.library                = "stdc++"
  s.compiler_flags         = folly_compiler_flags + ' ' + boost_compiler_flags
  s.source_files           = "**/*.{m,mm,cpp,h}"
  s.exclude_files          = "**/tests/*",
                             "**/android/*",
                             "**/cxx/*"
  s.header_dir             = "react/graphics"
  s.pod_target_xcconfig  = { "USE_HEADERMAP" => "NO", "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost-for-react-native\" \"$(PODS_TARGET_SRCROOT)/ReactCommon\" \"$(PODS_ROOT)/RCT-Folly\"" }

  s.dependency "RCT-Folly/Fabric", folly_version
end
