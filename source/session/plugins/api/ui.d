module session.plugins.api.ui;
import lumars;
import inui.widgets;
import std.string;
import std.meta : AliasSeq;


private {
    bool uiBegun;

    alias GUI_API = AliasSeq!(
        "button", (string text) { return uiBegun && uiImButton(text.toStringz); },
        "label", (string text) { if (uiBegun) uiImLabel(text); },
        "textbox", (string id, string text) {
            return [LuaValue(uiImInputText(id, text)), LuaValue(text)]; 
        },
        "error", (string title, string text) { uiImDialog(title.toStringz, text); },
        "info", (string title, string text) { uiImDialog(title.toStringz, text, DialogLevel.Info); },
        "warn", (string title, string text) { uiImDialog(title.toStringz, text, DialogLevel.Warning); },
    );
}

void insRegisterUIAPI(LuaState* state) {
    state.register!GUI_API("ui");
}

void insPluginBeginUI() {
    uiBegun = true;
}

void insPluginEndUI() {
    uiBegun = false;
}

