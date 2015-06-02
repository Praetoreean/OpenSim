// Default Program FrameWork
/*

    This script facilitiates the function of the elevator call button located on each floor OUTSIDE the elevator.
    Initialization read .config notecard, and then makes a general call on a channel ComChannel asking for config. A           Response is expected from the Server Prim, containing any extra centralized configuration data. 
        (ie: 
            Elevator Key,
            Elevtaor ComChannel
            ElevatorMode (On/Off)
        )

The Communication system for all parts of the elevator system uses listeners tuned to a channel but nothing else.
In order to allow each script to process both "Broadcast" and "Prim Specific Messages" the UUID of the destination prim is expected as the first parameter in the message. If a message is received where the 1st parameter does not match the scripts UUID, a seperate logic path is taken during the listen procesing.

TX Com Protocol
    1. Button to Elevator Server Communications
        When the Elevator button is reset, it makes an llRegionSay() call on {ComChannel} asking for an extra configuration         details not obtained during the reading of the .config notecard.
        The Request format is: GETCONFIG||OUTCALLBUTTON||{sFloor}
    
    2. Call Elevator to Floor
        The Elevator call buttons when pushed send an llRegionSayTo() the {ElevatorKey} on {ComChannel}
        The Message Sent is simply the iFloor variables sent as a sFloor.
        
RX Com Protocol  
    1. Elevator Server to Button Communcations
        The configuration message is expected in the following format...
            {llGetKey()}||CONFIG||{ElevatorKey}||{ElevatorComChannel}||{OpMode}

    2. General Command Reception
        This Type of communcation is used to notify the call button of status of the elevator.
        The format is as follows...
            {llGetKey()}||CMD||ARRIVED
*/

// Created by Tech Guy of IO

// Configuration Directives
/* This Section Contains Configuration Variables that will contain data set by reading the notecard specified by ConfigFile Variable */
        
    // Communication Channels
    integer MenuComChannel; // Menu Communications Channel for All User Dialog Communications
    integer ComChannel; // General Communication Channel for Inter-Device Communication

// System Variables
/* This Section contains variables that will be used throughout the program. */
    // Admin ACL
        list Admins = []; // List of Administrator Keys Read in from ConfigFile
    // Communication Handles
        integer MenuComHandle; // Menu Communications Handle
        integer ComHandle; // General Communications Handle
    // Config Card Reading Variables
        integer cLine; // Holds Configuration Line Index for Loading Config Loop
        key cQueryID; // Holds Current Configuration File Line during Loading Loop
    // Configuration Directives
        key ElevatorKey = NULL_KEY; // UUID of Elevator Car
        integer Floor = 1;
        key ArriveDing = NULL_KEY;
        
        
// System Constants
/* This Section contains constants used throughout the program */
string BootMessage = "Booting..."; // Default/Initial Boot Message
string ConfigFile = ".config"; // Name of Configuration File
string EMPTY = "";

// Color Vectors
list colorsVectors = [<0.000, 0.455, 0.851>, <0.498, 0.859, 1.000>, <0.224, 0.800, 0.800>, <0.239, 0.600, 0.439>, <0.180, 0.800, 0.251>, <0.004, 1.000, 0.439>, <1.000, 0.522, 0.106>, <1.000, 0.255, 0.212>, <0.522, 0.078, 0.294>, <0.941, 0.071, 0.745>, <0.694, 0.051, 0.788>, <1.000, 1.000, 1.000>];

// List of Names for Colors
list colors = ["BLUE", "AQUA", "TEAL", "OLIVE", "GREEN", "LIME", "ORANGE", "RED", "MAROON", "FUCHSIA", "PURPLE", "WHITE"];  

// System Switches
/* This Section contains variables representing switches (integer(binary) yes/no) or modes (string "modename" */
    // Debug Mode Swtich
        integer DebugMode = FALSE; // Is Debug Mode Enabled before Reading Obtaining Configuation Information
        integer OpMode = FALSE; // Is the Elevator is Active Operations Mode

// Imported Functions
/* This section contains any functions that were not written by Tech Guy */

// Home-Brew Functions
/* This section contains any functions that were written by Tech Guy */

// Debug Message Function
DebugMessage(string msg){
    if(DebugMode){
        llOwnerSay(msg);
    }
}

