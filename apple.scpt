set a to my format_debug_comment("", "size")
log a
set a to my format_debug_comment(a, "markets")
log a
set a to my format_debug_comment("", "")
log a

on format_debug_comment(currentComment, toAdd)
    -- 1. Return empty string if either is empty or toAdd already exists
    if currentComment is "" and toAdd is "" then return ""
    if toAdd is "" then return currentComment
    if currentComment contains toAdd then return currentComment
    
    -- 2. Remove "missing: " prefix if it exists
    set prefix to "missing: "
    if currentComment starts with prefix then
        set currentComment to text ((length of prefix) + 1) thru -1 of currentComment
    end if
    
    -- 3. Split on ", " into a list
    set AppleScript's text item delimiters to ", "
    set commentList to text items of currentComment
    
    -- 4. Append new word
    set end of commentList to toAdd
    
    -- 5. Join back into a string
    set AppleScript's text item delimiters to ", "
    set currentComment to commentList as text
    
    -- 6. Add prefix back
    set currentComment to prefix & currentComment
    
    return currentComment
end format_debug_comment