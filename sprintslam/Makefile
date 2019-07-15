
CC = clang++
CFLAGS = -g -Wall -std=c++17
SRCS = src/*.cpp
PROG = sprintslam
OUTPUT_DIR = build/sprintslam


OPENCV = `pkg-config --cflags --libs opencv4 `
LIBS = $(OPENCV)

$(PROG):$(SRCS)
		$(CC) $(LIBS) $(CFLAGS) $(STD) $(SRCS) -o $(OUTPUT_DIR) -lc++

run: ./sprintslam
	./build/sprintslam
#clang++ $(pkg-config --cflags --libs opencv4) -std=c++17  main.cpp -o sprintslam -lc++ -mmacosx-version-min=10.14
#clang++ `pkg-config --cflags --libs opencv ` -g -Wall -std=c++17  src/*.cpp -o sprintslam -lc++