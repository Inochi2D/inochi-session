/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.plugins.luapi.gui;
import lumars;
import std.string;
import inui.widgets;

void inPluginRegisterGUI(LuaState* state) {
    state.register!(
        "button", (string text) { return uiImButton(text.toStringz); },
        "label", (string text) { uiImLabel(text); }
    )("ui");
}