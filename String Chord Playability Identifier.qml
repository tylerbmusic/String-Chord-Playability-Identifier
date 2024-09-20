import QtQuick 2.1
import QtQuick.Controls 2.15
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Layouts 1.15
MuseScore {
    menuPath: "Plugins.String Chord Playability Identifier"
    version: "0.4"
    description: "Tells you if your selected chord is playable on the instrument (works for violin/viola/cello)."
    title: "String Chord Playability Identifier"
    requiresScore: true
    categoryCode: "composing-arranging-tools"
    thumbnailName: "string_identifier.png"
    id: wiefrn

    /*
    Rules and Notes for Double Stops:
    	1. The chord should all be in one position. //Implemented
    	2. Each finger should be taken only once? //Implemented
    	3. Each string should be taken only once. //Implememnted
    	4. The note should be inside the finger range, inclusive [lowest,highest]. //Implemented
    	5. If a note is on an open string, a finger should not be taken, but the string should be marked as taken. //Implemented
    	6. If a double stop is unplayable, the function should return false; If the double stop is playable, the function should return true. //Implemented
    	7. The array follows the format range[position][string][finger][rangeNo] where rangeNo=0 is the lowest bound and rangeNo=1 is the highest. //Implemented
        8. The same finger can be taken twice if it is needed on two adjacent strings. //Implemented
    */    
    function tBL(text) { //textBoxLog
        consoleBox.text += text + "\n\n";
    }
    function chordPlayable(notes, openStrings, range) { //Notes: cursor.element.notes; openStrings: oS; range: range;
        var debugNotes = "notes: ";
        for (var i = 0; i < notes.length; i++) {
            debugNotes += notes[i].pitch + " "
        }
        tBL(debugNotes);
        tBL("openStrings: " + openStrings);
        tBL("range: " + range);
        var bestCase = false;
        var noteDone; //Tracks whether the note is accounted for.
        var badPitch = ""; //The bad pitches will be stored in this variable.
        for (var position = 0; position < range.length; position++) { //Finger position
            badPitch = ""; //Reset the bad pitches so it doesn't cause a whole lotta confusion and repetition
            var ret = 0; //This should match notes.length by the end.
            var stringsTaken = [-1, -1, -1, -1]; //Tracks whether each string is taken, and what finger the string is on.
            var fingersTaken = [false, false, false, false]; //Tracks whether each finger is taken
            var note; //Current note
            var pitch; //Current pitch
            for (var noteI = 0; noteI < notes.length; noteI++) { //Note Index
                noteDone = false; //The for loop just started, so the note hasn't been accounted for.
                note = notes[noteI]; //Current note
                pitch = note.pitch; //Current pitch
                for (var openSI = 0; openSI < openStrings.length; openSI++) { //open String Index
                    if ((pitch == openStrings[openSI]) && (stringsTaken[openSI] == -1)) { //If the pitch matches an open string and the string isn't taken,
                        stringsTaken[openSI] = -2; //Take the string. -2 means open.
                        noteDone = true; //It's been accounted for.
                        ret++; //This note is playable.
                        tBL("OPEN STRING: " + pitch);
                    } //End open string if statement
                } //End open String Index loop
                if (noteDone == false) { //Only keep checking if it's playable if it hasn't already been marked as playable.
                    var foundPosition = false; //Keeps track of a valid position
                    for (var string = 0; string < range[position].length; string++) { //String number
                        for (var finger = 0; finger < range[position][string].length; finger++) { //Finger number
                            if ((pitch >= range[position][string][finger][0]) && (pitch <= range[position][string][finger][1])) { //If the note is in range
                                if ((stringsTaken[string] == -1) && ((fingersTaken[finger] == false) || ((string > 0) && (stringsTaken[string-1] == finger)) || ((string < 3) && (stringsTaken[string+1] == finger)))) {
                                    stringsTaken[string] = finger; //Take the string.
                                    fingersTaken[finger] = true; //Take the note.
                                    noteDone = true; //It's been accounted for.
                                    ret++; //This note is playable.
                                    foundPosition = true;
                                    tBL(pitch + ", " + position + ", " + string + ", " + finger + "; " + stringsTaken + " and finally, " + fingersTaken)
                                    break;
                                } //End strings & fingers taken if statment
                            } //End note in range if statement
                        } //End Finger number loop
                        if (foundPosition) break; //Break the loop if position found
                    } //End string number loop
                } //End noteDone if statement
                /*if (!noteDone) {
                    break;
                }*/
            } //End Note Index loop
            if (ret == notes.length) { //If all notes are playable together,
                bestCase = true; //Return true, breaking all loops. In this case, true means the double stop is playable.
                break;
            } else {//End all notes playable if statement
                tBL(stringsTaken);
            }
        } //End Finger position loop
        return bestCase;
    } //End chordPlayable

    onRun: {
        wiefrn.visible = false;
        var fullScore = false;
        if (typeof curScore === 'undefined') return;
        var cursor = curScore.newCursor();
        cursor.rewind(2);
        var endStaff = cursor.staffIdx;
        var lastTick = cursor.tick;
        cursor.rewind(1);
        var startStaff = cursor.staffIdx;
        var oS;
        var validInstrument;
        var range;
        if (lastTick == 0) {
            cursor.rewind(0);
            fullScore = true;
            endStaff = cursor.score.nstaves - 1;
        }
        var fT = "";
        for (var staff = startStaff; staff <= endStaff; staff++) {
            (fullScore) ? cursor.rewind(0) : cursor.rewind(1);
            cursor.staffIdx = staff;
            validInstrument = false;
            while ((fullScore && cursor.segment) || cursor.tick < lastTick) {
                if (cursor.element && cursor.element.type === Element.CHORD && cursor.element.notes.length > 1) {
                    if (cursor.element.staff.part.instrumentId == 'strings.violin') {
                        validInstrument = true;
                        oS = [55, 62, 69, 76]; //Open strings
                        //Forget 2D arrays, have a 4D array!!!1!!11 (why do strings have to be so complicated???)
                        //Every line of this array has comments. Enjoy!
                        range = [ //Master array
                            [ //First position
                                [ //String 1
                                    [56,58],[58,60],[59,61],[61,63] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [63,65],[65,67],[66,68],[68,70] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [70,72],[72,74],[73,75],[75,77] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [77,79],[79,81],[80,82],[82,84] //finger ranges
                                ] //End String 4
                            ],//End First position
                            [ //Second position
                                [ //String 1
                                    [58,59],[60,61],[62,63],[64,64] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [66,66],[67,68],[69,70],[71,71] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [72,73],[74,75],[76,76],[77,77] //finger ranges
                                ], //End String 3
                                [ //String 4
                                    [79,80],[81,82],[83,84],[85,100] //finger ranges
                                ] //End String 4
                            ],//End Second position
                            [ //Third position
                                [ //String 1
                                    [60,60],[61,62],[63,64],[65,66] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [67,67],[68,69],[70,71],[72,73] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [74,74],[75,76],[77,78],[79,80] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [81,81],[82,83],[84,85],[86,87] //finger ranges
                                ] //End String 4
                            ],//End Third position
                            [ //Fourth position
                                [ //String 1
                                    [62,62],[63,64],[65,66],[67,67] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [69,69],[70,71],[72,73],[74,74] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [76,76],[77,78],[79,80],[81,81] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [83,83],[84,85],[86,87],[88,88] //finger ranges
                                ] //End String 4
                            ],//End Fourth position
                            [ //Fifth position
                                [ //String 1
                                    [63,64],[65,66],[67,67],[68,69] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [70,71],[72,73],[74,74],[75,76] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [77,78],[79,80],[81,81],[82,83] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [84,85],[86,87],[88,88],[89,90] //finger ranges
                                ] //End String 4
                            ],//End Fifth position
                            [ //Sixth position
                                [ //String 1
                                    [65,66],[66,68],[68,70],[70,71] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [72,73],[73,75],[75,76],[76,77] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [79,80],[80,82],[82,83],[83,84] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [86,87],[87,88],[89,90],[90,91] //finger ranges
                                ] //End String 4
                            ],//End Sixth position
                            [ //Seventh position
                                [ //String 1
                                    [67,68],[68,70],[70,71],[71,72] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [74,75],[75,76],[77,78],[78,79] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [81,82],[82,83],[84,85],[85,86] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [88,89],[89,90],[90,92],[92,93] //finger ranges
                                ] //End String 4
                            ] //End Seventh position
                        ]; //One down, 2 more /*hours*/years to go
                        //Oh wait, other sources show violins have seven positions, and half positions, and more... I'm not doing all that. On to the viola!
                    } else if (cursor.element.staff.part.instrumentId == 'strings.viola') {
                        validInstrument = true;
                        oS = [48, 55, 62, 69];
                        range = [ //Master array
                            [ //First position
                                [ //String 1
                                    [49,50],[51,52],[53,53],[54,55] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [56,57],[58,59],[60,60],[61,62] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [63,64],[65,66],[67,67],[68,69] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [69,70],[71,72],[73,73],[74,75] //finger ranges
                                ],//End String 4
                            ],//End First position
                            [ //Second position
                                [ //String 1
                                    [52,52],[53,54],[54,56],[56,57] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [59,59],[60,61],[61,63],[63,64] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [65,66],[66,68],[68,70],[70,71] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [72,73],[73,75],[76,76],[77,77] //finger ranges
                                ] //End String 4
                            ],//End Second position
                            [ //Third position
                                [ //String 1
                                    [53,54],[54,56],[56,58],[58,60] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [60,61],[61,63],[63,64],[64,66] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [67,68],[68,70],[70,71],[72,73] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [74,75],[75,76],[76,78],[78,80] //finger ranges
                                ] //End String 4
                            ],//End Third position
                            [ //Fourth position
                                [ //String 1
                                    [55,56],[56,58],[58,59],[59,60] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [62,64],[64,64],[65,66],[66,67] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [69,70],[70,72],[72,73],[73,74] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [76,77],[77,78],[78,80],[80,81] //finger ranges
                                ] //End String 4
                            ],//End Fourth position
                            [ //Fifth position
                                [ //String 1
                                    [57,58],[58,59],[60,61],[61,62] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [64,64],[65,66],[66,68],[68,69/*nice*/] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [71,71],[72,73],[73,75],[75,76] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [77,78],[78,80],[80,82],[82,83] //finger ranges
                                ] //End String 4
                            ],//End Fifth position
                            [ //Sixth position
                                [ //String 1
                                    [59,59],[60,61],[61,63],[63,64] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [65,66],[66,68],[68,70],[70,71] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [72,73],[73,75],[75,76],[77,77] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [79,80],[80,82],[82,83],[84,84] //finger ranges
                                ] //End String 4
                            ],//End Sixth position
                            [ //Seventh position
                                [ //String 1
                                    [60,61],[61,63],[63,64],[65,65] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [67,68],[68,70],[70,71],[72,72] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [74,75],[75,76],[77,78],[78,79] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [81,82],[82,83],[84,85],[85,86] //finger ranges
                                ] //End String 4
                            ] //End Seventh position
                        ]; //Two down!
                    } else if (cursor.element.staff.part.instrumentId == 'strings.cello') {
                        validInstrument = true;
                        oS = [36, 43, 50, 57];
                        range = [//Master array
                            [ //First position
                                [ //String 1
                                    [37,37],[38,38],[39,39],[40,41] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [44,44],[45,45],[46,46],[47,48] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [51,51],[52,52],[53,53],[54,55] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [58,58],[59,59],[60,60],[61,61] //finger ranges
                                ] //End String 4
                            ],//End First position
                            [ //Second position
                                [ //String 1
                                    [39,39],[40,40],[41,41],[42,42] //finger ranges
                                ],//End String 1
                            ],//End Second position
                            [ //Third position
                                [ //String 1
                                    [41,41],[42,42],[43,43],[44,44] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [48,48],[49,49],[50,50],[51,51] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [55,55],[56,56],[57,57],[58,58] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [62,62],[63,63],[64,64],[65,65] //finger ranges
                                ] //End String 4
                            ],//End Third position
                            [ //Fourth position
                                [ //String 1
                                    [43,43],[44,44],[45,45],[46,46] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [50,50],[51,51],[52,52],[53,53] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [57,57],[58,58],[59,59],[60,60] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [64,64],[65,65],[66,66],[67,67] //finger ranges
                                ] //End String 4
                            ],//End Fourth position
                            [ //Fifth position
                                [ //String 1
                                    [45,45],[46,47],[47,48] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [52,52],[53,54],[54,55] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [59,59],[60,61],[61,62] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [65,65],[66,67],[67,68] //finger ranges
                                ] //End String 4
                            ],//End Fifth position
                            [ //Sixth position
                                [ //String 1
                                    [46,47],[47,49],[49,50] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [53,54],[54,56],[56,57] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [60,61],[61,63],[63,64] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [67,68],[68,70],[70,71] //finger ranges
                                ] //End String 4
                            ],//End Sixth position
                            [ //Seventh position
                                [ //String 1
                                    [48,49],[49,50],[51,51] //finger ranges
                                ],//End String 1
                                [ //String 2
                                    [55,56],[56,57],[58,58] //finger ranges
                                ],//End String 2
                                [ //String 3
                                    [62,63],[63,64],[65,65] //finger ranges
                                ],//End String 3
                                [ //String 4
                                    [69,70],[70,71],[72,72] //finger ranges
                                ] //End String 4
                            ] //End Seventh position
                        ]; //End Master array
                        //Yay! I'm done with that! Now I have to implement the logic to make my work show.
                    } //End instrument if else-if statements
                    if (validInstrument && cursor.element.notes[1] != undefined) {
                        var notes = cursor.element.notes;
                        var good = chordPlayable(notes, oS, range);;
                        tBL(good);
                        if (!good) {
                            var measureNo = (cursor.tick / ((cursor.measure.timesigActual.numerator * division) / (cursor.measure.timesigActual.denominator * 0.25))) + 1;
                            var minutes = Math.round(Math.floor((cursor.time / 1000) / 60)*10)/10; //A bit of math(s)
                            var seconds = Math.round(((Math.floor(cursor.time / 100) / 10) % 60)*10)/10; //More math(s)
                            var theTime = minutes + ":" + seconds;
                            fT += "unplayable" + " in measure " + measureNo + " at time " + theTime + " played by " + cursor.element.staff.part.longName + "\n";
                        } //End bad if statement
                    } //End valid instrument if statement
                } //End cursor.element if statement
                cursor.next();
            } //End while loop
        } //End staff loop
        
        if (fT == "") {
            fT = "All good";
        }
        box.text = fT;
        box.open();
        //consoleBox.open(); //This was for debugging purposes. This line will most likely be removed in version 1.0.0
    } //End onRun
    //UI
    MessageDialog {
        id: box
        text: "Nope!"
        title: "Open String Checker"
    }
    MessageDialog {
        id: consoleBox
        text: ""
        title: "Console logs"
    }
}