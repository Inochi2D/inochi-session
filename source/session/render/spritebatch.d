/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module session.render.spritebatch;
import inochi2d;
import inmath;
import bindbc.opengl;

private {

    /// How many entries in a SpriteBatch
    enum EntryCount = 10_000;

    // Various variables that make it easier to reference sizes
    enum VecSize = 2;
    enum UVSize = 2;
    enum ColorSize = 4;
    enum VertsCount = 6;
    enum DataLength = VecSize+UVSize+ColorSize;
    enum DataSize = DataLength*VertsCount;

    Shader spriteBatchShader;

    vec2 transformVerts(vec2 position, mat4 matrix) {
        return vec2(matrix*vec4(position.x, position.y, 0, 1));
    }
}

/**
    Global sprite batcher
*/
static SpriteBatch AppBatch;

/**
    Sprite flipping
*/
enum SpriteFlip {
    None = 0,
    Horizontal = 1,
    Vertical = 2
}

/**
    Batches Texture objects for 2D drawing
*/
class SpriteBatch {
private:
    float[DataSize*EntryCount] data;
    size_t dataOffset;
    size_t tris;

    GLuint vao;
    GLuint buffer;
    GLint vp;

    Texture currentTexture;
    mat4 viewProjection;

    void addVertexData(vec2 position, vec2 uvs, vec4 color) {
        data[dataOffset..dataOffset+DataLength] = [position.x, position.y, uvs.x, uvs.y, color.x, color.y, color.z, color.w];
        dataOffset += DataLength;
    }

    void updateVP() {
        int w, h;
        inGetViewport(w, h);

        int largest = max(w, h);

        viewProjection = 
            mat4.orthographic(0, w, h, 0, 0, largest) *
            mat4.translation(0, 0, -10);
    }

public:

    /**
        Constructor
    */
    this() {
        data = new float[DataSize*EntryCount];

        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

        glGenBuffers(1, &buffer);
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
        glBufferData(GL_ARRAY_BUFFER, float.sizeof*data.length, data.ptr, GL_DYNAMIC_DRAW);

        spriteBatchShader = new Shader(import("shaders/batch.vert"), import("shaders/batch.frag"));
        vp = spriteBatchShader.getUniformLocation("vp");
        updateVP();
    }

    /**
        Draws the texture

        Remember to call flush after drawing all the textures you want

        Flush will automatically be called if your draws exceed the max count
        Flush will automatically be called if you queue an other texture
    */
    void draw(Texture texture, rect position, rect cutout = rect.init, vec2 origin = vec2(0, 0), float rotation = 0f, SpriteFlip flip = SpriteFlip.None, vec4 color = vec4(1)) {
        import std.math : isFinite;

        // Flush if neccesary
        if (dataOffset == DataSize*EntryCount) flush();
        if (texture != currentTexture) flush();

        // Update current texture
        currentTexture = texture;

        // Calculate rotation, position and scaling.
        mat4 transform =
            mat4.translation(-origin.x, -origin.y, 0) *
            mat4.translation(position.x, position.y, 0) *
            mat4.translation(origin.x, origin.y, 0) *
            mat4.zRotation(rotation) * 
            mat4.translation(-origin.x, -origin.y, 0) *
            mat4.scaling(position.width, position.height, 0);

        // If cutout has not been set (all values are NaN or infinity) we set it to use the entire texture
        if (!cutout.x.isFinite || !cutout.y.isFinite || !cutout.width.isFinite || !cutout.height.isFinite) {
            cutout = rect(0, 0, texture.width, texture.height);
        }

        // Get the area of the texture with a tiny bit cut off to avoid textures bleeding in to each other
        // TODO: add a 1x1 px transparent border around textures instead?
        enum cutoffOffset = 0.05;
        enum cutoffAmount = cutoffOffset*2;

        vec4 uvArea = vec4(
            (flip & SpriteFlip.Horizontal) > 0 ? (cutout.right)-cutoffAmount : (cutout.left)+cutoffOffset,
            (flip & SpriteFlip.Vertical)   > 0 ? (cutout.bottom)-cutoffAmount : (cutout.top)+cutoffOffset,
            (flip & SpriteFlip.Horizontal) > 0 ? (cutout.left)+cutoffOffset : (cutout.right)-cutoffAmount,
            (flip & SpriteFlip.Vertical)   > 0 ? (cutout.top)+cutoffOffset : (cutout.bottom)-cutoffAmount,
        );

        // Triangle 1
        addVertexData(vec2(0, 1).transformVerts(transform), vec2(uvArea.x, uvArea.w), color);
        addVertexData(vec2(1, 0).transformVerts(transform), vec2(uvArea.z, uvArea.y), color);
        addVertexData(vec2(0, 0).transformVerts(transform), vec2(uvArea.x, uvArea.y), color);
        
        // Triangle 2
        addVertexData(vec2(0, 1).transformVerts(transform), vec2(uvArea.x, uvArea.w), color);
        addVertexData(vec2(1, 1).transformVerts(transform), vec2(uvArea.z, uvArea.w), color);
        addVertexData(vec2(1, 0).transformVerts(transform), vec2(uvArea.z, uvArea.y), color);

        tris += 2;
    }

    /**
        Flush the buffer
    */
    void flush(bool isFbo=false)() {
        
        // update view and projection matrix
        updateVP();

        // Don't draw empty textures
        static if (!isFbo) {
            if (currentTexture is null) return;
        }

        // Bind VAO
        glBindVertexArray(vao);

        // Bind just in case some shennanigans happen
        glBindBuffer(GL_ARRAY_BUFFER, buffer);

        // Update with this draw round's data
        glBufferSubData(GL_ARRAY_BUFFER, 0, dataOffset*float.sizeof, data.ptr);

        // Bind the texture
        static if (!isFbo) {
            currentTexture.bind();
        } else {
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, currentFboTex.getTexId());
        }

        // Use our sprite batcher shader and bind our camera matrix
        spriteBatchShader.use();
        spriteBatchShader.setUniform(vp, viewProjection);

        // Vertex buffer
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(
            0,
            VecSize,
            GL_FLOAT,
            GL_FALSE,
            DataLength*GLfloat.sizeof,
            null,
        );

        // UV buffer
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(
            1,
            UVSize,
            GL_FLOAT,
            GL_FALSE,
            DataLength*GLfloat.sizeof,
            cast(GLvoid*)(VecSize*GLfloat.sizeof),
        );

        // Color buffer
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(
            2,
            ColorSize,
            GL_FLOAT,
            GL_FALSE,
            DataLength*GLfloat.sizeof,
            cast(GLvoid*)((VecSize+UVSize)*GLfloat.sizeof),
        );

        // Draw the triangles
        glDrawArrays(GL_TRIANGLES, 0, cast(int)(tris*3));

        // Reset the batcher's state
        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);
        glDisableVertexAttribArray(2);
        currentTexture = null;
        dataOffset = 0;
        tris = 0;
    }
}