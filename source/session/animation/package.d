module session.animation;

import session.tracking;
import inochi2d.core.animation;
import inochi2d.core.animation.player;
import fghj;
import i18n;
import std.format;

enum TriggerType {
    None,
    TrackingTrigger,
    EventTrigger
}

enum TriggerEvent {
    None,
    TrackingOff,
    TrackingOn,
}

class AnimationControl {
public:
    string name;
    bool loop = true;
    bool inmediateStop = false;

    TriggerType type = TriggerType.None;

    // Binding
    string sourceName;
    string sourceDisplayName;
    SourceType sourceType;
    bool inverse;
    float leadInValue = 1;
    float leadOutValue = 0;
    float fullStopValue = -1;

    // EventBidning
    TriggerEvent leadInEvent;
    TriggerEvent leadOutEvent;
    TriggerEvent fullStopEvent;

    // Util
    AnimationPlaybackRef anim; 

    void serialize(S)(ref S serializer) {
        auto state = serializer.objectBegin;
            serializer.putKey("name");
            serializer.putValue(name);
            serializer.putKey("loop");
            serializer.putValue(loop);
            serializer.putKey("inmediateStop");
            serializer.putValue(inmediateStop);
            serializer.putKey("triggerType");
            serializer.serializeValue(type);

            switch(type) {
                case TriggerType.TrackingTrigger:
                    serializer.putKey("sourceName");
                    serializer.putValue(sourceName);
                    serializer.putKey("sourceType");
                    serializer.serializeValue(sourceType);

                    serializer.putKey("inverse");
                    serializer.putValue(inverse);

                    serializer.putKey("leadInValue");
                    serializer.putValue(leadInValue);
                    serializer.putKey("leadOutValue");
                    serializer.putValue(leadOutValue);
                    serializer.putKey("fullStopValue");
                    serializer.putValue(fullStopValue);
                    break;
                case TriggerType.EventTrigger:
                    serializer.putKey("leadInEvent");
                    serializer.serializeValue(leadInEvent);
                    serializer.putKey("leadOutEvent");
                    serializer.serializeValue(leadOutEvent);
                    serializer.putKey("fullStopEvent");
                    serializer.serializeValue(fullStopEvent);
                    break;
                default: break;
            }

        serializer.objectEnd(state);
    }

    SerdeException deserializeFromFghj(Fghj data) {
        data["name"].deserializeValue(name);
        data["loop"].deserializeValue(loop);
        data["inmediateStop"].deserializeValue(inmediateStop);
        data["triggerType"].deserializeValue(type);

        switch(type) {
            case TriggerType.TrackingTrigger:
                data["sourceName"].deserializeValue(sourceName);
                data["sourceType"].deserializeValue(sourceType);

                data["inverse"].deserializeValue(inverse);
                
                data["leadInValue"].deserializeValue(leadInValue);
                data["leadOutValue"].deserializeValue(leadOutValue);
                data["fullStopValue"].deserializeValue(fullStopValue);
                this.createSourceDisplayName();
                break;
            case TriggerType.EventTrigger:
                data["leadInEvent"].deserializeValue(leadInValue);
                data["leadOutEvent"].deserializeValue(leadOutValue);
                data["fullStopEvent"].deserializeValue(fullStopValue);
                break;
            default: break;
        }
                
        return null;
    }

    bool finalize(ref AnimationPlayer player) {
        anim = player.createOrGet(name);
        return anim !is null;

    }

    void createSourceDisplayName() {
        switch(sourceType) {
            case SourceType.Blendshape:
                sourceDisplayName = sourceName;
                break;
            case SourceType.BonePosX:
                sourceDisplayName = _("%s (X)").format(sourceName);
                break;
            case SourceType.BonePosY:
                sourceDisplayName = _("%s (Y)").format(sourceName);
                break;
            case SourceType.BonePosZ:
                sourceDisplayName = _("%s (Z)").format(sourceName);
                break;
            case SourceType.BoneRotRoll:
                sourceDisplayName = _("%s (Roll)").format(sourceName);
                break;
            case SourceType.BoneRotPitch:
                sourceDisplayName = _("%s (Pitch)").format(sourceName);
                break;
            case SourceType.BoneRotYaw:
                sourceDisplayName = _("%s (Yaw)").format(sourceName);
                break;
            default: assert(0);    
        }
    }

}
