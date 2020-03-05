// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library git_mock_http_request;

import 'dart:async';

class MockEvents {
  List load = [];
}

abstract class MockHttpRequest {
  static var _responseText = "";
  var _readyState = 4;
  var _status = 200;
  var _responseType;

  StreamController loadStream;
  get onLoad => loadStream.stream;

  StreamController _errorStream;
  get onError => _errorStream.stream;

  StreamController _abortStream;
  get onAbort => _abortStream.stream;

  var on = new MockEvents();

  get readyState => _readyState;

  get status => _status;

  set responseType(type) => _responseType = type;

  set responseText(v) => _responseText = v;

  get responseText => _responseText;

  setRequestHeader(_a, _b) => true;

  bool open(_a, _b, {async : true, user, password}) => true;

  bool send([dynamic body]) => on.load.forEach((cb){ cb(null);});

  MockHttpRequest() {
    _abortStream = new StreamController();
    _errorStream = new StreamController();
    loadStream = new StreamController();
  }
}
