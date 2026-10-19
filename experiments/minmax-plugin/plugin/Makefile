CXX      ?= g++
CXXFLAGS ?= -std=c++2b -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Wno-unused-parameter
HYPR_CFLAGS := $(shell pkg-config --cflags hyprland)

BUILD := ../build
TARGET := $(BUILD)/hyprminmax.so

.PHONY: all clean

all: $(TARGET)

$(TARGET): src/main.cpp
	mkdir -p $(BUILD)
	$(CXX) $(CXXFLAGS) $(HYPR_CFLAGS) -shared -o $@ $<

clean:
	rm -f $(TARGET)
