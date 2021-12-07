# Minetest Expo
A modified design of the great presentations mod to build virtual expositions in minetest
This mod is derived from Minetest presentation https://github.com/LucxMangaJet/minetest_presentations
The main purpose is to suppress the "download" features and allow images organisation in subfolders of "textures" folder. 
This mods also add  text comments associated with pictures. These comments are showed on screen when the player is in vicinity.

# Minetest Expo
A mod for minetest that allows displaying images at runtime.  
It servers two main purpuses:  
1. Displaying images ingame, for the use in virtual exhibitions/galleries or simply for decoration.  
2. Holding virtual presentations.  

To achieve this two items are added to the game:   
(You can find both by typing "expo" or "display" in the search bar)  
1. Expo Display  
2. Expo Display Remote  
	 
---

### Display

The display item is a canvas that display images (.png or .jpg).  
It can display a multitude of images if multiple are specified in the respective image list.  
You can set it up and edit it by right clicking.  
This includes changing size, proportions, rotation, position and images to display.  
You can change the current displayed image by punching the canvas (left click) OR by using a display remote (see below)  

To add images you need to paste a link ending in .png or .jpg into the "URLS" input fields, multiple images can be downloaded at once.   
Requires "expo" privilage to be edited.   
Adding images is ONLY available if you upload it in "textures" folder 


---

### Display Remote
The remote is used to facilitate the presentation, it is not necessary.   
Left clicking with a remote on a display will "connect" the remote to that presentation  
Left clicking while connected opens up a UI that lets you change slides.  
You can give a connected remote to a user without the "presentations" privilage to allow them to change slides.  

![Remote UI](https://user-images.githubusercontent.com/38705070/107877924-9579b880-6ecf-11eb-9533-aeb11abbd380.png)

---


### Installation

To install it copy the downloaded folder (see releases) to the /mods/ folder of your server.  

To allow downloading finding images at runtime the mod needs to get added to the *trusted_mods* in the minetest.conf.  
Add this line to your minetest.conf:  
`"secure.trusted_mods = expo"`  


Once ingame you will need the "presentations" privilage to edit/add displays.  
`/grant username expopriv`    
