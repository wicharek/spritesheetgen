//
//  main.cpp
//  spritesheetgen
//
//  Created by Vitaliy Ivanov on 6/26/12.
//

#include <iostream>
#include <fstream>
#include <string>
#include <list>
#include <vector>
#include <memory>

#include "types.h"
#include "frame.h"
#include "platform.h"

#ifdef DEBUG
#define SSG_DEBUG_LOG
#endif

using namespace ssg;
using namespace std;

namespace ssg
{

bool compare_frame_by_area(Frame* f1, Frame* f2)
{
	return (f1->imageBounds.width * f1->imageBounds.height) >
		(f2->imageBounds.width * f2->imageBounds.height);
}

class Texture
{
	vector<rect_t> rectangles_;
	rect_t ownRect_;
	int insertSpace_;

	bool intersectRootNode(const rect_t& rect)
	{
		if ((rect.x + rect.width > ownRect_.width) || (rect.y + rect.height > ownRect_.height))
		{
			return true;
		}

		for (int i = 0; i < rectangles_.size(); ++i)
		{
			const rect_t& fromRoot = rectangles_.at(i);
			if (fromRoot.intersects(rect))
			{
				return true;
			}
		}

		return false;
	}

public:
	Texture(int x0, int y0, int width, int height) :
		ownRect_(x0, y0, width, height), insertSpace_(1)
	{
		
	}

	void addRect(const rect_t& rect)
	{
		rectangles_.push_back(rect);
	}

	void cleanup()
	{
		rectangles_.clear();
	}
	
	bool place(Frame* frame, const rect_t& newItemRect)
	{
		if (!intersectRootNode(newItemRect))
		{
			frame->pos.x = newItemRect.x;
			frame->pos.y = newItemRect.y;
			frame->isPlaced = true;
			addRect(newItemRect);
			return true;
		}
		else
		{
			return false;
		}
	}

	bool placeItem(Frame* item)
	{
		rect_t itemRect = rect_t(0, 0, item->imageBounds.width + 1, item->imageBounds.height + 1);
		if (place(item, itemRect))
			return true;

		for (int i = 0; i < rectangles_.size(); ++i)
		{
			const rect_t& rectFromRoot = rectangles_.at(i);
			itemRect = rect_t(rectFromRoot.x + rectFromRoot.width + insertSpace_, rectFromRoot.y, itemRect.width, itemRect.height);
			if (place(item, itemRect))
				return true;
		}
		for (int i = 0; i < rectangles_.size(); ++i)
		{
			const rect_t& rectFromRoot = rectangles_.at(i);
			itemRect = rect_t(rectFromRoot.x, rectFromRoot.y + rectFromRoot.height + insertSpace_, itemRect.width, itemRect.height);
			if (place(item, itemRect))
				return true;
		}
		for (int i = 0; i < rectangles_.size(); ++i)
		{
			const rect_t& rectFromRoot = rectangles_.at(i);
			itemRect = rect_t(rectFromRoot.x + rectFromRoot.width + insertSpace_, rectFromRoot.y + rectFromRoot.height + insertSpace_,
				itemRect.width, itemRect.height);
			if (place(item, itemRect))
				return true;
		}

		return false;
	}
};

bool try_place(FramesList& frames, const ssg::size_t& size)
{
	#ifdef SSG_DEBUG_LOG
	cout << "Trying size: " << size.width << ", " << size.height << endl;
	#endif

	for (FramesList::iterator i=frames.begin(), e=frames.end(); i!=e; ++i)
	{
		(*i)->isPlaced = false;
	}
	
	int left = frames.size();

	Texture tex(0, 0, size.width, size.height);

	for (FramesList::iterator i=frames.begin(), e=frames.end(); i!=e; ++i)
	{
		Frame* frame = *i;

		if (!(frame->isPlaced))
		{
			if (tex.placeItem(frame))
			{
				--left;
			}
		}
	}
	
	#ifdef SSG_DEBUG_LOG
	cout << " frames left: " << left << endl;
	#endif
	
	return left == 0;
}

void write_plist(const FramesList& frames, const ssg::size_t& size, const std::string& path, const std::string& name)
{
	ofstream plist(path.c_str());
	
	plist << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		<< "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
		<< "<plist version=\"1.0\">\n"
		<< "<dict>\n"
		<< "	<key>texture</key>\n"
		<< "	<dict>\n"
		<< "		<key>width</key>\n"
		<< "		<integer>" << size.width << "</integer>\n"
		<< "		<key>height</key>\n"
		<< "		<integer>" << size.height << "</integer>\n"
		<< "		</dict>\n"
		<< "	<key>frames</key>\n"
		<< "	<dict>\n";
	
	for (FramesList::const_iterator i=frames.begin(), e=frames.end(); i!=e; ++i)
	{
		Frame* frame = *i;

		plist << "		<key>" << frame->imageName << "</key>\n"
			<< "		<dict>\n"
			<< "			<key>x</key>\n"
			<< "			<integer>" << frame->pos.x << "</integer>\n"
			<< "			<key>y</key>\n"
			<< "			<integer>" << frame->pos.y << "</integer>\n"
			<< "			<key>width</key>\n"
			<< "			<integer>" << frame->imageBounds.width << "</integer>\n"
			<< "			<key>height</key>\n"
			<< "			<integer>" << frame->imageBounds.height << "</integer>\n"
			<< "			<key>offsetX</key>\n"
			<< "			<real>" << -frame->fullImageSize.width * 0.5 + (frame->imageBounds.x + frame->imageBounds.width * 0.5) << "</real>\n"
			<< "			<key>offsetY</key>\n"
			<< "			<real>" << frame->fullImageSize.height * 0.5 - (frame->imageBounds.y + frame->imageBounds.height * 0.5) << "</real>\n"
			<< "			<key>originalWidth</key>\n"
			<< "			<integer>" << frame->fullImageSize.width << "</integer>\n"
			<< "			<key>originalHeight</key>\n"
			<< "			<integer>" << frame->fullImageSize.height << "</integer>\n"
			<< "		</dict>\n";
	}
	
	plist << "	</dict>\n";
	
	plist << "</dict>\n"
		<< "</plist>\n";
}

}

