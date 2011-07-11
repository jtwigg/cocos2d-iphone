/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2008-2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <math.h>
#import <stdlib.h>
#import <string.h>

#import "CCDrawingPrimitives.h"
#import "ccMacros.h"
#import "Platforms/CCGL.h"
#import "ccGLState.h"
#import "CCShaderCache.h"
#import "GLProgram.h"
#import "Support/OpenGL_Internal.h"


static BOOL initialized = NO;
static GLProgram *shader_ = nil;
static int colorLocation_ = -1;
static ccColor4F color_ = {1,1,1,1};

static void lazy_init( void )
{
	if( ! initialized ) {
		
		//
		// Position and 1 color passed as a uniform (to similate glColor4ub )
		//
		shader_ = [[GLProgram alloc] initWithVertexShaderFilename:@"Shaders/Position_uColor.vert"
									 fragmentShaderFilename:@"Shaders/Position_uColor.frag"];
		

		[shader_ addAttribute:@"aVertex" index:kCCAttribPosition];
		
		[shader_ link];
		
		[shader_ updateUniforms];
		
		colorLocation_ = glGetUniformLocation( shader_->program_, "u_color");
				
		initialized = YES;
	}
	
}

void ccDrawPoint( CGPoint point )
{
	lazy_init();

	ccVertex2F p = (ccVertex2F) {point.x, point.y};
	
	// Default Attribs & States: GL_TEXTURE0, kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Needed states: GL_TEXTURE0, k,kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Unneeded states: GL_TEXTURE0, kCCAttribColor, kCCAttribTexCoords
	
	glDisableVertexAttribArray(kCCAttribTexCoords);
	glDisableVertexAttribArray(kCCAttribColor);

	ccGLUseProgram( shader_->program_ );
	ccGLUniformProjectionMatrix( shader_ );
	ccGLUniformModelViewMatrix( shader_ );
	
	glUniform4f( colorLocation_, color_.r, color_.g, color_.b, color_.a );

	glVertexAttribPointer(kCCAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &p);

	glDrawArrays(GL_POINTS, 0, 1);
	
	// restore default state
	glEnableVertexAttribArray(kCCAttribTexCoords);
	glEnableVertexAttribArray(kCCAttribColor);
	
	CHECK_GL_ERROR_DEBUG();
}

void ccDrawPoints( const CGPoint *points, NSUInteger numberOfPoints )
{
	lazy_init();

	// Default Attribs & States: GL_TEXTURE0, kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Needed states: GL_TEXTURE0, k,kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Unneeded states: GL_TEXTURE0, kCCAttribColor, kCCAttribTexCoords

	glDisableVertexAttribArray(kCCAttribTexCoords);
	glDisableVertexAttribArray(kCCAttribColor);

	ccGLUseProgram( shader_->program_ );
	ccGLUniformProjectionMatrix( shader_ );
	ccGLUniformModelViewMatrix( shader_ );
	
	glUniform4f( colorLocation_, color_.r, color_.g, color_.b, color_.a );

	// iPhone and 32-bit machines optimization
	if( sizeof(CGPoint) == sizeof(ccVertex2F) )
		glVertexAttribPointer(kCCAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, points);
	
	else
    {
		ccVertex2F newPoints[numberOfPoints];

		// Mac on 64-bit
		for( NSUInteger i=0; i<numberOfPoints;i++)
			newPoints[i] = (ccVertex2F) { points[i].x, points[i].y };
		
		glVertexAttribPointer(kCCAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, newPoints);
	}

    glDrawArrays(GL_POINTS, 0, (GLsizei) numberOfPoints);

	// restore default state
	glEnableVertexAttribArray(kCCAttribTexCoords);
	glEnableVertexAttribArray(kCCAttribColor);
	
	CHECK_GL_ERROR_DEBUG();
}


