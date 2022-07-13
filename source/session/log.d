module session.log;
import std.stdio : writeln;
import std.format;

void insLogInfo(T...)(string fmt, T args) {
    version(Windows) {
        version(InLite) writeln("[INFO] ", fmt.format(args));
        else debug writeln("[INFO] ", fmt.format(args));
    } else {
        writeln("[INFO] ", fmt.format(args));
    }
}

void insLogWarn(T...)(string fmt, T args) {
    version(Windows) {
        version(InLite) writeln("[WARN] ", fmt.format(args));
        else debug writeln("[WARN] ", fmt.format(args));
    } else {
        writeln("[WARN] ", fmt.format(args));
    }
}

void insLogErr(T...)(string fmt, T args) {
    version(Windows) {
        version(InLite) writeln("[ERR ] ", fmt.format(args));
        else debug writeln("[ERR ] ", fmt.format(args));
    } else {
        writeln("[ERR ] ", fmt.format(args));
    }
}