int main(int argc, const char * argv[])
{
	on_start();
	
	if (argc < 4 || (argc >= 2 && string(argv[1]) == "-help"))
	{
		cout << argv[0] << "\"<input-dir-path>\" \"<output-dir-path>\" \"<name>\" \n";
		
		on_end();
		return -1;
	}
	
	string input_dir(argv[1]);
	string output_dir(argv[2]);
	string name(argv[3]);
	
	cout << "Generating spritesheet (input: \"" << input_dir << "\" output: \"" << (output_dir + "/" + name) << "\" )..." << endl;
	
	FramesList frames = frames_from_dir(input_dir);
	frames.sort(compare_frame_by_area);
	
	#ifdef SSG_DEBUG_LOG
	cout << endl << "Frames: " << endl;
	for (FramesList::const_iterator i=frames.begin(), e=frames.end(); i!=e; ++i)
	{
		cout << "{ \"" << (*i)->absolutePath << "\", { "
			<< (*i)->imageBounds.x << ", "
			<< (*i)->imageBounds.y << ", "
			<< (*i)->imageBounds.width << ", "
			<< (*i)->imageBounds.height << " } "
			<< "}" << endl;
	}
	cout << endl;
	#endif
	
	const ssg::size_t sizes[] =
	{
		{ 128, 128 },
		{ 256, 128 },
		{ 128, 256 },
		
		{ 256, 256 },
		{ 512, 256 },
		{ 256, 512 },
		
		{ 512, 512 },
		{ 1024, 512 },
		{ 512, 1024 },
		
		{ 1024, 1024 },
		{ 2048, 1024 },
		{ 1024, 2048 },
		
		{ 2048, 2048 },
		{ 4096, 2048 },
		{ 2048, 4096 },
		
		{ 4096, 4096 }
	};
	
	for (int i=0; i<sizeof(sizes) / sizeof(ssg::size_t); ++i)
	{
		if (try_place(frames, sizes[i]))
		{
			#ifdef SSG_DEBUG_LOG
			cout << endl;
			#endif
			
			write_image(frames, sizes[i], output_dir + "/" + name + ".png");
			write_plist(frames, sizes[i], output_dir + "/" + name + ".plist", name);
			
			cout << " done (size: " << sizes[i].width << ", " << sizes[i].height << ")" << endl;
			
			on_end();
			return 0;
		}
	}
	
	#ifdef SSG_DEBUG_LOG
	cout << endl;
	#endif
	
	cout << "ERROR: Couldn't place all frames" << endl;
	
	on_end();
	return 1;
}
