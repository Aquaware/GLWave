//
//  GameViewController.swift
//  Wave
//
//  Created by 工藤征生 on 2016/03/29.
//  Copyright © 2016年 Aquaware. All rights reserved.
//

import GLKit
import OpenGLES

func BUFFER_OFFSET(i: Int) -> UnsafePointer<Void> {
    let p: UnsafePointer<Void> = nil
    return p.advancedBy(i)
}

 struct VertexData {
    var x: GLfloat = 0.0
    var y: GLfloat = 0.0
    var z: GLfloat = 0.0
    var u: GLfloat = 0.0
    var v: GLfloat = 0.0
    
    init() {
    }
}

// 分割数
private let kDivCount: Int = 120;
// 頂点数 = Y頂点数 * X頂点数
private let kVertexCount: Int = (kDivCount+1) * (kDivCount+1);
// 頂点インデックス数 = Y座標のインデックス数 * X座標のインデックス数
private var kIndexCount: Int = (kDivCount) * (3+(((kDivCount+1)-2)*2)+3);

class GameViewController: GLKViewController {
    
    var program: GLuint = 0
    var rotation: Float = 0.0
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    var indexBuffer: GLuint = 0
    
    var context: EAGLContext? = nil
    var effect: GLKBaseEffect? = nil
    
    deinit {
        tearDownGL()
        
        if EAGLContext.currentContext() === self.context {
            EAGLContext.setCurrentContext(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.context = EAGLContext(API: .OpenGLES2)
        
        if !(self.context != nil) {
            print("Failed to create ES context")
        }
        
        let view = self.view as! GLKView
        view.context = self.context!
        view.drawableDepthFormat = .Format24
        
        self.setupGL()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if self.isViewLoaded() && (self.view.window != nil) {
            self.view = nil
            
            tearDownGL()
            
            if EAGLContext.currentContext() === self.context {
                EAGLContext.setCurrentContext(nil)
            }
            self.context = nil
        }
    }
    
    func setupGL() {
        EAGLContext.setCurrentContext(self.context)
        
        loadShaders()
        
        self.effect = GLKBaseEffect()
        self.effect!.light0.enabled = GLboolean(GL_TRUE)
        self.effect!.light0.diffuseColor = GLKVector4Make(1.0, 0.4, 0.4, 1.0)
        
        glEnable(GLenum(GL_DEPTH_TEST))
        
        createVertex()
        createIndex()
    }
    
    private func createVertex() {
        // 頂点バッファ
        var vertices = [VertexData](count: kVertexCount, repeatedValue: VertexData())
        
        // 頂点間の長さ
        let divisions: Float = 1.0 / Float(kDivCount);
        
        //　頂点作成
        var i: Int = 0;
        for var y: Int = 0; y <= kDivCount; y++ {
            for var x: Int = 0; x <= kDivCount; x++ {
                let tx: Float = Float(x) * divisions * 2.0 - 1.0;
                let ty: Float = Float(y) * divisions * 2.0 - 1.0;
                let tz: Float = 0.0
                vertices[i].x = tx
                vertices[i].y = ty
                vertices[i].z = tz
                vertices[i].u = tx
                vertices[i].v = ty
                i++
            }
        }
        
        // 頂点バッファ作成
        glGenBuffers(1, &vertexBuffer)
        assert(glGetError() == GLenum(GL_NO_ERROR))
        assert(vertexBuffer != 0)
        
        // バインド
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        assert(glGetError() == GLenum(GL_NO_ERROR))
        
        // アップロード
        glBufferData(   GLenum(GL_ARRAY_BUFFER),
                        sizeof(VertexData) * kVertexCount,
                        UnsafeMutablePointer<VertexData>(vertices),
                        GLenum(GL_STATIC_DRAW));
        assert(glGetError() == GLenum(GL_NO_ERROR))
        
        // バインド解除
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0);
    }
    
    private func createIndex() {
        //インデックスバッファ
        var indices = [Int](count: kIndexCount, repeatedValue: 0)
                
        // y座標最大値
        let maxYposition = kDivCount + 1;
                
        var i : Int = 0;
        for var y: Int = 0; y < kDivCount; y++ {
            for var x: Int = 0; x < kDivCount + 1; x++ {
                let index0: Int = x + (y * maxYposition);
                let index1: Int = index0 + maxYposition;
                        
                if x == 0 {
                    // 先頭x座標の場合、縮退三角形の対応をする
                    indices[i++] = index0
                    indices[i++] = index0
                    indices[i++] = index1
                } else if x == kDivCount {
                    // 後尾x座標の場合、縮退三角形の対応をする
                    indices[i++] = index0
                    indices[i++] = index1
                    indices[i++] = index1
                } else {
                    indices[i++] = index0
                    indices[i++] = index1
                }
            }
        }
                
        // インデックス
        glGenBuffers(1, &indexBuffer)
        assert(glGetError() == GLenum(GL_NO_ERROR))
        assert(indexBuffer != 0)
                
        // バインド
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        assert(glGetError() == GLenum(GL_NO_ERROR))
                
        // アップロード
        glBufferData(   GLenum(GL_ELEMENT_ARRAY_BUFFER),
                        sizeof(Int) * kIndexCount,
                        &indices, GLenum(GL_STATIC_DRAW))
        
        assert(glGetError() == GLenum(GL_NO_ERROR))
                
        // バインド解除
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0);
        
    }
    
