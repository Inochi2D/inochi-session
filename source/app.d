/*
    Inochi Session main app entry
    
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module app;
import inochi2d;
import inui;
import session.windows;
import std.stdio : writeln;

void main(string[] args) {
    
    // Set the application info
    InApplication appInfo = InApplication(
        "net.inochi2d.InochiSession",   // FQDN
        "inochi-session",               // Config dir
        "Inochi Session"                // Human-readable name
    );
    inSetApplication(appInfo);
    
    // Initialize UI
    inInitUI();

    // Open window and init Inochi2D
    auto window = new InochiSessionWindow(args[1..$]);
    
    // Draw window
    while(window.isAlive) {
        window.update();
    }
    
    inSettingsSave();
}