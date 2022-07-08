module session.plugins.luapi.gui;
import lumars;
import std.string;
import inui.widgets.im;

void inPluginRegisterGUI(LuaState* state) {
    state.register!(
        "button", (string text) { return uiImButton(text.toStringz); },
        "label", (string text) { uiImLabel(text); }
    )("ui");
}