; freo's Stacked Table Previewer v1.16
; Only works in Vista/Windows7 with aero enabled
; 'clay973' on PS for donations

;Features:
;Shows thumbnails of all stacked tables in a preview window
;Adds and removes tables as they are opened and closed
;Click on the thumbnail to activate the table in the stack
;Click the "Leave Table" icon on Pokerstars thumbnails or the Options/Lobby/Stats icons on FTP thumbnails to leave the table
;this will also click the "are you sure you want to leave?" message box
;Displays number of open tables in the preview window title (in the caption)
;Highlights the active table green in the thumbnail (Color and border width can be changed in the user defined settings)
;Highlights the previous active table pink (Color and border width can be changed in the user defined settings)

#SingleInstance Force
#NoEnv

DetectHiddenWindows,On
SetTitleMatchMode, 2

OnMessage(0x201,"clickevent")
OnMessage(0x46, "WM_WINDOWPOSCHANGING")

;------------------------------------------------------------------------------------------------------------------
;User defined settings
pokersite=ft                   ;Pokersite ID - ps for Pokerstars : ft for Full Tilt : cu for customised (you'll need to change cu settings further down)
hostwindoww=800                ;Host preview window width             
hostwindowh=900                 ;Host preview window height
hostwindowx=800                 ;Host preview window x position on screen
hostwindowy=0                  ;Host preview window y position on screen
refreshrate=3000                ;Number of seconds to wait between refreshes (1000 = 1 second)
activebordersize=4              ;Width of the colored border for showing active and last active tables
activebordercolor=00FF00        ;Color of the highlight border for the active window
lactivebordercolor=FF00FF       ;Color of the highlight boredr for the last active window

;------------------------------------------------------------------------------------------------------------------

if pokersite = ps
{
    ptablebasew=483                                     ;Poker table base resolution width(For stars this is the smallest table resolution (483 x 353)
    ptablebaseh=353                                     ;Poker table base resolution height(For stars this is the smallest table resolution (483 x 353)
    
    ;Close settings - On Pokerstars this is the area of the Leave Table icon in the top right of the thumbnail
    closexl=418                                         ;Left x position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh 
    closexr=481                                         ;Right x position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh 
    closeyt=24                                          ;Top y position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh 
    closeyb=42                                          ;Bottom y position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh
    
    windowtitle=ahk_class PokerStarsTableFrameClass     ;Window title to match to find tables - Pokerstars (use window class (ahk_class prefixed))
    windowtitleexclude=                                 ;Window title to exclude 
}
else if pokersite = ft
{
    ptablebasew=480                                     ;Poker table base resolution width
    ptablebaseh=351                                     ;Poker table base resolution height
    
    ;Close settings - On Full Tilt this is the area of the blue Options/Lobby/Stats icons in the top right of the thumbnail
    closexl=427                                         ;Left x position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh 
    closexr=478                                         ;Right x position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh 
    closeyt=22                                          ;Top y position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh 
    closeyb=52                                          ;Bottom y position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh
    
    windowtitle= Logged In As ahk_class QWidget             ;Window title to match to find tables - (use window class (ahk_class prefixed))
    windowtitleexclude=Full Tilt                        ;Window title to exclude  
}
else if pokersite = cu         ;Change these settings for a custom site/application
{
    ptablebasew=483                                     ;Poker table base resolution width(For stars this is the smallest table resolution (483 x 353)
    ptablebaseh=353                                     ;Poker table base resolution height(For stars this is the smallest table resolution (483 x 353)
    closexl=418                                         ;Left x position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh 
    closexr=481                                         ;Right x position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh 
    closeyt=24                                          ;Top y position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh 
    closeyb=42                                          ;Bottom y position of leave table button in relation to the resolution set against ptablebasew & ptablebaseh
    windowtitle= - Table 1                             ;Window title to match to find tables - Pokerstars (use control type)
    windowtitleexclude=                                 ;Window title to exclude 
}

hModule := DllCall("LoadLibrary", "str", "dwmapi.dll")       ;Load dwmapi.dll for handling thumbnails
SysGet, borderxa, 45                                         ;Size of the x window 3D border
Sysget, borderya, 46                                         ;Size of the y window 3D border
Sysget, captionha, 4                                         ;Size of the caption
Sysget, borderxb, 5                                          ;Size of the x window normal border
Sysget, borderyb, 6                                          ;Size of the y window normal border
borderx := borderxa + borderxb                               ;Total size of the x border
bordery := borderya + borderyb                               ;Total size of the y border
captionh := captionha + bordery                             ;Total size of the caption
clientareah := hostwindowh - bordery - captionh              ;Height of the area thumbnail windows can be placed in
clientareaw := hostwindoww - borderx - borderx               ;Width of the area thumbnail windows can be placed in
clientareax := hostwindowx + borderx
clientareay := hostwindowy + captionh
ptablehwratio := (ptablebaseh-captionha) / ptablebasew                  ;Ratio used for scaling thumbnail window size
lastactive:=0
thisactive:=0
borderguix:=clientareax
borderguiy:=clientareay

;Create preview window
Gui, 99: +LastFound +LabelForm1_
Gui, 99: Color, 000000 
WinSet, TransColor, 000000                    
target := WinExist()

;Test calls
;DLL hook for detecting window activations (for colored active table borders)
DllCall( "RegisterShellHookWindow", UInt,target) 
MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
OnMessage( MsgNum, "ShellMessage" )

;Create GUi's for colored border
;Gui 1 for active table
Gui, 1:+LastFound +Owner99 
Gui, 1:Color, %activebordercolor%
Gui, 1:-Caption -Border
activegui:=WinExist()

;Gui 2 for last active table
Gui, 2:+LastFound +Owner99 
Gui, 2:Color, %lactivebordercolor%
Gui, 2:-Caption -Border
lactivegui:=WinExist()


;Create Empty variables for storing thumbnail links
Loop, 98
{
    source%A_Index%_hnd:=0
    source%A_Index%_thumb:=0
    source%A_Index%_wide:=0
}

;Show existing tables
WinGet, list, list, %windowtitle%, ,%windowtitleexclude%
tblcount:=0
Loop, %list%
{
    tblcount++
    tblcount%tblcount%:=list%A_Index% 
}

currentcnt:=tblcount                           

;Calculate child window size and number per row
tablesw := numtablesw(currentcnt)
childwinw := Floor(calcwinsize(tablesw, currentcnt))
childwinh := Floor(childwinw * ptablehwratio)

;Create child windows for tables already open
Loop, %tblcount%
{
    thisid:=tblcount%A_Index%
    addchild(A_Index, thisid)
}

Gui, 99: Show, w%hostwindoww% h%hostwindowh% x%hostwindowx% y%hostwindowy%, %tblcount% Tables Previewed

;Infinite loop to monitor table opens, closes & resizes.
Loop,
{    
    Sleep, %refreshrate%
    
    wasredrawn:=0
    
    ;Find any closed tables
    Loop, 98
    {
        thishnd:=source%A_Index%_hnd
        if (thishnd > 0)
        {
            IfWinNotExist, ahk_id %thishnd%
            {
                source%A_Index%_hnd:=0
                source%A_Index%_thumb:=0
                source%A_Index%_wide:=0
            }
        }
    }
        
    ;Get new list of tables
    WinGet, list, list, %windowtitle%, ,%windowtitleexclude% 
    tblcount:=0
    Loop, %list%
    {
        tblcount++
        tblcount%tblcount%:=list%A_Index%    
    }    
    
    ;Find any new tables
    Loop, %tblcount%
    {
        thishnd:=tblcount%A_Index%
        found:=0
        Loop,98
        {
            if (source%A_Index%_hnd = thishnd)
            {
                found:=1
                break            
            }
        }
        
        ;New table found
        if (found = 0)
        {
            ;Find first avail slot
            newslot:=0
            Loop,98
            {
                if (source%A_Index%_hnd = 0)
                {
                    newslot:=A_Index
                    break                    
                }
            }

            ;Determine whether an existing slot is available or a recalculation is required as its a new slot.
            if (newslot <= currentcnt)         ;Existing slot taken, no recalc required
            {
                addchild(newslot, thishnd)
            }
            else                                ;Need to recalculate to determine if new rows or columns are required
            {
                currentcnt += 1
                oldcols:=tablesw
                oldw:=childwinw
                tablesw := numtablesw(currentcnt)
                childwinw := Floor(calcwinsize(tablesw, currentcnt))
                childwinh := Floor(childwinw * ptablehwratio)
                if (oldcols = tablesw) and (oldw = childwinw)       ;Still a slot left at the end of the current config
                    addchild(newslot, thishnd)
                else                                                ;Need to redraw all thumbnails with diff config
                {
                    Loop, 98
                    {
                        unregisterthumbnail(source%A_Index%_thumb)            ;Unregister existing thumbs                         
                    }
                    
                    Loop, %tblcount%
                    {
                        if(A_Index < tblcount)
                        {
                            thisid:=source%A_Index%_hnd
                            addchild(A_Index, thisid)
                        }
                        else
                        {
                            thisid:=tblcount%A_Index%
                            addchild(A_Index, thishnd)
                        }
                    }
                    wasredrawn:=1
                }
            }
        }
    }
    
    ;Check if any tables have been resized and if so, redraw
    if (wasredrawn = 0)                 
    {
        Loop, %tblcount%
        {
            retable:=source%A_Index%_hnd
            WinGetPos,wx,wy,ww,wh,ahk_id %retable%
            if (ww != source%A_Index%_wide)
            {
                unregisterthumbnail(source%A_Index%_thumb)
                addchild(A_Index, retable)
            }
        }
    }
    WinSetTitle, ahk_id %target%, ,%tblcount% Tables Previewed
}

Return


;Function to register the thumbnail to the GUI
registerthumbnail(target, source, thumbnum)
{
    Global    
    
    VarSetCapacity(thumbnail,4,0)
    hr1:=DllCall("dwmapi\DwmRegisterThumbnail",UInt,target,UInt,source,UInt, &thumbnail)
    thumbnail:=Numget(thumbnail,0,true)
    source%thumbnum%_hnd:=source
    source%thumbnum%_thumb:=thumbnail
    
    updatethumbnail(source, thumbnum, thumbnail)
}

;Function sets thumbnail properties and displays
updatethumbnail(source, thumbnum, thumbnail)
{    
    /*
    DWM_TNP_RECTDESTINATION (0x00000001)
    Indicates a value for rcDestination has been specified.
    DWM_TNP_RECTSOURCE (0x00000002)
    Indicates a value for rcSource has been specified.
    DWM_TNP_OPACITY (0x00000004)
    Indicates a value for opacity has been specified.
    DWM_TNP_VISIBLE (0x00000008)
    Indicates a value for fVisible has been specified.
    DWM_TNP_SOURCECLIENTAREAONLY (0x00000010)
    Indicates a value for fSourceClientAreaOnly has been specified.
    */
    
    Global  
    
    dwFlags:=0X1 | 0x2 | 0x10
    opacity:=150
    fVisible:=1
    fSourceClientAreaOnly:=1
    
    ;Determine where to position thumbnail based on its number
    rownum := Ceil(thumbnum / tablesw)
    colnum := Mod(thumbnum - 1,tablesw)
    newx := ((colnum) * childwinw)
    newy := ((rownum - 1) * childwinh) 
    neww := newx + childwinw
    newh := newy + childwinh
    
    WinGetPos,wx,wy,ww,wh,ahk_id %source%
    
    VarSetCapacity(dskThumbProps,45,0)
    ;struct _DWM_THUMBNAIL_PROPERTIES
    NumPut(dwFlags,dskThumbProps,0,"UInt")
    NumPut(newx,dskThumbProps,4,"Int")                     ;x coord in relation to the target
    NumPut(newy,dskThumbProps,8,"Int")                     ;y coord in relation to the target
    NumPut(neww,dskThumbProps,12,"Int")                   ;x coord of bottom of the thumb in relation to the target
    NumPut(newh,dskThumbProps,16,"Int")                   ;y coord of the right edge of the thumb in relation to the target
    NumPut(0,dskThumbProps,20,"Int")                      ;x coord of target to start thumb
    NumPut(0,dskThumbProps,24,"Int")                      ;y coord of target to start thumb
    NumPut(ww-borderx,dskThumbProps,28,"Int")                    ;width of the thumb in relation to the source
    NumPut(wh-captionh,dskThumbProps,32,"Int")                    ;height of the thumb in relation to the source
    NumPut(opacity,dskThumbProps,36,"UChar")
    NumPut(fVisible,dskThumbProps,37,"Int")
    NumPut(fSourceClientAreaOnly,dskThumbProps,41,"Int")
    hr2:=DllCall("dwmapi\DwmUpdateThumbnailProperties","UInt",thumbnail,"UInt",&dskThumbProps) 
    source%thumbnum%_wide:=ww-(borderx*2)
   
}


unregisterthumbnail(unthumbnail)
{
    ur1:=DllCall("dwmapi.dll\DwmUnregisterThumbnail", "UInt", unthumbnail)
}


;Function to determine the optimal number of tables wide to show in preview window
numtablesw(totaltables)
{
    if(totaltables > "1")
    {   
        global clientareah
        global clientareaw
        global ptablehwratio
        
        wsize := 0
        wnum := 0
        
        ;The loop value will equal the number of tables per row
        Loop,%totaltables%
        {            
            thiswsize := floor(calcwinsize(A_Index, totaltables))
            
            if (thiswsize >= wsize)
            {    
                wsize := thiswsize
                wnum := A_Index
            }
        }
        return, %wnum%
    }
    Else 
    {
        return, 1
    }
}

;Calculates child window size based on number of tables per row
calcwinsize(tblperrow, totaltables)
{
    global clientareaw
    global clientareah
    global ptablehwratio
    
    calcwsize := clientareaw / tblperrow
    calcrownum := ceil(totaltables / tblperrow)
            
    if ((clientareah / calcrownum) < (ptablehwratio * calcwsize))
    {
        calcwsize := (1 / ptablehwratio) * (clientareah / calcrownum)
    }
    
    Return, calcwsize    
}

;Adds child window to the preview pane
addchild(usenum, previewid)
{
    Global childwinw
    Global childwinh
    Global hostwindoww
    Global hostwindowh
    Global target

    if (usenum > 0) ;If usenum is 0 it is not part of the initial load of existing windows
    {
        registerthumbnail(target, previewid, usenum)
        Return
    }
}

;Function to determine what happens when a thumbnail is clicked
clickevent(wparam)
{
    local id,win,mousex,mousey,thisslot,thisrow,thiscol,xl,xr,yt,yb
    coordmode,mouse,relative
    mousegetpos,mousex,mousey,id
    if (id=target)
    {
        if(tblcount>0)
        {
            ;Calculate slot number
            thisrow:=Ceil((mousey - captionh) / childwinh)
            thiscol:=Ceil((mousex - borderx) / childwinw)
            thisslot:=((thisrow-1)*tablesw)+thiscol
            getcoords(thisslot,thisrow,thiscol,closexl,closexr,closeyt,closeyb,xl,xr,yt,yb)
            win:=source%thisslot%_hnd
            ;Action to take
            if (mousex>=(xl-1) and mousex<=(xr-1) and mousey>=(yt+1) and mousey<=(yb+1))    ;Close table
                if pokersite = ps
                {
                    WinGetTitle, closetitle, ahk_id%win% 
                    winclose,ahk_id%win%  
                    stringleft,endtitle,closetitle,3
                    Loop
                    {
                        IfWinNotExist, ahk_id%win% 
                            break
                        
                        WinGet,closeID,ID,%endtitle% ahk_class #32770
                        if (closeID > 0)
                        {
                            WinActivate,ahk_id%closeID% 
                            SendInput {Enter}
                        }
                    }
                }
                else if pokersite = ft
                {
                    WinGetTitle, closetitle, ahk_id%win% 
                    winclose,ahk_id%win%  
                    stringleft,endtitle,closetitle,3
                    Loop
                    {
                        IfWinNotExist, ahk_id%win% 
                            break
                        
                        WinGet,closeID,ID,%endtitle% ahk_class QWidget,,Logged
                        if (closeID > 0)
                        {
                            WinActivate,ahk_id%closeID% 
                            SendInput {Tab}{Enter}
                        }
                    }                
                }
                else
                {
                    winclose,ahk_id%win%                
                }
            else
            {        
                if (win >0)                                                 ;Activate the window
                    winactivate,ahk_id%win%
            }
        }
    }
}

;Calculates the four coordinates of a rectangle in a thumbnail
getcoords(calcslot,thisrow,thiscol,rectxl,rectxr,rectyt,rectyb,ByRef thisxl,ByRef thisxr,ByRef thisyt,ByRef thisyb)
{
    Global    
    
    ;Calculate coords
    realw:=source%calcslot%_wide
    thisx:= ((thiscol-1) * childwinw)+borderx
    thisy:= ((thisrow - 1) * childwinh)+captionh ;+bordery 
    thisxl:=floor((childwinw*((rectxl-borderx)/(ptablebasew-borderx))) + thisx)
    thisxr:=floor((childwinw*((rectxr-borderx)/(ptablebasew-borderx))) + thisx) 
    thisyt:=floor((childwinh*((rectyt-captionh)/(ptablebaseh-captionh-bordery))) + thisy)
    thisyb:=floor((childwinh*((rectyb-captionh)/(ptablebaseh-captionh-bordery))) + thisy) 
    
    return
}

;Function for docking the border gui's to the preview window
WM_WINDOWPOSCHANGING(wParam, lParam) 
{ 
    Global captionh,borderx,thisactive,lastactive, borderguix, borderguiy
    if (A_Gui = 99) && !(NumGet(lParam+24) & 0x2) ; SWP_NOMOVE=0x2 
    { 
        ; Since WM_WINDOWPOSCHANGING happens *before* the window moves, 
        ; we must get the new position from the WINDOWPOS pointed to by lParam. 
        borderguix := NumGet(lParam+8,0,"int") + borderx
        borderguiy := NumGet(lParam+12,0,"int") + captionh
        
        ; Move - but don't activate - Border Gui's 
        If(thisactive>0)
            Gui, 1:Show, X%borderguix% Y%borderguiy% NA
        
        if(lastactive>0)
            Gui, 2:Show, X%borderguix% Y%borderguiy% NA
    } 
} 

;Function for detecting window activations for setting border colors
ShellMessage( wParam,lParam )
{
    Global
    
    If ((wParam = 4 or wParam = 32772) And WinExist( "ahk_id " lParam ))                       ;  HSHELL_WINDOWACTIVATED = 4, HSHELL_RUDEAPPACTIVATED = 32772
    {    
        ;If the activated window is in the list set the active and last active window
        matchcnt:=0
        Loop, 98 
        {
            matchcnt++
            if(source%matchcnt%_hnd = lParam)
                break
        }    
        if (matchcnt < 98 and thisactive != lParam)
        {
            ;Set and display active table border gui's
            drawborder(1,matchcnt)
            lastactive:=thisactive
            thisactive:=lParam  
            if(lastactive > 0)
            {
                matchcnt:=0
                Loop, 98 
                {
                    matchcnt++
                    if(source%matchcnt%_hnd = lastactive)
                        break
                } 
                drawborder(2,matchcnt)
            }
        }
    }
}

drawborder(guinum, slotnumb)
{
    Global
    ;Get the thumbnail outer edge coords
    thisrow:=Ceil(slotnumb/tablesw)
    thiscol:=Mod(slotnumb - 1,tablesw)+1
    getcoords(slotnumb,thisrow,thiscol,borderx,ptablebasew-borderx,captionh,ptablebaseh-bordery,xl,xr,yt,yb)
    
    if(guinum=1)
        thisgui:=activegui
    else
        thisgui:=lactivegui
    
    xl-=borderx
    xr-=borderx
    yt-=captionh
    yb-=captionh    
    
    xli:=xl+activebordersize
    xri:=xr-activebordersize
    yti:=yt+activebordersize
    ybi:=yb-activebordersize
    neww:=xr-xl
    newh:=yb-yt
        
    ;Draw the border gui
    WinSet, Region, %xl%-%yt% %xr%-%yt% %xr%-%yb% %xl%-%yb% %xl%-%yt%   %xli%-%yti% %xri%-%yti% %xri%-%ybi% %xli%-%ybi% %xli%-%yti%, ahk_id %thisgui%   
    Gui, %guinum%:Show, x%borderguix% y%borderguiy% W%hostwindoww% H%hostwindowh% NA
}

Form1_Close:
	ExitApp
return
Like
Like
Dislike
AHK Script: Stacked Table Previewer
Quote
Multi-Quote This Message
AHK Script: Stacked Table Previewer
03-20-2016
, 10:36 PM
