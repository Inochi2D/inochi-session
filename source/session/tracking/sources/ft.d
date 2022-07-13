module session.tracking.sources.ft;
import session.tracking;
import ft;
import inochi2d;

public Adaptor[] insAdaptors;

class FTSource : IBindingSource {
public:
    Adaptor adaptor;

    /**
        Gets the source ID
    */
    string getSourceID() {
        return "FT";
    }

    /**
        Returns a list of keys for the source
    */
    string[] getBlendshapeKeys() {
        return adaptor.getBlendshapes().keys;
    }

    /**
        Returns the value for the specified name
    */
    float getBlendshape(string name) {
        return adaptor.getBlendshapes()[name];
    }

    /**
        Gets list of keys for bones
    */
    string[] getBoneKeys() {
        return adaptor.getBones().keys;
    }

    /**
        Gets a bone
    */
    ref Bone getBone(string name) {
        return adaptor.getBones()[name];
    }

    /**
        Clears the source
    */
    void clear() { /* Intentionally left as a stub*/ }
}