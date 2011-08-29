SRCS = main.cpp solver.cpp log.cpp
DEFINES = /D_CRT_SECURE_NO_WARNINGS=1 /D_BIND_TO_CURRENT_VCLIBS_VERSION=1
CPPFLAGS = /EHsc $(DEFINES)

OBJS = $(SRCS:.cpp=.obj)

APPVER = 5.0
TARGET = WINNT
TARGETLANG = LANG_JAPANESE
_WIN32_IE = 0x0600
!INCLUDE <Win32.Mak>

build : solver.exe

clean :
	del /F *.exe
	del /F *.exe.manifest
	del /F *.obj
	del /F *.pdb
	del /F *.res
	del /F *.zip
	del /F tags

archive : src.zip

tags: *.cpp *.hpp
	ctags -R *.cpp *.hpp

rebuild : clean tags build

.PHONY: build clean rebuild

.cpp.obj ::
	$(CC) $(cdebug) $(cflags) $(cvarsdll) $(CPPFLAGS) /c $<

solver.exe : $(OBJS)
	$(link) $(ldebug) $(conlflags) $(conlibsdll) \
		/OUT:$@ $(LINKFLAGS) $(OBJS) $(RESOBJS) $(LIBS)

src.zip : $(SRCS)
	zip $@ $(SRCS)
