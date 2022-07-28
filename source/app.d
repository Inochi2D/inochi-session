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
import session.plugins;
import session.log;
import session.ver;
import session.scene;
import session.framesend;
import session.tracking.expr;


void main(string[] args) {
    insLogInfo("Inochi Session %s, args=%s", INS_VERSION, args[1..$]);
    
    // Set the application info
    InApplication appInfo = InApplication(
        "net.inochi2d.InochiSession",   // FQDN
        "inochi-session",               // Config dir
        "Inochi Session"                // Human-readable name
    );
    inSetApplication(appInfo);

    // Initialize Lua
    insLuaInit();
    
    // Initialize UI
    inInitUI();

    // Initialize expressions before models are loaded.
    insInitExpressions();

    // Open window and init Inochi2D
    auto window = new InochiSessionWindow(args[1..$]);
    
    insSceneInit();
    insInitFrameSending();

    // Draw window
    while(window.isAlive) {
        window.update();
    }
    
    insCleanupExpressions();
    insCleanupFrameSending();
    insSceneCleanup();
    inSettingsSave();
}