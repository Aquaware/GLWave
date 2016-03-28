//
//  Shader.fsh
//  Wave
//
//  Created by 工藤征生 on 2016/03/29.
//  Copyright © 2016年 Aquaware. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = vec4(abs(colorVarying.x+vary_color.x), abs(colorVarying.y+vary_color.y), 1.0, 1.0);
}