// Send Any User a Message
SendMessage(string msg, key userid){
    if(userid=="NULL_KEY" || userid==""){
        //llSay(0, msg);
        llRegionSay(0, msg);
    }else if(msg!="" && userid!=NULL_KEY){
        //llInstantMessage(userid, msg);
        llRegionSayTo(userid, 0, msg);
    }else{
        DebugMessage("Error Sending User Message: "+msg);
    }
}

// Main Initialization Logic, Executed Once Upon Script Start    
Initialize(){
    SendMessage(BootMessage, llGetOwner()); // State Booting Message
    MenuComChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); // Randomize Dialog Com Channel
    SendMessage("Configuring...", llGetOwner()); // Message Owner that we are starting the Configure Loop
    cQueryID = llGetNotecardLine(ConfigFile, cLine); // Start the Read from Config Notecard
}

// System has started Function (Runs After Configuration is Loaded, as a result of EOF)
SystemStart(){
    SendMessage("System Started!", llGetOwner());
}

// Ask for Config
AskForConfig(){
    DebugMessage("Asking for configuration directives from Elevator Server...");
    llRegionSay(ComChannel, "GETCONFIG||OUTCALLBUTTON||"+(string)Floor);
}

// Add Admin (Add provided Legacy Name to Admins List after extrapolating userKey)
AddAdmin(string LegacyName){
    string FName = llList2String(llParseString2List(LegacyName, [" "], []), 0);
    string LName = llList2String(llParseString2List(LegacyName, [" "], []), 1);
    DebugMessage("First Name: "+FName+" Last Name: "+LName);
    key UserKey = osAvatarName2Key(FName, LName);
    if(UserKey!=NULL_KEY){
        Admins = Admins + UserKey;
        DebugMessage("Added Admin: "+LegacyName);
    }else{
        DebugMessage("Unable to Resolve: "+LegacyName);
    }
}


//  Configuration Directives Processor (Called Each Time a Line is Found in the config File)
LoadConfig(string data){
    if(data!=""){ // If Line is not Empty
        //  if the line does not begin with a comment
        if(llSubStringIndex(data, "#") != 0)
        {
        //  find first equal sign
            integer i = llSubStringIndex(data, "=");
 
        //  if line contains equal sign
            if(i != -1){
                //  get name of name/value pair
                string name = llGetSubString(data, 0, i - 1);
                //  get value of name/value pair
                string value = llGetSubString(data, i + 1, -1);
                //  trim name
                list temp = llParseString2List(name, [" "], []);
                name = llDumpList2String(temp, " ");
                //  make name lowercase
                name = llToLower(name);
                //  trim value
                temp = llParseString2List(value, [" "], []);
                value = llDumpList2String(temp, " ");
                //  Check Key/Value Pairs and Set Switches and Lists
                if(name=="debugmode"){ // Check DeBug Mode
                    if(value=="TRUE" || value=="true"){
                        DebugMode = TRUE;
                        llOwnerSay("Debug Mode: Enabled!");
                    }else if(value=="FALSE" || value=="false"){
                        DebugMode = FALSE;
                        llOwnerSay("Debug Mode: Disabled!");
                    }
                }else if(name=="comchannel"){
                    ComChannel = (integer)value;
                    DebugMessage("Config Com Channel: "+(string)ComChannel+", Opening Channel...");
                    llListenRemove(ComHandle);
                    llSleep(0.2);
                    ComHandle = llListen(ComChannel, EMPTY, EMPTY, EMPTY);
                    if(ComHandle!=0){
                        DebugMessage("Channel Open!");
                    }else{
                        DebugMessage("Error Opening Channel!");
                    }
                }
        }else{ //  line does not contain equal sign
                SendMessage("Configuration could not be read on line " + (string)cLine, NULL_KEY);
            }
        }
    }
}

// Turn the Call Button On and Off (ie Lights, Glow E.T.C)
ButtonLight(integer Mode){
    if(Mode){
        llSetPrimitiveParams([
            PRIM_COLOR, ALL_SIDES, <255,255,0>, 1.0,
            PRIM_POINT_LIGHT, TRUE, <128,128,0>, 1.0, 0.7, 0.0,
            PRIM_GLOW, ALL_SIDES, 0.10,
            PRIM_FULLBRIGHT, ALL_SIDES, TRUE]
        );
    }else{
        llSetPrimitiveParams([
            PRIM_COLOR, ALL_SIDES, <255,255,255>, 1.0,
            PRIM_POINT_LIGHT, FALSE, <128,128,0>, 1.0, 0.7, 0.0,
            PRIM_GLOW, ALL_SIDES, 0.0,
            PRIM_FULLBRIGHT, ALL_SIDES, FALSE]
        );
    }
}

