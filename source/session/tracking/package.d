/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.tracking;
import inochi2d;

public import session.tracking.sources;

enum BindingType {
    RatioBinding,
    ExpressionBinding
}

class TrackingBinding {
private:

public:
    Parameter param;
    IBindingSource source;
}