void ccDrawLine( CGPoint origin, CGPoint destination )
{
	lazy_init();

	ccVertex2F vertices[2] = {
		{origin.x, origin.y},
		{destination.x, destination.y}
	};
	

	// Default Attribs & States: GL_TEXTURE0, kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Needed states: GL_TEXTURE0, k,kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Unneeded states: GL_TEXTURE0, kCCAttribColor, kCCAttribTexCoords
	
	glDisableVertexAttribArray(kCCAttribTexCoords);
	glDisableVertexAttribArray(kCCAttribColor);
	
	ccGLUseProgram( shader_->program_ );
	ccGLUniformProjectionMatrix( shader_ );
	ccGLUniformModelViewMatrix( shader_ );
	
	glUniform4f( colorLocation_, color_.r, color_.g, color_.b, color_.a );
	
	glVertexAttribPointer(kCCAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);	
	glDrawArrays(GL_LINES, 0, 2);

	// restore default state
	glEnableVertexAttribArray(kCCAttribTexCoords);
	glEnableVertexAttribArray(kCCAttribColor);
	
	CHECK_GL_ERROR_DEBUG();
}


void ccDrawPoly( const CGPoint *poli, NSUInteger numberOfPoints, BOOL closePolygon )
{
	lazy_init();
	
	// Default Attribs & States: GL_TEXTURE0, kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Needed states: GL_TEXTURE0, k,kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Unneeded states: GL_TEXTURE0, kCCAttribColor, kCCAttribTexCoords

	glDisableVertexAttribArray(kCCAttribTexCoords);
	glDisableVertexAttribArray(kCCAttribColor);
	
	ccGLUseProgram( shader_->program_ );
	ccGLUniformProjectionMatrix( shader_ );
	ccGLUniformModelViewMatrix( shader_ );
	
	glUniform4f( colorLocation_, color_.r, color_.g, color_.b, color_.a );

	// iPhone and 32-bit machines optimization
	if( sizeof(CGPoint) == sizeof(ccVertex2F) )
		glVertexAttribPointer(kCCAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, poli);
	
	else
    {
		ccVertex2F newPoli[numberOfPoints];

		// Mac on 64-bit
		for( NSUInteger i=0; i<numberOfPoints;i++)
			newPoli[i] = (ccVertex2F) { poli[i].x, poli[i].y };
		
		glVertexAttribPointer(kCCAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, newPoli);
	}
		
	if( closePolygon )
		glDrawArrays(GL_LINE_LOOP, 0, (GLsizei) numberOfPoints);
	else
		glDrawArrays(GL_LINE_STRIP, 0, (GLsizei) numberOfPoints);
	
	
	// restore default state
	glEnableVertexAttribArray(kCCAttribTexCoords);
	glEnableVertexAttribArray(kCCAttribColor);
	
	CHECK_GL_ERROR_DEBUG();
}

void ccDrawCircle( CGPoint center, float r, float a, NSUInteger segs, BOOL drawLineToCenter)
{
	lazy_init();
	
	int additionalSegment = 1;
	if (drawLineToCenter)
		additionalSegment++;
	
	const float coef = 2.0f * (float)M_PI/segs;
	
	GLfloat *vertices = calloc( sizeof(GLfloat)*2*(segs+2), 1);
	if( ! vertices )
		return;
	
	for(NSUInteger i = 0;i <= segs; i++) {
		float rads = i*coef;
		GLfloat j = r * cosf(rads + a) + center.x;
		GLfloat k = r * sinf(rads + a) + center.y;
		
		vertices[i*2] = j;
		vertices[i*2+1] = k;
	}
	vertices[(segs+1)*2] = center.x;
	vertices[(segs+1)*2+1] = center.y;

	// Default Attribs & States: GL_TEXTURE0, kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Needed states: GL_TEXTURE0, k,kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Unneeded states: GL_TEXTURE0, kCCAttribColor, kCCAttribTexCoords
	
	glDisableVertexAttribArray(kCCAttribTexCoords);
	glDisableVertexAttribArray(kCCAttribColor);
	
	ccGLUseProgram( shader_->program_ );
	ccGLUniformProjectionMatrix( shader_ );
	ccGLUniformModelViewMatrix( shader_ );
	
	glUniform4f( colorLocation_, color_.r, color_.g, color_.b, color_.a );
	
	glVertexAttribPointer(kCCAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);	
	glDrawArrays(GL_LINE_STRIP, 0, (GLsizei) segs+additionalSegment);	
	
	free( vertices );
	
	// restore default state
	glEnableVertexAttribArray(kCCAttribTexCoords);
	glEnableVertexAttribArray(kCCAttribColor);
	
	CHECK_GL_ERROR_DEBUG();
}

