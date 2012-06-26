//
//  Frame.h
//  spritesheetgen
//
//  Created by Vitaliy Ivanov on 6/26/12.
//  Copyright (c) 2012 Factorial Complexity. All rights reserved.
//

#pragma once

#include <string>
#include <list>

#include "types.h"

namespace ssg
{
	class Frame
	{
	public:
		point_t pos;
		bool isPlaced;
		
		std::string absolutePath;
		std::string imageName;
		size_t fullImageSize;
		rect_t imageBounds;
	};
	
	typedef std::list<Frame*> FramesList;
}
