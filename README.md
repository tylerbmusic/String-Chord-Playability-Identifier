# String Chord Playability Identifier
This MuseScore 4 pluin tells you if your selected chord is playable on the instrument (works for violin/viola/cello/double bass). If a chord is unplayable, it will tell you the measure number, the time, and the instrument that is playing the chord.  
Important note: The measure number algorithm breaks when there is a key signature change.  
Another Important note: The time will sometimes be .000000000001 seconds off, this is due to floating point operations and I don't really feel like fixing it.  
It is recommended to set the plugin to a shortcut (Plugins > Manage Plugins... > String Chord Playability Identifier > Edit shortcut > double click on the item).  
  
For those who are reading the code, notice (especially on lines 299 and 300) that I've made the comments internationally compatible!