void ccDrawQuadBezier(CGPoint origin, CGPoint control, CGPoint destination, NSUInteger segments)
{
	lazy_init();

	ccVertex2F vertices[segments + 1];
	
	float t = 0.0f;
	for(NSUInteger i = 0; i < segments; i++)
	{
		vertices[i].x = powf(1 - t, 2) * origin.x + 2.0f * (1 - t) * t * control.x + t * t * destination.x;
		vertices[i].y = powf(1 - t, 2) * origin.y + 2.0f * (1 - t) * t * control.y + t * t * destination.y;
		t += 1.0f / segments;
	}
	vertices[segments] = (ccVertex2F) {destination.x, destination.y};

	// Default Attribs & States: GL_TEXTURE0, kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Needed states: GL_TEXTURE0, k,kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Unneeded states: GL_TEXTURE0, kCCAttribColor, kCCAttribTexCoords
	
	glDisableVertexAttribArray(kCCAttribTexCoords);
	glDisableVertexAttribArray(kCCAttribColor);
	
	ccGLUseProgram( shader_->program_ );
	ccGLUniformProjectionMatrix( shader_ );
	ccGLUniformModelViewMatrix( shader_ );
	
	glUniform4f( colorLocation_, color_.r, color_.g, color_.b, color_.a );
	
	glVertexAttribPointer(kCCAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);	
	glDrawArrays(GL_LINE_STRIP, 0, (GLsizei) segments + 1);

	// restore default state
	glEnableVertexAttribArray(kCCAttribTexCoords);
	glEnableVertexAttribArray(kCCAttribColor);
	
	CHECK_GL_ERROR_DEBUG();	
}

void ccDrawCubicBezier(CGPoint origin, CGPoint control1, CGPoint control2, CGPoint destination, NSUInteger segments)
{
	lazy_init();

	ccVertex2F vertices[segments + 1];
	
	float t = 0;
	for(NSUInteger i = 0; i < segments; i++)
	{
		vertices[i].x = powf(1 - t, 3) * origin.x + 3.0f * powf(1 - t, 2) * t * control1.x + 3.0f * (1 - t) * t * t * control2.x + t * t * t * destination.x;
		vertices[i].y = powf(1 - t, 3) * origin.y + 3.0f * powf(1 - t, 2) * t * control1.y + 3.0f * (1 - t) * t * t * control2.y + t * t * t * destination.y;
		t += 1.0f / segments;
	}
	vertices[segments] = (ccVertex2F) {destination.x, destination.y};

	
	// Default Attribs & States: GL_TEXTURE0, kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Needed states: GL_TEXTURE0, k,kCCAttribPosition, kCCAttribColor, kCCAttribTexCoords
	// Unneeded states: GL_TEXTURE0, kCCAttribColor, kCCAttribTexCoords
	
	glDisableVertexAttribArray(kCCAttribTexCoords);
	glDisableVertexAttribArray(kCCAttribColor);
	
	ccGLUseProgram( shader_->program_ );
	ccGLUniformProjectionMatrix( shader_ );
	ccGLUniformModelViewMatrix( shader_ );
	
	glUniform4f( colorLocation_, color_.r, color_.g, color_.b, color_.a );
	
	glVertexAttribPointer(kCCAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);	
	glDrawArrays(GL_LINE_STRIP, 0, (GLsizei) segments + 1);
	
	// restore default state
	glEnableVertexAttribArray(kCCAttribTexCoords);
	glEnableVertexAttribArray(kCCAttribColor);
	
	CHECK_GL_ERROR_DEBUG();	
}

void ccDrawColor4f( GLubyte r, GLubyte g, GLubyte b, GLubyte a )
{
	color_ = (ccColor4F) {r, g, b, a};
}

void ccDrawColor4ub( GLubyte r, GLubyte g, GLubyte b, GLubyte a )
{
	color_ =  (ccColor4F) {r/255.0f, g/255.0f, b/255.0f, a/255.0f};
}