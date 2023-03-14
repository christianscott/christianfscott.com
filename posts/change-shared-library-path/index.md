---
title: Changing Shared Library Paths on MacOS
date: "2023-03-14T12:48:43.276Z"
---

Today I wanted to test the performance of [a commit that recently landed in `libuv`](https://github.com/libuv/libuv/commit/d4eb276eea7cb19a888fe97d7759d97c7092ad02). I did not want to wait for a new `libuv` release, a NodeJS release, or to have to wrangle a NodeJS upgrade. Instead, I wanted to test the performance of the new `libuv` commit with the version of NodeJS that I'm already using. I also did not want to have to compile NodeJS from scratch: I have done this before and it took an ungodly amount of time.

Luckily, NodeJS is dynamically linked against `libuv`. This means that `libuv` is not "baked into" the NodeJS executable at compile time, and is loaded at runtime. This means that it should be possible to change the version that's resolved at runtime. Before attempting this, I had a vague impression that I could achieve this by changing a lookup path (`$LD_LOOKUP_PATH`?) but that does not appear to be the case on MacOS. From what I can tell, shared libraries are referenced via *absolute paths*, not "relative" library names. You can see the shared libraries a binary uses via `otool -L`, for example:

```
# otool -L /usr/bin/grep
/usr/bin/grep (architecture x86_64):
        /usr/lib/libbz2.1.0.dylib (compatibility version 1.0.0, current version 1.0.8)
        /usr/lib/liblzma.5.dylib (compatibility version 6.0.0, current version 6.3.0)
        /usr/lib/libz.1.dylib (compatibility version 1.0.0, current version 1.2.11)
        /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1319.0.0)
/usr/bin/grep (architecture arm64e):
        /usr/lib/libbz2.1.0.dylib (compatibility version 1.0.0, current version 1.0.8)
        /usr/lib/liblzma.5.dylib (compatibility version 6.0.0, current version 6.3.0)
        /usr/lib/libz.1.dylib (compatibility version 1.0.0, current version 1.2.11)
        /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1319.0.0)
```

These are called "install names", and seem to be baked into the executable at link time. Since they are absolute, it implies that it's expected that these paths will be the same across systems, which surprised me. [Apparently it's possible to have relative install names](https://medium.com/@donblas/fun-with-rpath-otool-and-install-name-tool-e3e41ae86172), but I was not able to find an executable using one on my system.

To change the path to a shared library used by an executable on MacOS, these are the steps that worked for me:

1. First, you'll need to identify the current path to the shared library used by your executable. You can do this using the otool command. To identify the path to the libuv library used by the node executable, run `otool -L /path/to/node | grep libuv`.

1. Once you've identified the current path, use `install_name_tool` to update the path to the shared library. To update the path to the `libuv` library used by the `node` executable to `/some/other/path/libuv.1.dylib`, run `install_name_tool -change /opt/homebrew/opt/libuv/lib/libuv.1.dylib /some/other/path/libuv.1.dylib /path/to/node`.

1. You now need to resign the executable. By changing one of the install names, you will have invalidated the code signature of the binary. First you'll need to generate a new code signing certificate. Open Keychain Access, go to Keychain Access > Certificate Assistant > Create a Certificate, and follow the prompts to create a new code signing certificate. Make sure you change the "Certificate Type" to "Code Signing".

1. Re-sign the executable by running `codesign -s "Certificate Name" /path/to/node`. Replace "Certificate Name" with the name of your code signing certificate created in the previous step.

1. Verify that the install name has been updated by running `otool -L /path/to/node`, and then by running the executable.
