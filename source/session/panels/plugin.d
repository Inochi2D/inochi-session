module session.panels.plugin;
import session.tracking.expr;
import session.plugins;
import session.plugins.api;
import inui.panel;
import i18n;
import session.scene;
import inui;
import inui.widgets;
import session.log;
import inmath;
import std.format;

class PluginPanel : Panel {
private:

protected:

    override 
    void onUpdate() {
    
        foreach(ref plugin; insPlugins) {
            uiImPush(&plugin);
                if (uiImHeader(plugin.getCName(), true)) {
                    uiImPushTextWrapPos();
                        uiImIndent();
                            if (plugin.hasError) {
                                uiImLabelColored(
                                    _("%s has crashed, options are disabled.").format(plugin.getInfo().pluginName), 
                                    vec4(1, 0.3, 0.3, 1)
                                );
                            } else if (plugin.hasEvent("onRenderUI")) {
                                    insPluginBeginUI();
                                    try {
                                        plugin.callEvent("onRenderUI");
                                    } catch(Exception ex) {
                                        insLogErr(_("%s (plugin): %s"), plugin.getInfo().pluginId, ex.msg);
                                    }
                                    insPluginEndUI();
                            } else {
                                uiImLabel(_("Plugin cannot be configured."));
                            }
                        uiImUnindent();
                    uiImPopTextWrapPos();
                }
            uiImPop();
        }
    }

public:
    this() {
        super("Plugins", _("Plugins"), true);
    }
}

mixin inPanel!PluginPanel;