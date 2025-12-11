# Makefile for thinkcy-status binary

CC ?= gcc
CFLAGS ?= -Wall -Os -s
LDFLAGS ?= 
TARGET = thinkcy-status

SRC = thinkcy-status.c
OBJ = $(SRC:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJ)

install: $(TARGET)
	install -D -m 0755 $(TARGET) $(DESTDIR)/usr/bin/$(TARGET)

.PHONY: all clean install
