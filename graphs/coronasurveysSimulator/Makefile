SNAPDIR=../snap-git/snap
#../../../../snap
INCLUDES= -I $(SNAPDIR)/snap-core -I $(SNAPDIR)/glib-core
CC=g++
LINKER   = g++

TARGET   = projectname


# compiling flags here
CFLAGS=-c -O3 -std=c++14
LFLAGS   = -Wall -I. -lm

SRCDIR   = src
OBJDIR   = obj
BINDIR   = bin

SOURCES  := $(wildcard $(SRCDIR)/*.c)
INCLUDES := $(wildcard $(SRCDIR)/*.h)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)


#SOURCES= abstractGraphBasedSurveyDiffusion.cpp abstractSurvey.cpp directEstimationSurvey.cpp  socialGraphSurveyDiffusion.cpp  uniformRandomSpreader.cpp abstractSpreader.cpp scaleUpDirectSurveyComparator.cpp  networkScaleUpSurvey.cpp testGraphSampler.cpp util.cpp
OBJECTS=$(SOURCES:.cpp=.o)
EXECUTABLE=scaleUpDirectSurveyComparator
SNAPLIB=$(SNAPDIR)/snap-core/Snap.o

rm       = rm -f


$(BINDIR)/$(TARGET): $(OBJECTS)
    @$(LINKER) $(OBJECTS) $(LFLAGS) -o $@
    @echo "Linking complete!"

$(OBJECTS): $(OBJDIR)/%.o : $(SRCDIR)/%.c
    @$(CC) $(CFLAGS) -c $< -o $@
    @echo "Compiled "$<" successfully!"

.PHONY: clean
clean:
    @$(rm) $(OBJECTS)
    @echo "Cleanup complete!"

.PHONY: remove
remove: clean
    @$(rm) $(BINDIR)/$(TARGET)
    @echo "Executable removed!"
