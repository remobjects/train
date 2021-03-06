// Copyright 2009 the Sputnik authors.  All rights reserved.
// This code is governed by the BSD license found in the LICENSE file.

/**
 * @name: S7.9_A11_T2;
 * @section: 7.9, 12.5;
 * @assertion: Check If Statement for automatic semicolon insertion;
 * @description: Use if (false) \n x = 1 and check x; 
*/

//CHECK#1
x = 0;
if (false) 
x = 1
if (x !== 0) {
  $ERROR('#1: Check If Statement for automatic semicolon insertion');
}
