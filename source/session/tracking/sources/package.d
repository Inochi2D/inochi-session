module session.tracking.sources;
public import session.tracking.sources.ft;
public import session.tracking.sources.expr;
import ft.data : Bone;

IBindingSource insBindingSources;

void insInitBindingSources() {

}

interface IBindingSource {
    string getSourceID();

    string[] getBlendshapeKeys();
    float getBlendshape(string name);
    
    string[] getBoneKeys();
    ref Bone getBone(string name);

    void clear();
}