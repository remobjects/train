// Copyright 2009 the Sputnik authors.  All rights reserved.
// This code is governed by the BSD license found in the LICENSE file.

/**
 * @name: S15.9.5.42_A3_T1;
 * @section: 15.9.5.42;
 * @assertion: The Date.prototype.toUTCString property "length" has { ReadOnly, DontDelete, DontEnum } attributes;
 * @description: Checking ReadOnly attribute;
 */

x = Date.prototype.toUTCString.length;
Date.prototype.toUTCString.length = 1;
if (Date.prototype.toUTCString.length !== x) {
  $ERROR('#1: The Date.prototype.toUTCString.length has the attribute ReadOnly');
}

