//
//  Shader.vsh
//  Wave
//
//  Created by 工藤征生 on 2016/03/29.
//  Copyright © 2016年 Aquaware. All rights reserved.
//

attribute vec4 position;
attribute vec3 color;

varying lowp vec4 colorVarying;


void main()
{
    colorVarying = color;
    gl_Position = position;
}
