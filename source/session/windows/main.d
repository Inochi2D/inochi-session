/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.windows.main;
import session.scene;
import inui;
import inui.widgets;
import inui.input;
import inochi2d;
import ft;
import i18n;
import inui.utils.link;
import std.format;

private {
    struct InochiWindowSettings {
        int width;
        int height;
    }

    struct PuppetSavedData {
        float scale;
    }
}

class InochiSessionWindow : InApplicationWindow {
private:
    Adaptor adaptor;
    bool showUI = true;
    Texture logo;

protected:
    override
    void onEarlyUpdate() {
        insUpdateScene();
        inDrawScene(vec4(0, 0, width, height));
    }

    override
    void onUpdate() {
        if (inInputMouseDoubleClicked(MouseButton.Left)) showUI = !showUI;
        if (!inInputIsInUI()) {
            insInteractWithScene();
        }

        if (showUI) {
            uiImBeginMainMenuBar();
                vec2 avail = uiImAvailableSpace();
                uiImImage(logo.getTextureId(), vec2(avail.y*2, avail.y*2));

                if (uiImBeginMenu(__("File"))) {
                    uiImEndMenu();
                }

                uiImLabel(_("Double-click to show/hide"));

                // DONATE BUTTON
                avail = uiImAvailableSpace();
                vec2 donateBtnLength = uiImMeasureString(_("Donate")).x+16;
                uiImDummy(vec2(avail.x-donateBtnLength.x, 0));
                if (uiImMenuItem(__("Donate"))) {
                    uiOpenLink("https://www.patreon.com/LunaFoxgirlVT");
                }
            uiImEndMainMenuBar();
        }
    }

    override
    void onResized(int w, int h) {
        inSetViewport(w, h);
        inSettingsSet("window", InochiWindowSettings(width, height));
    }

    override
    void onClosed() {
    }

public:

    /**
        Construct Inochi Session
    */
    this(string[] args) {
        InochiWindowSettings windowSettings = 
            inSettingsGet!InochiWindowSettings("window", InochiWindowSettings(1024, 1024));

        super("Inochi Session", windowSettings.width, windowSettings.height);
        
        // Initialize Inochi2D
        inInit(&inGetTime);
        inSetViewport(windowSettings.width, windowSettings.height);

        // Preload any specified models
        foreach(arg; args) {
            import std.file : exists;
            if (!exists(arg)) continue;

            insPuppets ~= inLoadPuppet(arg);
        }

        inGetCamera().scale = vec2(0.05);

        logo = new Texture(ShallowTexture(cast(ubyte[])import("tex/logo.png")));
    }
}