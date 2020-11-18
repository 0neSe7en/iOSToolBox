# Created by Kael

if application "System Preferences" is running then
    tell application "System Events"
        set theID to unix id of processes whose name is "System Preferences"
        try
            do shell script "kill -9 " & theID
        end try
    end tell
end if

tell application "System Preferences"
    activate
    set the current pane to pane id "com.apple.preferences.AppleIDPrefPane"
    tell application "System Events"
        repeat until window "Apple ID" of application process "System Preferences" exists
        end repeat
        set theWindow to window "Apple ID" of application process "System Preferences"
        
        repeat until row 3 of table 1 of scroll area 1 of theWindow exists
        end repeat
        select row 3 of table 1 of scroll area 1 of theWindow
        
        repeat until group 1 of theWindow exists
        end repeat
        set theGroup to group 1 of theWindow
        
        repeat until button "获取验证码" of group 9 of group 1 of group 1 of UI element 1 of scroll area 1 of theGroup exists
        end repeat
        set theButton to button "获取验证码" of group 9 of group 1 of group 1 of UI element 1 of scroll area 1 of theGroup
        
        click theButton
        
        repeat until sheet 1 of theWindow exists
        end repeat
        set theSheet to sheet 1 of theWindow
        
        set theDescription to the name of second static text of theSheet
        set theCode to text ((offset of "为：" in theDescription) + 2) thru end of theDescription
        
        click button "好" of theSheet
    end tell
    
    quit
end tell

return theCode