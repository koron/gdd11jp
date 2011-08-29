SRCS = main.cpp solver.cpp
CPPFLAGS = /EHsc

OBJS = $(SRCS:.cpp=.obj)

APPVER = 5.0
TARGET = WINNT
TARGETLANG = LANG_JAPANESE
_WIN32_IE = 0x0600
!INCLUDE <Win32.Mak>

build : solver.exe

clean :
	del /F *.obj
	del /F *.res
	del /F *.exe
	del /F *.exe.manifest
	del /F *.dll
	del /F *.dll.manifest
	del /F *.pdb
	del /F tags

tags: *.cpp *.hpp
	ctags -R *.cpp *.hpp

rebuild : clean tags build

.PHONY: build clean rebuild

.cpp.obj ::
	$(CC) $(cdebug) $(cflags) $(cvarsdll) $(CPPFLAGS) /c $<

solver.exe : $(OBJS)
	$(link) $(ldebug) $(conlflags) $(conlibsdll) \
		/OUT:$@ $(LINKFLAGS) $(OBJS) $(RESOBJS) $(LIBS)
