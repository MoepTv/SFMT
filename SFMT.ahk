; Stream-Friendly Music Ticker v1.1
; Original Code: https://github.com/gustafsonk/SFMT
; Edited Code: https://github.com/thesymbol/SFMT

; Description:
; This script is intended to make it possible to share the currently playing song from your media
; player through a streaming program. It works by scraping the title of your media player's window,
; outputting the part you want to a file, and reading the file through a streaming program.

; Supported Media Players?
; Winamp, foobar2000, Spotify, YouTube (via web browser), MusicBee, MediaMonkey, VLC, WMP, iTunes,
; and any other media player that can display the currently playing song in the title of its window.

; Supported Streaming Programs?
; OBS, XSplit, FFsplit, and any other streaming program that can read text from a file.

; Pros and Cons?
; + No dependency on any specific media player
; + Supports Unicode characters
; + Easy to trim junk off the beginning and end of a window title
; + Fix for padding out scrolling text in OBS
; + Multi-platform (untested, but use IronAHK instead of AutoHotkey_L)
; + Open-source, well-documented, and easy-to-edit
; - No GUI for configuration (yet)

; Instructions:
; 1. Download and install AutoHotkey from http://ahkscript.org/ (should be the default one).
; 2. Save/Extract the SFMT.ahk file to your computer (ZIP button in the top left of GitHub).
; 3. Run this file by double-clicking on it to generate the output file, which is where your now
;    playing song will be later. By default, it's "nowplaying.txt" and refreshes every 3 seconds.
; 4. Open your media player of choice and begin playing music.
; 5. Using your streaming program, add a text source for the output file.
; 6. Right-click the .ahk file, click Edit Script, and edit the CONFIGURE ME section below for your
;    media player/streaming program (see example below for help).
; 7. While configuring the file, you should perform the following workflow: edit the file,
;    save the file, right-click the H icon in the system tray, click Reload This Script,
;    and finally open the output file/preview the stream to see if it looks the way you want.

; Example Configuration:
; First get the title of your media player's window. You can do this by hovering over the program
; in the taskbar or system tray and waiting a bit for text to appear. If you're having trouble with
; this or you can't find it, you can still figure it out by looking at the contents of the output
; file after you do this next step. This is an example title I see when playing a song in Winamp:
; "16. Carly Rae Jepsen - Call Me Maybe - Winamp".
;
; Now you need to pick a part of the window title that will always be there while playing songs,
; which can usually be the program's name itself. In this example, "Winamp" will always be in the
; window's title so I can use that. Note that any other window with "Winamp" in it could interfere
; and be grabbed instead. Finally, place this value by the spot marked PART 1 in the CONFIGURE ME
; section. You can now perform Step 7 above to test if this part works for you.
;
; Now you need to trim off the parts that you don't want to share on the stream, like the playlist
; number on the left and the media player's name on the right in this example. To trim the left side,
; identify the block of text closest to the left side of the untrimmed text that does not change from
; song to song. In this example, you could use " " (a space), or ". " (a period then space). Now,
; working from left-to-right, check if this block of text won't occur before you want; otherwise, it
; will trim from there instead. For example, if the title began with "Curiosity - 16. " and I was
; using " ", then it would trim off "Curiosity " when I wanted to trim off all of it. Using ". "
; instead would fix this problem. Many media players give you near full control over the look and
; ordering of the title elements so keep this in mind if you can't get what you want. To trim the
; right side, repeat this procedure working from right-to-left instead. In this example, I want to
; trim " - Winamp" so I can't use " ", but I can use " -" or even " - Winamp". Finally, place these
; values by the two spots marked PART 2 in the CONFIGURE ME section.
;
; If you're using OBS to stream and scrolling the text, then you may want to edit PART 3 to make it
; look nicer. Other than that, you should be good to go and comfortable editing other things in the
; CONFIGURE ME section at the very least.

