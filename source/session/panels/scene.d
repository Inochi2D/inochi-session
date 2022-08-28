/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.panels.scene;
import inui.panel;
import i18n;
import session.scene;
import inui;
import inui.widgets;
import session.log;
import inmath;
import std.format;
import inochi2d;
import tinyfiledialogs;
import std.string;
import bindbc.imgui;

class ScenePanel : Panel {
private:
    vec4 clearColor = vec4(0);

    void loadBackground(string file) {
        if (file.empty) {
            insScene.bgPath = null;
            insScene.backgroundImage = null;
            inSettingsSet("bgPath", null);
            return;
        }

        try {
            insScene.bgPath = file;
            ShallowTexture tex = ShallowTexture(file);
            if (tex.channels == 4) {
                inTexPremultiply(tex.data);
            }
            insScene.backgroundImage = new Texture(tex);
            inSettingsSet("bgPath", insScene.bgPath);
        } catch (Exception ex) {
            uiImDialog(__("Error"), _("Could not load %s, %s").format(file, ex.msg));
        }
    }

    void setBGColor(vec4 color) {
        clearColor = vec4(color.r, color.g, color.b, color.a);
        inSetClearColor(color.r, color.g, color.b, color.a);
        inSettingsSet!(float[4])("bgColor", [color.r, color.g, color.b, color.a]);
    }

protected:

    override 
    void onUpdate() {

        
        uiImLabelColored(_("Lighting"), vec4(0.8, 0.3, 0.3, 1));
        uiImSeperator();

        
        uiImIndent();
            uiImColorButton3("###LIGHT_COLOR", &inSceneAmbientLight.vector);
            uiImUnindent();
        uiImUnindent();

        uiImLabelColored(_("Background Color"), vec4(0.8, 0.3, 0.3, 1));
        uiImSeperator();

        uiImIndent();
            if (uiImColorButton4("###BG_COLOR", &clearColor.vector)) {
                inSetClearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
            }

            uiImLabelColored(_("Color Swatches"), vec4(0.8, 0.3, 0.3, 1));
            uiImIndent();
                
                if (uiImColorSwatch4(__("Full Transparent"), vec4(0, 0, 0, 0))) {
                    this.setBGColor(vec4(0, 0, 0, 0));
                }

                uiImSameLine(0, 4);
                
                if (uiImColorSwatch4(__("Chroma Key Red"), vec4(1, 0, 0, 1))) {
                    this.setBGColor(vec4(1, 0, 0, 1));
                }

                uiImSameLine(0, 4);

                if (uiImColorSwatch4(__("Chroma Key Green"), vec4(0, 1, 0, 1))) {
                    this.setBGColor(vec4(0, 1, 0, 1));
                }

                uiImSameLine(0, 4);
                
                if (uiImColorSwatch4(__("Chroma Key Blue"), vec4(0, 0, 1, 1))) {
                    this.setBGColor(vec4(0, 0, 1, 1));
                }
            uiImUnindent();
        uiImUnindent();

        uiImLabelColored(_("Background Image"), vec4(0.8, 0.3, 0.3, 1));
        uiImSeperator();
    
        if (uiImButton(__("Select Background"))) {
            const(TFD_Filter)[] filters = [
                { ["*.png"], "PNG File (*.png)" },
                { ["*.jpg", "*.jpeg"], "JPEG (*.jpeg, *.jpeg)" },
                { ["*.tga"], "TARGA (*.tga)" }
            ];

            c_str filename = tinyfd_openFileDialog(__("Open..."), "", filters, false);
            if (filename !is null) {
                string file = cast(string)filename.fromStringz;
                this.loadBackground(file);
            }
        }
        if (igBeginDragDropTarget()) {
            const(ImGuiPayload)* payload = igAcceptDragDropPayload("_FILEDROP");
            if (payload !is null) {
                string[] files = *cast(string[]*)payload.Data;

                if (files.length > 0) {
                    import std.path : baseName, extension;
                    import std.uni : toLower;
                    string file = files[0];
                    string filebase = file.baseName;

                    switch(filebase.extension.toLower) {
                        
                        case ".png", ".tga", ".jpeg", ".jpg":
                            this.loadBackground(file);
                            break;

                        default:
                            uiImDialog(__("Error"), _("Could not load %s, unsupported file format.").format(file));
                            break;
                    }
                }
            }
        }

        if (insScene.backgroundImage) {
            igSameLine(0, 4);
            
            if (uiImButton(__("Remove"))) {
                this.loadBackground(null);
            }
        }
    }

public:
    this() {
        super("Scene Settings", _("Scene Settings"), true);
    }
}

mixin inPanel!ScenePanel;