module session.tracking.sources.ft;
import session.tracking;
import ft;
import inochi2d;
import session.log;

public Adaptor[] insAdaptors;

class FTSource : IBindingSource {
public:
    string[string] settings;
    Adaptor adaptor;

    this() { }
    this(Adaptor adaptor, string[string] settings = string[string].init) {
        this.adaptor = adaptor;
        this.settings = settings;
        this.adaptor.start(settings);
    }

    /**
        Source destructor
    */
    ~this() {
        adaptor.stop();
    }

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
    ref float[string] getBlendshapes() {
        return adaptor.getBlendshapes();
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
        Gets a bone
    */
    ref Bone[string] getBones() {
        return adaptor.getBones();
    }

    /**
        Gets whether the tracking is active
    */
    bool isTrackingActive() {
        
        // TODO: Add a better method in Adaptor
        return adaptor.getBlendshapes().length > 0;
    }

    void update() {
        adaptor.poll();
    }

    /**
        Clears the source
    */
    void clear() { /* Intentionally left as a stub*/ }

    void onDispose() {
        adaptor.stop();
    }
}