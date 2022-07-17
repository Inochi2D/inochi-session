module session.panels.tracking;
import inui.panel;
import i18n;
import session.scene;
import session.tracking;
import inui;
import inui.widgets;
import session.log;

class TrackingPanel : Panel {
private:
    

    void ratioBinding(ref TrackingBinding binding) {
        bool hasTrackingSrc = binding.sourceBlendshapeCStr !is null;

        uiImPush(&binding);
            if (hasTrackingSrc && uiImButton(__("Reset"))) {
                binding.sourceBlendshapeCStr = null;
                binding.sourceBlendshape = null;
            }
            if (uiImBeginComboBox(hasTrackingSrc ? binding.sourceBlendshapeCStr : __("Not tracked"))) {
                foreach(blendshape; insScene.space.getAllBlendshapeNames) {
                        bool selected = binding.sourceBlendshape == blendshape[0..$-1];
                        if (uiImSelectable(blendshape.ptr, selected)) {
                            insLogInfo(blendshape[0..$-1]);
                            binding.sourceBlendshapeCStr = blendshape.dup.ptr;
                            binding.sourceBlendshape = blendshape[0..$-1];
                        }
                }
                uiImEndComboBox();
            }

            if (hasTrackingSrc) {
                uiImLabel(_("Dampen"));
                uiImDrag(binding.dampenLevel, 0, 10);

                uiImLabel(_("Tracking In"));
                uiImPush(0);
                    uiImIndent();
                        uiImProgress(binding.inVal);
                        uiImRange(binding.inRange.x, binding.inRange.y, -1, 1);
                    uiImUnindent();
                uiImPop();
                
                uiImLabel(_("Tracking Out"));
                uiImPush(1);
                    uiImIndent();
                        uiImRange(binding.outRange.x, binding.outRange.y, -float.max, float.max);
                        uiImProgress(binding.outVal);
                    uiImUnindent();
                uiImPop();
            }
        uiImPop();
    }
protected:
    override 
    void onUpdate() {
        auto item = insSceneSelectedSceneItem();
        if (item) {
            if (uiImButton(__("Refresh"))) {
                insScene.space.refresh();
            }

            foreach(ref TrackingBinding binding; item.bindings) {
                if (!uiImHeader(binding.nameCStr, true)) continue;

                uiImIndent();
                    switch(binding.type) {

                        case BindingType.RatioBinding:
                            ratioBinding(binding);
                            break;

                        case BindingType.ExpressionBinding:
                        
                            break;

                        // External bindings
                        default: 
                            uiImLabel(_("No settings available."));
                            break;
                    }
                uiImUnindent();
            }
        } else uiImLabel(_("No puppet selected"));
    }

public:
    this() {
        super("Tracking", _("Tracking"), true);
    }
}

mixin inPanel!TrackingPanel;