//Process Listen Responses
ProcessResponse(string Type, list InputData){
    if(Type=="Config"){ // We are processing an initial configuration data response.
        ElevatorKey = llList2Key(InputData, 2);
        ComChannel = llList2Integer(InputData, 3);
        if(llList2String(InputData, 4)=="TRUE"){ OpMode = TRUE; }else{ OpMode = FALSE; }
        ArriveDing = llList2Key(InputData, 4);
        DebugMessage("Elevator Car: "+llKey2Name(ElevatorKey)+"\nElevator Com Channel: "+(string)ComChannel+"\nClosing Old Com Channel...");
        llListenRemove(ComHandle);
        ComHandle = 0;
        if(ComHandle<=0){
            DebugMessage("Old Channel Closed! Opening New Channel...");
            ComHandle = llListen(ComChannel, EMPTY, EMPTY, EMPTY);
        }
        if(ComHandle>0){
            DebugMessage("New Com Channel Open!");
            SystemStart();
        }
    }
}


//Main Program Logic
/* This section contains the main program logic. (ie: Default State, and all event triggers) */

default{
    on_rez(integer params){
        llResetScript();
    }
    
    state_entry(){
        ButtonLight(FALSE);
        Initialize();
    }
    
     // DataServer Event Called for Each Line of Config NC. This Loop It was Calls LoadConfig()
    dataserver(key query_id, string data){       // Config Notecard Read Function Needs to be Finished
        if (query_id == cQueryID){
            if (data != EOF){ 
                LoadConfig(data); // Process Current Line
                ++cLine; // Increment Line Index
                cQueryID = llGetNotecardLine(ConfigFile, cLine); // Attempt to Read Next Config Line (Re-Calls DataServer Event)
            }else{ // IF EOF (End of Config loop, and on Blank File)
                AskForConfig();
            }
        }
    }
    
    listen(integer channel, string sender, key id, string msg){
        DebugMessage("Listen Fired: "+(string)msg);
        if(channel==ComChannel){
            list InputData = llParseString2List(msg, ["||"], []);
            if(llList2Key(InputData, 0)==llGetKey()){ // Response was destined for this prim
                string CMD = llList2String(InputData, 1);
                if(CMD=="CONFIG"){
                    DebugMessage("Sending to Config Processor...");
                    ProcessResponse("Config", InputData);
                }
            }else if(llList2Key(InputData, 0)=="ARRIVED"){
                integer Where = llList2Integer(InputData, 1);
                if(Floor==Where){ // Car Has Arrived
                    // Turn Light Off
                    ButtonLight(FALSE);
                    string Display = EMPTY;
                    if(Floor<10){
                        Display = "  0"+(string)Floor+"  ";
                    }else{
                        Display = "  "+(string)Floor+"  ";
                    }
                    llMessageLinked(LINK_SET, 281000, Display, "''''");
                    llPlaySound(ArriveDing, 0.5);
                }
            }else if(llList2Key(InputData, 0)=="FLOOR"){
                integer NewFloor = llList2Integer(InputData, 1);
                string Display = EMPTY;
                if(NewFloor<10){
                    Display = "  0"+(string)NewFloor+"  ";
                }else{
                    Display = "  "+(string)NewFloor+"  ";
                }
                llMessageLinked(LINK_SET, 281000, Display, "''''");
            }
        }
    }
    
    touch_start(integer total_number)
    {
        key UserKey = llDetectedKey(0);
        if(OpMode){
            string SendString = (string)ElevatorKey+"||GOTO||"+(string)Floor;
            llRegionSayTo(ElevatorKey, ComChannel, SendString);
            ButtonLight(TRUE);
            llRegionSayTo(UserKey, 0, "Elevator called to floor: "+(string)Floor);
        }else{
            llRegionSayTo(UserKey, 0, "Elevator is currently non operational!");
        }
    }
    
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            BootMessage = "Inventory Changed Detected, Re-Initializing...";
            llResetScript();
        }
    }
}