    private func tearDownGL() {
        EAGLContext.setCurrentContext(self.context)
        
        glDeleteBuffers(1, &vertexBuffer)
        glDeleteVertexArraysOES(1, &vertexArray)
        glDeleteBuffers(1, &indexBuffer)
        
        self.effect = nil
        
        if program != 0 {
            glDeleteProgram(program)
            program = 0
        }
    }
    
    // MARK: - GLKView and GLKViewController delegate methods
    
    func update() {

    }
    
    override func glkView(view: GLKView, drawInRect rect: CGRect) {
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        // バッファバインド
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        
        // 頂点情報設定
        
            // シェーダのattribute変数取得
            var position = GLuint(glGetAttribLocation(program, "position"))
            
            // シェーダ内属性のアクセス許可有効化
            glEnableVertexAttribArray(position);
            
            // 利用箇所指定
            let a: Void
            glVertexAttribPointer(  position,
                                    3,
                                    GLenum(GL_FLOAT),
                                    GLboolean(GL_FALSE),
                                    GLsizei(sizeof(VertexData)),
                                    BUFFER_OFFSET(0))
        
            
            // フラグメント情報設定
        
            // シェーダのattribute変数取得
            let color = GLuint(glGetAttribLocation(program, "color"))
                
            // シェーダ内属性のアクセス許可有効化
            glEnableVertexAttribArray(color)
                
                // 利用箇所指定
            glVertexAttribPointer(  color,
                                    2,
                                    GLenum(GL_FLOAT),
                                    GLboolean(GL_FALSE),
                                    GLsizei(sizeof(VertexData)),
                                    BUFFER_OFFSET(0))
        
        
        // インデックスバッファバインド
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        
        // シェーダー利用開始
        glUseProgram(program);
        assert(glGetError() == GLenum(GL_NO_ERROR))
        
        // シェーダー描画
        glDrawElements( GLenum(GL_TRIANGLE_STRIP),
                        GLsizei(kIndexCount),
                        GLenum(GL_UNSIGNED_INT),
                        BUFFER_OFFSET(0))
            
        assert(glGetError() == GLenum(GL_NO_ERROR))
    }
    
    // MARK: -  OpenGL ES 2 shader compilation
    
