CC		= g++
#CXXFLAGS	= -Wall -g -std=c++11 -no-pie
CXXFLAGS	= -Wall -O2 -s -std=c++11 -no-pie
DEPS		= xmkit.h
OBJ		= xmkit.o xm2sleizsatrio.o


xm2sleizsatrio: $(OBJ)
	$(CC) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.cpp $(DEPS)
	$(CC) -c $(CXXFLAGS) -o $@ $< $(LDFLAGS)

.PHONY: clean
clean:
	rm *.o
