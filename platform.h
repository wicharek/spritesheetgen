//
//  platform.h
//  spritesheetgen
//
//  Created by Vitaliy Ivanov on 6/26/12.
//  Copyright (c) 2012 Factorial Complexity. All rights reserved.
//

#ifndef spritesheetgen_platform_h
#define spritesheetgen_platform_h

#include <string>

#include "frame.h"

namespace ssg
{
	void on_start();
	FramesList frames_from_dir(const std::string& dir_path);
	void write_image(const FramesList& frames, const ssg::size_t& size, const std::string& path);
	void on_end();
}

#endif
