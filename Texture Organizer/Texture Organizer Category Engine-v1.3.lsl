//Configuration Variables
string ReasonBroken = ""; // Hold Reason we entered a broken state
string Category = "Doors";

// Texture Lists
list textureids = [];
list texturenames = [];
integer NumTextures; // Hold Total Number of Textures (So we do not have to constantly recalculate)
integer TIndex; // Hold Index Number of Current Texture in Main Viewer
integer StartIndex; // Holds Index Number for Texture in Prim 3
integer EndIndex;  // Holds Index Number for Texture in Prim 27

integer SendMsg = FALSE; // Hold Boolean Value of weather to send a "We have update Inventory" Message after Inventory Update

LoadInventory(){
    texturenames = [];
    textureids = [];
    integer InvNum = llGetInventoryNumber(INVENTORY_TEXTURE);
    if(InvNum<=0){ // If we have no textures
        ReasonBroken = "InvEmpty";
        state broken;
    }else{ // We Found Textures so Process Them
        integer i; // Hold Iterative Index Counter
        for(i=0;i<=InvNum-1;i++){
            string TextureName = llGetInventoryName(INVENTORY_TEXTURE, i);
                texturenames = texturenames + TextureName;
                key TextureKey = llGetInventoryKey(llList2String(texturenames,i));
                if(TextureKey!=NULL_KEY){
                    textureids = textureids + TextureKey;
                    llOwnerSay("Texture: "+llList2String(texturenames, i)+"\nID: "+llList2String(textureids, i)+"\nHas been sucessfully added to "+Category);
                }else{
                    llOwnerSay("TextureName: "+llList2String(texturenames, i));
                }
        }
        NumTextures = llGetListLength(textureids); // Make note of how many texture we have in inventory lists
        if(SendMsg){
            SendMsg = FALSE;
            llMessageLinked(LINK_ROOT, 0, "UPDATED", "");
        }else{
            llOwnerSay("Inventory Loaded!");
        }
    }
}

state broken{ 
    state_entry(){
        if(ReasonBroken=="InvEmpty"){
            llOwnerSay("You have no textures in the "+Category+" Category. Please add some...");
        }
    }
    
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            llSetTimerEvent(5.0);
        }
    }
    
    timer(){
        llOwnerSay("Inventory Change Detected for Category "+Category+", Resetting...");
        llResetScript();
    }
}

default
{
    on_rez(integer start_params){
        llResetScript();
    }
    
    state_entry()
    {
        llSetColor(<1.0,1.0,1.0>, 4);
        LoadInventory();
    }
    
    link_message(integer send_num, integer num, string msg, key id){
        if(msg=="nogreen"){
            llSetColor(<1.0,1.0,1.0>, 4);
        }else if(msg=="getids"){
            llMessageLinked(LINK_ROOT, 0, llList2CSV(textureids), "");
        }else if(msg=="getnames"){
            llMessageLinked(LINK_ROOT, 0, llList2CSV(texturenames), "");
        }else if(num==2){
            //if(id==llGetOwner()){
                if(llGetInventoryType(msg)!=INVENTORY_NONE){
                    llRemoveInventory(msg);
                    SendMsg = TRUE;
                    LoadInventory();
                }
            //}
        }else if(num==0){
            if(llGetInventoryType(msg)!=INVENTORY_NONE){
                llGiveInventory(id, msg);
            }
        }
    }
    
    touch(integer num){
        llSay(0, "Switching to "+Category+" Category...");
        llMessageLinked(LINK_ALL_OTHERS, 0, "nogreen", llDetectedKey(0));
        llSleep(1.0);
        llMessageLinked(LINK_ROOT, 0, "catchange", llDetectedKey(0));
        llSetColor(<0.0,1.0,0.0>, 4);
    }
    
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            llSetTimerEvent(5.0);
        }
    }
    timer(){
        llOwnerSay("Inventory Change Detected for Category "+Category+", Resetting...");
        llResetScript();
    }
}