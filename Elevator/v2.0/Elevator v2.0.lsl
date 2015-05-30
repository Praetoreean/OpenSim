// Key Framed Elevator v2.0
// Created by Tech Guy of IO 2015
/*

    This elevator uses llSetKeyframedMotion() to facilitate smooth uniform motion.

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
    // Configuration Variables
        list Floors = [ 1 ];
        list Seats = [];
        integer CurrentFloor = 1;
        list DestFloor = []; // Holds List of Floors that have called it or it has been order to go to. In Order of Selection
        integer OpMode = FALSE; // Elevator is in Non-Operational Mode
        string RunMode = "Offline"; // Ready/MoveUp/MoveDown/Offline
        float SpeedT = 5.0; // Travel Speed (Multipled by Travel Distance to get Key Framed Animation Time)
        float DiM = 0.0; // Distance in Meters from current Floor to Next Floor in DestFloor List.
        
        
        
        
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
                    DebugMessage("Opening Com Channel ("+(string)ComChannel+")...");
                    ComHandle = llListen(ComChannel, EMPTY, EMPTY, EMPTY);
                    if(ComHandle>0){
                        DebugMessage("Com Channel Open!");
                    }else{
                        DebugMessage("Unable to Open Com Channel ("+(string)ComChannel+")!");
                    }
                }
        }else{ //  line does not contain equal sign
                SendMessage("Configuration could not be read on line " + (string)cLine, NULL_KEY);
            }
        }
    }
}

// Scan LinkSet for Prims marked seat and add their link id to seats list
ScanForSeats(){
    integer NumLinks = llGetNumberOfPrims();
    integer i;
    for(i=1;i<NumLinks;i++){
        //DebugMessage("Checking Prim "+(string)i+" for seat...");
        string Name = llGetLinkName(i);
        if(Name=="seat"){
            Seats = Seats + [ i ];
            DebugMessage("Found Seat "+(string)llGetListLength(Seats)+" Link ID: "+llList2String(Seats, -1));
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
        Initialize();
    }
    
    listen(integer channel, string sender, key id, string msg){
        if(channel==ComChannel){
            list InputData = llParseString2List(msg, ["||"], []);
            if(llList2String(InputData, 0)==llGetKey()){
                if(llList2String(InputData, 1)=="CONFIG"){
                    ComChannel = llList2Integer(InputData, 2);
                    DebugMessage("New Com Channel: "+(string)ComChannel+" Closing old channel...");
                    llListenRemove(ComHandle);
                    ComHandle = 0;
                    DebugMessage("Opening New Channel...");
                    ComHandle = llListen(ComChannel, EMPTY, EMPTY, EMPTY);
                    if(ComHandle>0){
                        DebugMessage("New Com Channel ("+(string)ComChannel+") Open!");
                    }else{
                        DebugMessage("Could not open new com channel!");
                        return;
                    }
                    if(llList2String(InputData, 3)=="TRUE"){ OpMode = TRUE; }else{ OpMode = FALSE; }
                    if(OpMode){
                        DebugMessage("Elevator Starting in Online Mode!");
                        RunMode = "Ready";
                    }else{
                        DebugMessage("Elevator Starting in Offline Mode!");
                        RunMode = "Offline";
                    }
                    SpeedT = llList2Float(InputData, 4);
                    DebugMessage("Speed: "+(string)SpeedT);
                    integer i;
                    list TempFloors = llList2List(InputData, 5, -1);
                    for(i=0;i<llGetListLength(TempFloors);i++){
                        Floors = Floors + [llList2Float(TempFloors, i)];
                        DebugMessage("Registering Floor "+(string)(i + 1)+" Z-Axis as: "+(string)llList2String(Floors, -1));
                    }
                    ScanForSeats();
                }
            }else{
                return;
            }
        }
    }
    
     // DataServer Event Called for Each Line of Config NC. This Loop It was Calls LoadConfig()
    dataserver(key query_id, string data){       // Config Notecard Read Function Needs to be Finished
        if (query_id == cQueryID){
            if (data != EOF){ 
                LoadConfig(data); // Process Current Line
                ++cLine; // Increment Line Index
                cQueryID = llGetNotecardLine(ConfigFile, cLine); // Attempt to Read Next Config Line (Re-Calls DataServer Event)
            }else{ // IF EOF (End of Config loop, and on Blank File)
                DebugMessage("Asking Elevator Panel Server for Config...");
                string SendString = "GETCONFIG||ELEVATOR";
                llRegionSay(ComChannel, SendString);
            }
        }
    }
    
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            BootMessage = "Inventory Changed Detected, Re-Initializing...";
            llResetScript();
        }
    }
}