//
// A bare-bones Swift standard library
// derived from https://github.com/apple/swift/blob/master/validation-test/stdlib/MicroStdlib/Inputs/Swift.swift
//
// Copied and pasted together from bits of the apple swift standard library with
// a lot of hacking and tweaking. Don't use this for your own stuff. It probably
// won't work! Apple Swift has a perfectly good standard library, this is a
// research piece and I might incorporate this or a similar thing into my
// Swift for Arduino product at some point but otherwise it's probably never
// going to "work" and it's just to help me and others understand how the
// standard library works, it's limitations and what can be done with it.
//
// Some day, when Swift for Arduino has matured and developed into a full
// fledged company, I hope to open source the product and create a production
// ready version of this. For now it's just for interest and research. I hope
// people find it interesting!
//
// I've no idea what the copyright is, as I'm not a lawyer. :)
//

import uSwiftShims

@_transparent public var mainLoopRunning: Bool {
	return main_loop_running()
}
