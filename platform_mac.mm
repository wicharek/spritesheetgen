//
//  platform_mac.cpp
//  spritesheetgen
//
//  Created by Vitaliy Ivanov on 6/26/12.
//  Copyright (c) 2012 Factorial Complexity. All rights reserved.
//

#include "platform.h"
#include <Foundation/Foundation.h>
#include <Quartz/Quartz.h>
#include <iostream>

using namespace std;
using namespace ssg;

static NSAutoreleasePool* g_pool = nil;

void ssg::on_start()
{
	g_pool = [[NSAutoreleasePool alloc] init];
}

void ssg::on_end()
{
	[g_pool release];
}

FramesList ssg::frames_from_dir(const string& dir_path)
{
	FramesList frames;
	
	NSError* error;
	NSString* dir_path_string = [NSString stringWithUTF8String:dir_path.c_str()];
	NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir_path_string
		error:&error];
		
	for (NSString* file_name in files)
	{
		if ([[file_name pathExtension] isEqualToString:@"png"] ||
			[[file_name pathExtension] isEqualToString:@"jpg"] ||
			[[file_name pathExtension] isEqualToString:@"jpeg"])
		{
			CGDataProviderRef image_data = CGDataProviderCreateWithCFData((CFDataRef)[NSData
				dataWithContentsOfFile:[dir_path_string stringByAppendingPathComponent:file_name]]);
			CGImageRef image = [[file_name pathExtension] isEqualToString:@"png"] ?
				CGImageCreateWithPNGDataProvider(image_data, NULL, true, kCGRenderingIntentDefault) :
				CGImageCreateWithJPEGDataProvider(image_data, NULL, true, kCGRenderingIntentDefault);
			
			if (image)
			{
				Frame* frame = new Frame;
				frame->absolutePath = [[dir_path_string stringByAppendingPathComponent:file_name] UTF8String];
				frame->imageName = [file_name UTF8String];
				frame->isPlaced = false;
				
				int width = frame->fullImageSize.width = CGImageGetWidth(image);
				int height = frame->fullImageSize.height = CGImageGetHeight(image);
				
				CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
				unsigned char *rawData = (unsigned char*)calloc(height * width * 4, sizeof(unsigned char));
				NSUInteger bytesPerPixel = 4;
				NSUInteger bytesPerRow = bytesPerPixel * width;
				NSUInteger bitsPerComponent = 8;
				CGContextRef context = CGBitmapContextCreate(rawData, width, height,
					bitsPerComponent, bytesPerRow, colorSpace,
					kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
				CGColorSpaceRelease(colorSpace);

				CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
				CGContextRelease(context);

				// Now your rawData contains the image data in the RGBA8888 pixel format.
				#define RAW_DATA_INDEX(xx, yy) ((bytesPerRow * (yy)) + (xx) * bytesPerPixel)
				#define ALPHA_AT(xx, yy) (rawData[RAW_DATA_INDEX((xx), (yy)) + 3])
				
				// strip alpha
				int x, y;
				int alpha;
				
//				for (y = 0; y<height; ++y)
//				{
//					for (x = 0; x<width; ++x)
//					{
//						cout << " ( " << (int)(rawData[RAW_DATA_INDEX(x, y)]) << ", "
//							<< (int)rawData[RAW_DATA_INDEX(x, y) + 1] << ", "
//							<< (int)rawData[RAW_DATA_INDEX(x, y) + 2] << ", "
//							<< (int)rawData[RAW_DATA_INDEX(x, y) + 3] << ") ";
//					}
//				}
				
				// left
				alpha = 0;
				for (x=0; x<width; ++x)
				{
					for (y=0; y<height && !alpha; ++y)
					{
						alpha = ALPHA_AT(x, y);
					}
					
					if (alpha)
						break;
				}
				frame->imageBounds.x = x;

				// right
				alpha = 0;
				for (x=width-1; x>=0; --x)
				{
					for (y=0; y<height && !alpha; ++y)
					{
						alpha = ALPHA_AT(x, y);
					}
					
					if (alpha)
						break;
				}
				frame->imageBounds.width = MAX(x - frame->imageBounds.x + 1, 0);

				// top
				alpha = 0;
				for (y=0; y<height; ++y)
				{
					for (x=0; x<width && !alpha; ++x)
					{
						alpha = ALPHA_AT(x, y);
					}
					
					if (alpha)
						break;
				}
				frame->imageBounds.y = y;

				// bottom
				alpha = 0;
				for (y=height-1; y>=0; --y)
				{
					for (x=0; x<width && !alpha; ++x)
					{
						alpha = ALPHA_AT(x, y);
					}
					
					if (alpha)
						break;
				}
				frame->imageBounds.height = MAX(y - frame->imageBounds.y + 1, 0);
				
				frames.push_back(frame);
				
				free(rawData);
				CFRelease(image);
			}
			
			CFRelease(image_data);
		}
	}
	
	return frames;
}

void CGImageWriteToFile(CGImageRef image, NSString *path)
{
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);

    if (!CGImageDestinationFinalize(destination))
	{
		cout << @"ERROR: Failed to write image to " << [path UTF8String];
    }

    CFRelease(destination);
}

void ssg::write_image(const FramesList& frames, const ssg::size_t& size, const std::string& path)
{
	// Create a bitmap graphics context of the given size
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	unsigned char *rawData = (unsigned char*)calloc(size.height * size.width * 4, sizeof(unsigned char));
    CGContextRef context = CGBitmapContextCreate(rawData, size.width, size.height, 8, 4 * size.width,
		colorSpace,	kCGImageAlphaPremultipliedLast);
	
//	CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, size.height);
//	CGContextConcatCTM(context, flipVertical);  
	
	for (FramesList::const_iterator i=frames.begin(), e=frames.end(); i!=e; ++i)
	{
		Frame* frame = *i;
		NSString* img_path = [NSString stringWithUTF8String:frame->absolutePath.c_str()];
		
		CGDataProviderRef image_data = CGDataProviderCreateWithCFData((CFDataRef)[NSData
			dataWithContentsOfFile:img_path]);
		CGImageRef image = [[img_path pathExtension] isEqualToString:@"png"] ?
			CGImageCreateWithPNGDataProvider(image_data, NULL, true, kCGRenderingIntentDefault) :
			CGImageCreateWithJPEGDataProvider(image_data, NULL, true, kCGRenderingIntentDefault);
		CGImageRef partial_image = CGImageCreateWithImageInRect(image, CGRectMake(frame->imageBounds.x, frame->imageBounds.y,
			frame->imageBounds.width, frame->imageBounds.height));
		CGContextDrawImage(context, CGRectMake(frame->pos.x, size.height - frame->pos.y - frame->imageBounds.height, frame->imageBounds.width, frame->imageBounds.height),
			partial_image);
		
		CFRelease(partial_image);
		CFRelease(image);
	}
	
    CGImageRef out_image = CGBitmapContextCreateImage(context);
	CGImageWriteToFile(out_image, [NSString stringWithUTF8String:path.c_str()]);

    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
	
	CFRelease(out_image);
	free(rawData);
}
