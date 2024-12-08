When you install this you will have to go to your database inside nd characters and clean out the metadata 

after you have done this 

when you load into the game 
if the player's appearance doesn't load 

do /skin 1 in your chat 

then change your appearance 

save that 

go to a outfit store and add an outfit 

save that 



I've added an update where you can block item numbers out in your shop so no one can buy them with a cool message.
in client change these like this 


-- Define blocked items
local blockedItems = {
    hats = {},
    legs = {},
    bags = {},
    scarvesChains = {},
    shirts = {1, 5, 7},
    bodyArmor = {},
    jackets = {}
}




