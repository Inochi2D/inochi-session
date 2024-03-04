module session.panels.animations;
import inui.panel;
import i18n;
import session.scene;
import inui.widgets;
import std.string;
import std.algorithm.searching;
import inochi2d.core.animation.player;
import inmath;

class AnimationsPanel : Panel {
    string _selected;
    immutable(char) * _selectedCName;
    string _selectFilter;

protected:

    override 
    void onUpdate() {
        auto item = insSceneSelectedSceneItem();
        if (item) {

            if (uiImButton(__("Save to File"))) {
                try {
                    item.saveAnimations();
                } catch (Exception ex) {
                    uiImDialog(__("Error"), ex.msg);
                }
            }

            foreach(ref ac; item.animations) {
                uiImPush(&ac);
                auto anim = ac.anim;
                if (uiImHeader(ac.name.toStringz, true)) {

                    if (uiImButton("")) {
                        anim.stop(ac.inmediateStop);
                    }
                    uiImSameLine(0, 0);
                    
                    if (uiImButton(anim && !(!anim.playing || anim.paused) ? "" : "")) {
                        if (!anim.playing || anim.paused) anim.play(ac.loop);
                        else anim.pause();
                    }
                    uiImSameLine(0, 0);
                    uiImProgress((cast(float)anim.frame) / anim.frames, vec2(-float.min_normal, 0), "");

                    uiImCheckbox(__("Loop"), ac.loop);
                    uiImCheckbox(__("Inmediate Stop"), ac.inmediateStop);

                }
                uiImPop();
            }
        } else {
            uiImLabel(_("No puppet selected"));
        }
    }

public:
    this() {
        super("Animations", _("Animations"), true);
        _selected = _("Select an animation");
        _selectedCName = _selected.toStringz;
    }
}

mixin inPanel!AnimationsPanel;