; CONFIGURE ME (START)
  ; Getting the media player's window title, assumes no other window titles have this text
  windowTitle := "Winamp"  ; PART 1: The media player's window title needs to always have this text
  SetTitleMatchMode 2  ; Look everywhere in window titles for a match, not just the beginning
  DetectHiddenWindows, on  ; Also check window titles minimized to the system tray

  ; Parsing the media player's window title, use "" to not trim one or both of the sides
  firstAfter := ""  ; PART 2: Everything left of the first instance of this and itself is trimmed
  lastBefore := ""  ; PART 2: Same idea above except this trims right and reads right-to-left

  ; Set the output file
  outputFile := "nowplaying.txt"

  ; Refresh rate in milliseconds for repeating this script
  refreshRate = 3000

  ; For scrolling text that wraps continuously without spacing (OBS), use "" to not use this
  scrollSeparator := ""  ; PART 3: Separate the first character from the last character
  AutoTrim, off  ; Leading/trailing space is ignored by AHK by default
  
  paused := "" ; The paused text that you want to change. (leave empty to disable)
  pausedEdited := "Music Paused" ; The paused text to change to.

  ; All 3 streaming programs can use UTF-8 to display Unicode characters
  FileEncoding, UTF-8
; CONFIGURE ME (END)


; PROBABLY DON'T CONFIGURE ME
  ; Part of the AHK template
  #NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
  ; #Warn  ; Enable warnings to assist with detecting common errors.
  SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
  SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

  ; Keep the script running forever
  #Persistent

  ; Main logic of the script
  Gosub, Update  ; Update immediately on script start
  SetTimer, Update, %refreshRate%  ; Update forever on a periodic interval
  return

  Update:
    ; Get the unparsed title of the media player's window
    WinGetTitle, title, %windowTitle%

    ; Remove junk at the beginning and end of the title
    TrimText(title, firstAfter, lastBefore)

    ; Separate the first and last character with a separator for better continuous text scrolling
    title = %scrollSeparator%%title%

    ; Check if the file needs to be updated with a new title (avoids unneeded disk writing)
    if !FileEqualsText(outputFile, title)
    {
      ; Replace the file for a new title
      OverwriteFile(outputFile, title)
    }

    ; If we use scrollSeperator include those in the search for the text
    pausedV = %scrollSeparator%%paused%
    ; If we use scrollSeperator add those to the paused edited text
    pausedEditedV = %scrollSeparator%%pausedEdited%

    ; Check if the file needs to be edited to display another text while paused
    if FileEqualsText(outputFile, pausedV)
    {
        ; Replace the file for a new paused title
        OverwriteFile(outputFile, pausedEditedV)
    }
    return

  ; Removes all text before and including the first instance of a substring,
  ; as well as all text after and including the last instance of another substring
  TrimText(ByRef text, firstAfter, lastBefore)
  {
    StringGetPos, leftIndex, text, %firstAfter%
    if leftIndex != -1
    {
      ; text found, trim the left
      start := leftIndex + 1 + StrLen(firstAfter)
    }
    else
    {
      ; text not found, don't trim the left
      start := 1
    }

    StringGetPos, rightIndex, text, %lastBefore%, R
    if (rightIndex != -1 && rightIndex != 0)  ; 0 = empty string even though it's right-to-left
    {
      ; text found, trim the right
      length := rightIndex + 1 - start
    }
    else
    {
      ; text not found, don't trim the right
      length := StrLen(text) + 1 - start
    }

    text := SubStr(text, start, length)
  }

  ; See if a file's text equals another text
  FileEqualsText(ByRef file, ByRef text)
  {
    FileRead, fileText, %file%
    if fileText = %text%
    {
      return true
    }
    else
    {
      return false
    }
  }

  ; Overwrites a file's text with new text
  OverwriteFile(ByRef outputFile, ByRef outputText)
  {
    FileDelete, %outputFile%
    FileAppend, %outputText%, %outputFile%
  }