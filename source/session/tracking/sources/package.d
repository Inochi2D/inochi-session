module session.tracking.sources;
public import session.tracking.sources.ft;
import ft.data : Bone;

interface IBindingSource {

    string getSourceID();

    string[] getBlendshapeKeys();
    ref float[string] getBlendshapes();
    float getBlendshape(string name);
    
    string[] getBoneKeys();
    ref Bone[string] getBones();
    ref Bone getBone(string name);

    bool isTrackingActive();

    void clear();
    void update();

    void onDispose();
}