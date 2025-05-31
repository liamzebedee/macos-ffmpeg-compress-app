CC = clang
CFLAGS = -Wall -framework Cocoa

TARGET = VideoCompressor
SRC = main.m

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)

.PHONY: all clean 