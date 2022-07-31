/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.log;
import std.stdio : writeln;
import std.format;


void insLogDebug(T...)(string fmt, T args) {
    version(Windows) {
        version(InLite) writeln("[DEBUG] ", fmt.format(args));
        else debug writeln("[DEBUG] ", fmt.format(args));
    } else {
        writeln("[DEBUG] ", fmt.format(args));
    }
}

void insLogInfo(T...)(string fmt, T args) {
    writeln("[INFO] ", fmt.format(args));
}

void insLogWarn(T...)(string fmt, T args) {
    writeln("[WARN] ", fmt.format(args));
}

void insLogErr(T...)(string fmt, T args) {
    writeln("[ERR ] ", fmt.format(args));
}