    func loadShaders() -> Bool {
        var vertShader: GLuint = 0
        var fragShader: GLuint = 0
        var vertShaderPathname: String
        var fragShaderPathname: String
        
        // Create shader program.
        program = glCreateProgram()
        
        // Create and compile vertex shader.
        vertShaderPathname = NSBundle.mainBundle().pathForResource("Shader", ofType: "vsh")!
        if self.compileShader(&vertShader, type: GLenum(GL_VERTEX_SHADER), file: vertShaderPathname) == false {
            print("Failed to compile vertex shader")
            return false
        }
        
        // Create and compile fragment shader.
        fragShaderPathname = NSBundle.mainBundle().pathForResource("Shader", ofType: "fsh")!
        if !self.compileShader(&fragShader, type: GLenum(GL_FRAGMENT_SHADER), file: fragShaderPathname) {
            print("Failed to compile fragment shader")
            return false
        }
        
        // Attach vertex shader to program.
        glAttachShader(program, vertShader)
        
        // Attach fragment shader to program.
        glAttachShader(program, fragShader)
        
        // Bind attribute locations.
        // This needs to be done prior to linking.
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.Position.rawValue), "position")
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.Color.rawValue), "color")
        
        // Link program.
        if !self.linkProgram(program) {
            print("Failed to link program: \(program)")
            
            if vertShader != 0 {
                glDeleteShader(vertShader)
                vertShader = 0
            }
            if fragShader != 0 {
                glDeleteShader(fragShader)
                fragShader = 0
            }
            if program != 0 {
                glDeleteProgram(program)
                program = 0
            }
            
            return false
        }
        
        
        // Release vertex and fragment shaders.
        if vertShader != 0 {
            glDetachShader(program, vertShader)
            glDeleteShader(vertShader)
        }
        if fragShader != 0 {
            glDetachShader(program, fragShader)
            glDeleteShader(fragShader)
        }
        
        return true
    }
    
    
    func compileShader(inout shader: GLuint, type: GLenum, file: String) -> Bool {
        var status: GLint = 0
        var source: UnsafePointer<Int8>
        do {
            source = try NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding).UTF8String
        } catch {
            print("Failed to load vertex shader")
            return false
        }
        var castSource = UnsafePointer<GLchar>(source)
        
        shader = glCreateShader(type)
        glShaderSource(shader, 1, &castSource, nil)
        glCompileShader(shader)
        
        //#if defined(DEBUG)
        //        var logLength: GLint = 0
        //        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        //        if logLength > 0 {
        //            var log = UnsafeMutablePointer<GLchar>(malloc(Int(logLength)))
        //            glGetShaderInfoLog(shader, logLength, &logLength, log)
        //            NSLog("Shader compile log: \n%s", log)
        //            free(log)
        //        }
        //#endif
        
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        if status == 0 {
            glDeleteShader(shader)
            return false
        }
        return true
    }
    
    func linkProgram(prog: GLuint) -> Bool {
        var status: GLint = 0
        glLinkProgram(prog)
        
        //#if defined(DEBUG)
        //        var logLength: GLint = 0
        //        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        //        if logLength > 0 {
        //            var log = UnsafeMutablePointer<GLchar>(malloc(Int(logLength)))
        //            glGetShaderInfoLog(shader, logLength, &logLength, log)
        //            NSLog("Shader compile log: \n%s", log)
        //            free(log)
        //        }
        //#endif
        
        glGetProgramiv(prog, GLenum(GL_LINK_STATUS), &status)
        if status == 0 {
            return false
        }
        
        return true
    }
    
    func validateProgram(prog: GLuint) -> Bool {
        var logLength: GLsizei = 0
        var status: GLint = 0
        
        glValidateProgram(prog)
        glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            var log: [GLchar] = [GLchar](count: Int(logLength), repeatedValue: 0)
            glGetProgramInfoLog(prog, logLength, &logLength, &log)
            print("Program validate log: \n\(log)")
        }
        
        glGetProgramiv(prog, GLenum(GL_VALIDATE_STATUS), &status)
        var returnVal = true
        if status == 0 {
            returnVal = false
        }
        return returnVal
    }
}

