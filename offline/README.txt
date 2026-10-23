BumpMesh - Offline Edition (UNOFFICIAL)
=======================================

This is an unofficial offline build of CNC Kitchen's BumpMesh (bumpmesh.com),
packaged so it runs on a PC with no internet connection. It is not made,
endorsed or supported by CNC Kitchen. Everything it needs is in this folder.
The program itself never downloads anything and never sends your files
anywhere. (The shop and donate links in the page only open if you click them.)


HOW TO START IT
---------------
1. Copy the whole "BumpMesh-Offline" folder to the PC (Desktop or Documents).
2. Double-click:   START BumpMesh.bat
3. A black window says "BumpMesh is running" and your browser opens by itself.
Leave the black window open while you use BumpMesh.


HOW TO STOP IT
--------------
Close the black window. Closing only the browser tab does not stop it.


IF THE BROWSER DOES NOT OPEN
----------------------------
Type this into the address bar:   127.0.0.1:8731
If it shows nothing, use the address on the "Address:" line in the black
window (the number may be 8732, 8733 ... if another program uses 8731).


IF WINDOWS SHOWS A BLUE "WINDOWS PROTECTED YOUR PC" BOX
-------------------------------------------------------
The program is not signed by a big publisher. Click "More info", then "Run
anyway". The program only talks to your own browser on this PC (127.0.0.1).


WHAT IS NOT INCLUDED
--------------------
STL, OBJ, 3MF and STEP/STP files all open. All 101 textures are included, and you
can export STL and 3MF. (STEP files open through the STEP reader meshStep, which
this edition includes, so no internet is needed.)
Exported models go to your normal Downloads folder.


WHAT IS IN THIS FOLDER
----------------------
START BumpMesh.bat         The file you double-click.
bumpmesh-server.exe        The small program that hands the files to your browser.
app\                       BumpMesh itself, the textures and the 3D libraries.
server-source\main.zig     Source code of bumpmesh-server.exe (MIT).
LICENCES-AND-CREDITS.txt   Who made what, under which licence, and what was changed.
LICENSE                    The AGPL-3.0 licence of BumpMesh.
LICENSE-additions.txt      The MIT licence of the server and launcher.

Source for this build:     https://github.com/Diterex/stlTexturizer (branch offline-build)
Original BumpMesh source:  https://github.com/CNCKitchen/stlTexturizer
