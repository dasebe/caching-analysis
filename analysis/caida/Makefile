TARGET = rewrite_caida
OBJS += rewrite_caida.o

CXX = g++
CXXFLAGS += -std=c++11
CXXFLAGS += -O3 -ffast-math -march=native
CXXFLAGS += -Wall -Werror 
LDFLAGS += $(LIBS) -lpthread

all:		$(TARGET)

debug: CXXFLAGS += -ggdb  -D_GLIBCXX_DEBUG # debug flags
debug: $(TARGET)

$(TARGET):	$(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CXX) $(CXXFLAGS) -c -o $@ $<

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	-rm $(TARGET) $(OBJS) $(DEPS)
